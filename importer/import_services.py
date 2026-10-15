#!/usr/bin/env python3
"""JSON-Services standortabhängig in eine Terraform-tfvars-Datei importieren."""
import argparse
from datetime import datetime, timezone
import difflib
import ipaddress
import json
import logging
import os
from pathlib import Path
import re
import shutil
import tempfile

LOG = logging.getLogger('importer')
ROOT = Path(__file__).resolve().parent


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'Doppelter JSON-Schlüssel: {key}')
        result[key] = value
    return result


def validate(value, schema, root, path='$'):
    """Validiert die vom mitgelieferten Schema verwendeten JSON-Schema-Regeln."""
    if '$ref' in schema:
        target = root
        for part in schema['$ref'].removeprefix('#/').split('/'):
            target = target[part]
        return validate(value, target, root, path)
    kind = schema.get('type')
    expected = {'object': dict, 'array': list, 'string': str, 'integer': int}
    if kind and (not isinstance(value, expected[kind]) or
                 (kind == 'integer' and isinstance(value, bool))):
        raise ValueError(f'{path}: Erwarteter Typ: {kind}')
    if kind == 'object':
        missing = set(schema.get('required', [])) - value.keys()
        if missing:
            raise ValueError(f'{path}: Pflichtfelder fehlen: {", ".join(sorted(missing))}')
        if len(value) < schema.get('minProperties', 0):
            raise ValueError(f'{path}: Objekt darf nicht leer sein')
        for key, item in value.items():
            validate(key, schema.get('propertyNames', {}), root, f'{path}.{key}')
            child = schema.get('properties', {}).get(key,
                        schema.get('additionalProperties', {}))
            if child is False:
                raise ValueError(f'{path}: Unbekanntes Feld: {key}')
            if isinstance(child, dict):
                validate(item, child, root, f'{path}.{key}')
    elif kind == 'array':
        if len(value) < schema.get('minItems', 0):
            raise ValueError(f'{path}: Liste darf nicht leer sein')
        if schema.get('uniqueItems') and len({json.dumps(v, sort_keys=True) for v in value}) != len(value):
            raise ValueError(f'{path}: Doppelte Einträge sind nicht erlaubt')
        for index, item in enumerate(value):
            validate(item, schema.get('items', {}), root, f'{path}[{index}]')
    elif kind == 'string':
        if len(value.strip()) < schema.get('minLength', 0):
            raise ValueError(f'{path}: Text darf nicht leer sein')
        if schema.get('format') == 'ipv4':
            try:
                ipaddress.IPv4Address(value)
            except ipaddress.AddressValueError as exc:
                raise ValueError(f'{path}: Ungültige IPv4-Adresse: {value}') from exc
    elif kind == 'integer':
        if not schema.get('minimum', value) <= value <= schema.get('maximum', value):
            raise ValueError(f'{path}: Port muss zwischen 1 und 65535 liegen')
    if 'pattern' in schema and not re.search(schema['pattern'], value):
        raise ValueError(f'{path}: Ungültiger Name: {value}')
    if 'enum' in schema and value not in schema['enum']:
        raise ValueError(f'{path}: Ungültiger Wert: {value}; erlaubt: {schema["enum"]}')


def network(text):
    """IPv4-CIDR oder nachgestellte x/*-Oktette akzeptieren."""
    parts = text.lower().split('.')
    if any(p in ('x', '*') for p in parts):
        if len(parts) != 4:
            raise ValueError(f'Ungültiges IP-Muster: {text}')
        first = next(i for i, p in enumerate(parts) if p in ('x', '*'))
        if any(p not in ('x', '*') for p in parts[first:]):
            raise ValueError(f'Wildcards müssen am Ende stehen: {text}')
        text = '.'.join(parts[:first] + ['0'] * (4 - first)) + f'/{first * 8}'
    return ipaddress.IPv4Network(text, strict=True)


