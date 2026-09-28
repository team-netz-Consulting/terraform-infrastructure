#!/usr/bin/env python3
"""Generate the CS key migration from a Terraform state without modifying it."""

import argparse
import json
import sys
from pathlib import Path


RESOURCES = {
    "citrixadc_csaction.port",
    "citrixadc_cspolicy.port",
    "citrixadc_csvserver_cspolicy_binding.port",
    *{
        f"{resource}.{site}"
        for resource in (
            "citrixadc_lbvserver",
            "citrixadc_lbvserver_servicegroup_binding",
            "citrixadc_servicegroup",
            "citrixadc_servicegroup_servicegroupmember_binding",
            "citrixadc_servicegroup_lbmonitor_binding",
        )
        for site in ("local", "remote")
    },
}


def hcl_string(value):
    """Quote a literal string, including Terraform template markers."""
    return json.dumps(value, ensure_ascii=False).replace("${", "$${").replace("%{", "%%{")


def migrated_key(key, monitor_binding=False):
    if not isinstance(key, str):
        raise ValueError("Die Migration erwartet for_each-Schlüssel als Strings.")
    if monitor_binding:
        parts = json.loads(key)
        if not isinstance(parts, list) or len(parts) != 2 or not all(
            isinstance(part, str) for part in parts
        ):
            raise ValueError("Ungültiger Monitor-Schlüssel: erwartet [port_key, monitor].")
        port_key = migrated_key(parts[0])
        if port_key is None:
            return None
        return json.dumps([port_key, parts[1]], separators=(",", ":"), ensure_ascii=False)
    if key.startswith(("cs:", "lb:")):
        return None
    if ":" not in key:
        raise ValueError("Ungültiger Service-Schlüssel: erwartet Service:Portgruppe:Port.")
    return "cs:" + key


def generate_moves(state):
    if not isinstance(state, dict) or not isinstance(state.get("resources"), list):
        raise ValueError("Erwartet wird eine Terraform-State-Datei mit resources-Liste.")
    moves = {}
    occupied = set()
    for resource in state["resources"]:
        address = f"{resource['type']}.{resource['name']}"
        if resource.get("mode", "managed") != "managed" or address not in RESOURCES:
            continue
        if resource.get("module"):
            address = f"{resource['module']}.{address}"
        monitor = resource["type"] == "citrixadc_servicegroup_lbmonitor_binding"
        for instance in resource.get("instances", []):
            key = instance.get("index_key")
            new_key = migrated_key(key, monitor)
            source = f"{address}[{hcl_string(key)}]"
            occupied.add(source)
            if new_key is not None:
                moves[source] = f"{address}[{hcl_string(new_key)}]"
    if occupied.intersection(moves.values()):
        raise ValueError("Der State enthält alte und neue Adressen derselben Instanz.")
    if not moves:
        raise ValueError("Keine zu migrierenden CS-Instanzen im State gefunden.")
    header = (
        "# Migration der bestehenden CS-Instanzen auf Schlüssel mit cs:-Präfix.\n"
        "# NetScaler-Objektnamen bleiben unverändert.\n\n"
    )
    blocks = [
        f"moved {{\n  from = {source}\n  to   = {target}\n}}\n"
        for source, target in sorted(moves.items())
    ]
    return header + "\n".join(blocks), len(blocks)


def main():
    parser = argparse.ArgumentParser(
        description="Erzeugt moved-Blöcke für die CS-Präfix-Migration aus einem alten State."
    )
    parser.add_argument("state", type=Path, help="State vor der Präfix-Änderung, z. B. terraform.tfstate.backup")
    parser.add_argument("-o", "--output", type=Path, help="Neue Ausgabedatei (Standard: stdout); vorhandene Dateien werden nicht überschrieben")
    args = parser.parse_args()
    try:
        content, count = generate_moves(json.loads(args.state.read_text(encoding="utf-8")))
        if args.output:
            with args.output.open("x", encoding="utf-8") as output:
                output.write(content)
        else:
            sys.stdout.write(content)
        print(f"{count} moved-Blöcke erzeugt.", file=sys.stderr)
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.exit(1, f"Fehler: {error}\n")


if __name__ == "__main__":
    main()