def convert(data, site, local_net, remote_net):
    if local_net.overlaps(remote_net):
        raise ValueError('Lokaler und entfernter IP-Bereich überschneiden sich')
    services = {}
    servers = {}
    vips = set()
    for name, service in data['services'].items():
        if service.get('task') == 'delete':
            services[name] = None
            continue
        remote_sites = [key.removeprefix('cs_vip_') for key in service
                        if key.startswith('cs_vip_') and key != f'cs_vip_{site}']
        if len(remote_sites) != 1:
            raise ValueError(f'{name}: Genau ein entfernter Standort für {site} erforderlich')
        remote_site = remote_sites[0]
        vip = service[f'cs_vip_{site}']
        if vip in vips:
            LOG.warning('%s: CS-VIP %s wird mehrfach verwendet', name, vip)
        vips.add(vip)
        result = {key: service[key] for key in ('environment', 'stage')}
        result.update(cs_vip=vip, local_site=site, remote_site=remote_site, portgroups={})
        seen_ports = set()
        for group_name, group in service['portgroups'].items():
            context = f'{name}/{group_name}'
            overlap = seen_ports.intersection(group['ports'])
            if overlap:
                raise ValueError(f'{context}: Ports in mehreren Portgruppen: {sorted(overlap)}')
            seen_ports.update(group['ports'])
            members = {'local_members': [], 'remote_members': []}
            seen = set()
            for member in group['members']:
                server, address = member['server_name'], member['server_ip']
                if server in servers and servers[server] != address:
                    raise ValueError(f'{context}: Server {server} hat widersprüchliche IP-Adressen')
                servers[server] = address
                if server in seen:
                    LOG.warning('%s: Doppeltes Mitglied %s wird zusammengeführt', context, server)
                    continue
                seen.add(server)
                ip = ipaddress.IPv4Address(address)
                if ip in local_net:
                    members['local_members'].append(member)
                elif ip in remote_net:
                    members['remote_members'].append(member)
                else:
                    raise ValueError(f'{context}: IP {address} ({server}) passt zu keinem IP-Bereich')
            if not members['local_members']:
                raise ValueError(f'{context}: Keine lokalen Mitglieder für {site}; Terraform verlangt mindestens eines')
            if not members['remote_members']:
                LOG.warning('%s: Keine Remote-Mitglieder; Remote-Ressourcen werden nicht erzeugt', context)
            result['portgroups'][group_name] = {'ports': sorted(group['ports']), **members}
            LOG.info('%s: %d Ports, %d lokal, %d remote', context, len(group['ports']),
                     len(members['local_members']), len(members['remote_members']))
        services[name] = result
        LOG.info('%s: cs_vip_%s → cs_vip = %s', name, site, vip)
    return services


def convert_gslb(data, services):
    result = {}
    for name, service in data['services'].items():
        if service.get('task') == 'delete':
            result[name] = None
            continue
        converted = services[name]
        result[name] = {
            'stage': service['stage'],
            'environment': service['environment'],
            'servicetype': service.get('servicetype', 'TCP'),
            'dnsrecordtype': 'A',
            'lbmethod': 'STATICPROXIMITY',
            'edr': 'ENABLED',
            'tolerance': '0',
            'services': {
                location: {
                    'site': converted[f'{location}_site'],
                    'ip': service[f"cs_vip_{converted[f'{location}_site']}"],
                    'port': 65535,
                    'weight': 1,
                }
                for location in ('local', 'remote')
            },
            'gslb_domains': {
                'primary': {'domainname': service['fqdn'], 'ttl': 60}
            } if service.get('fqdn') else {},
        }
    return result


def hcl(value, level=0):
    if isinstance(value, str):
        # Terraform-Templates in importierten Texten müssen Literale bleiben.
        return json.dumps(value, ensure_ascii=False).replace('${', '$${').replace('%{', '%%{')
    if isinstance(value, dict):
        if not value:
            return '{}'
        lines = ['  ' * (level + 1) + hcl(k) + ' = ' + hcl(v, level + 1)
                 for k, v in value.items()]
        return '{\n' + '\n'.join(lines) + '\n' + '  ' * level + '}'
    if isinstance(value, list):
        if not value or all(isinstance(v, int) for v in value):
            return json.dumps(value)
        return '[\n' + ',\n'.join('  ' * (level + 1) + hcl(v, level + 1) for v in value) + '\n' + '  ' * level + ']'
    return json.dumps(value)


# Strings und Kommentare als einzelne Tokens behandeln, damit darin enthaltene
# Klammern und das Wort "cs_services" keine Blockgrenzen vortäuschen.
TOKEN = re.compile(r'\s+|\#[^\n]*|//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|[A-Za-z_][A-Za-z0-9_-]*|.', re.DOTALL)


def services_span(original, block='cs_services'):
    tokens = [m for m in TOKEN.finditer(original)
              if not m.group().isspace() and not m.group().startswith(('#', '//', '/*'))]
    depth = 0
    spans = []
    for i, token in enumerate(tokens):
        text = token.group()
        if text == '<' and i + 1 < len(tokens) and tokens[i + 1].group() == '<':
            raise ValueError('Heredoc in Zieldatei wird nicht unterstützt; kein Import durchgeführt')
        if depth == 0 and text in (block, json.dumps(block)):
            if i + 2 >= len(tokens) or tokens[i + 1].group() != '=' or tokens[i + 2].group() != '{':
                raise ValueError(f'{block} muss in der Zieldatei ein literaler Objektblock sein')
            nesting = 0
            for end in tokens[i + 2:]:
                if end.group() == '{':
                    nesting += 1
                elif end.group() == '}':
                    nesting -= 1
                    if nesting == 0:
                        spans.append((token.start(), end.end()))
                        break
            else:
                raise ValueError(f'{block}-Block ist nicht geschlossen')
        if text in ('{', '[', '('):
            depth += 1
        elif text in ('}', ']', ')'):
            depth -= 1
        if depth < 0:
            raise ValueError('Unausgeglichene Klammern in der Zieldatei')
    if depth or len(spans) != 1:
        raise ValueError(f'Zieldatei muss genau einen geschlossenen {block}-Block enthalten')
    return spans[0]


def merge_services(original, services, tasks=None, block='cs_services'):
    """Services anhand ihres Namens ergänzen/aktualisieren; Rest exakt erhalten."""
    start, end = services_span(original, block)
    tokens = [m for m in TOKEN.finditer(original, start, end)
              if not m.group().isspace() and not m.group().startswith(('#', '//', '/*'))]
    entries = {}
    entry_spans = {}
    i = 3  # cs_services = {
    while i < len(tokens) - 1:
        if tokens[i].group() == ',':
            i += 1
            continue
        key = tokens[i].group()
        entry_start = tokens[i].start()
        name = json.loads(key) if key.startswith('"') else key
        if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_-]*', name):
            raise ValueError(f'Ungültiger Service-Name im Ziel: {name}')
        if name in entries:
            raise ValueError(f'Doppelter Service im Ziel: {name}')
        if i + 2 >= len(tokens) or tokens[i + 1].group() != '=' or tokens[i + 2].group() != '{':
            raise ValueError(f'{name}: Service im Ziel muss ein literaler Objektblock sein')
        first = tokens[i + 2].start()
        nesting = 1
        i += 3
        while i < len(tokens) and nesting:
            if tokens[i].group() == '{':
                nesting += 1
            elif tokens[i].group() == '}':
                nesting -= 1
            i += 1
        entries[name] = (first, tokens[i - 1].end())
        entry_end = tokens[i - 1].end()
        if i < len(tokens) and tokens[i].group() == ',':
            entry_end = tokens[i].end()
        entry_spans[name] = (entry_start, entry_end)
    changes = []
    additions = []
    for name, service in services.items():
        task = (tasks or {}).get(name)
        if task == 'add' and name in entries:
            raise ValueError(f'{name}: Service bereits vorhanden; task=add nicht möglich')
        if task in ('modify', 'delete') and name not in entries:
            raise ValueError(f'{name}: Service nicht vorhanden; task={task} nicht möglich')
        if task == 'delete':
            first, last = entry_spans[name]
            changes.append((first, last, ''))
            LOG.info('%s: Service wird gelöscht', name)
            continue
        rendered = hcl(service, 1)
        if name in entries:
            first, last = entries[name]
            if original[first:last] != rendered:
                changes.append((first, last, rendered))
                LOG.warning('%s: Vorhandener Service wird ersetzt/geändert (Änderungsvorschau)', name)
                LOG.info('%s: Änderungen: - bisheriger Inhalt, + neuer Inhalt', name)
                for line in difflib.unified_diff(
                        original[first:last].splitlines(), rendered.splitlines(),
                        fromfile=f'{name} (bisher)', tofile=f'{name} (neu)', lineterm=''):
                    LOG.info('%s', line)
            else:
                LOG.info('%s: Service unverändert', name)
        else:
            additions.append('  ' + hcl(name) + ' = ' + rendered)
            LOG.info('%s: Neuer Service wird ergänzt', name)
    if additions:
        closing = tokens[-1].start()
        changes.append((closing, closing, '\n' + '\n'.join(additions) + '\n'))
    for first, last, replacement in sorted(changes, reverse=True):
        original = original[:first] + replacement + original[last:]
    return original


def write_result(target, original, updated):
    # Vorhandene Rechte erhalten; auch die Sicherung kann Zugangsdaten enthalten.
    if target.read_text(encoding='utf-8') != original:
        raise ValueError('Zieldatei wurde zwischenzeitlich geändert; Import bitte wiederholen')
    backup = target.with_name(target.name + '.' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ') + '.bak')
    shutil.copy2(target, backup)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=target.parent,
                                         prefix='.' + target.name, delete=False) as handle:
            temporary = Path(handle.name)
            handle.write(updated)
            handle.flush()
            os.fsync(handle.fileno())
        shutil.copymode(target, temporary)
        os.replace(temporary, target)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    LOG.info('Sicherung: %s', backup)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, epilog='Verarbeitet task=add/modify/delete. Ohne task werden Services ergänzt oder aktualisiert. Andere Services bleiben erhalten.')
    parser.add_argument('input', type=Path, help='JSON-Datei gemäß services.schema.json')
    parser.add_argument('--site', required=True, choices=('wi', 'mz', 'voh'), help='Lokaler Standort')
    parser.add_argument('--local-ip', '--local_ip', required=True, help='Lokaler IPv4-Bereich, z. B. 10.96.37.x oder 10.96.37.0/24')
    parser.add_argument('--remote-ip', '--remote_ip', required=True, help='Entfernter IPv4-Bereich')
    parser.add_argument('--output', type=Path, default=ROOT.parent / 'environments/ns-test/terraform.tfvars')
    parser.add_argument('--dry-run', action='store_true', help='Validieren und cs_services-Block auf stdout ausgeben; keine Dateien ändern')
    parser.add_argument('--gslb', action='store_true', help='Zusätzlich gslb_services importieren')
    args = parser.parse_args(argv)
    logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
    try:
        data = json.loads(args.input.read_text(encoding='utf-8-sig'), object_pairs_hook=unique_object)
        schema = json.loads((ROOT / 'services.schema.json').read_text(encoding='utf-8'))
        validate(data, schema, schema)
        services = convert(data, args.site, network(args.local_ip), network(args.remote_ip))
        target = args.output.resolve(strict=True)
        original = target.read_text(encoding='utf-8')
        tasks = {name: service.get('task') for name, service in data['services'].items()}
        updated = merge_services(original, services, tasks)
        if args.gslb:
            updated = merge_services(updated, convert_gslb(data, services), tasks, 'gslb_services')
        if args.dry_run:
            start, end = services_span(updated)
            print(updated[start:end])
            if args.gslb:
                start, end = services_span(updated, 'gslb_services')
                print(updated[start:end])
            LOG.info('Probelauf erfolgreich: %d Services; keine Dateien geändert', len(services))
        elif updated == original:
            LOG.info('Keine Änderungen erforderlich')
        else:
            write_result(target, original, updated)
            LOG.info('%d Services nach %s importiert; angezeigte Änderungen wurden geschrieben', len(services), target)
        return 0
    except (ValueError, OSError) as exc:
        LOG.error('%s', exc)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
