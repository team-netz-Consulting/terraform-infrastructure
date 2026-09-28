import contextlib
import copy
import io
import json
from pathlib import Path
import tempfile
import unittest

import import_services as importer


class ImportTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((importer.ROOT / 'services.example.json').read_text())
        self.schema = json.loads((importer.ROOT / 'services.schema.json').read_text())
        self.local = importer.network('10.96.37.x')
        self.remote = importer.network('10.96.5.0/24')

    def convert(self, data=None):
        return importer.convert(data or self.data, 'wi', self.local, self.remote)

    def test_example_wi(self):
        importer.validate(self.data, self.schema, self.schema)
        service = self.convert()['service-1']
        self.assertEqual(service['cs_vip'], '192.168.102.91')
        group = service['portgroups']['portgroup001']
        self.assertEqual(group['local_members'][0]['server_ip'], '10.96.37.21')
        self.assertEqual(group['remote_members'][0]['server_ip'], '10.96.5.34')

    def test_mz_and_missing_local(self):
        with self.assertRaisesRegex(ValueError, 'Keine lokalen'):
            importer.convert(self.data, 'mz', self.remote, self.local)
        for service in self.data['services'].values():
            del service['portgroups']['portgroup002']
        service = importer.convert(self.data, 'mz', self.remote, self.local)['service-1']
        self.assertEqual(service['cs_vip'], '192.168.101.91')
        self.assertEqual((service['local_site'], service['remote_site']), ('mz', 'wi'))
        self.assertEqual(service['portgroups']['portgroup001']['local_members'][0]['server_ip'], '10.96.5.34')

    def test_invalid_schema(self):
        for bad in (True, 0, 65536, '80'):
            data = copy.deepcopy(self.data)
            data['services']['service-1']['portgroups']['portgroup001']['ports'] = [bad]
            with self.assertRaises(ValueError):
                importer.validate(data, self.schema, self.schema)
        with self.assertRaisesRegex(ValueError, 'Doppelter JSON'):
            json.loads('{"services": {}, "services": {}}', object_pairs_hook=importer.unique_object)

    def test_networks(self):
        self.assertEqual(self.local, importer.network('10.96.37.0/24'))
        with self.assertRaisesRegex(ValueError, 'überschneiden'):
            importer.convert(self.data, 'wi', self.local, self.local)
        with self.assertRaises(ValueError):
            importer.network('10.x.37.x')

    def test_unknown_ip_and_conflicts(self):
        member = self.data['services']['service-1']['portgroups']['portgroup001']['members'][0]
        member['server_ip'] = '203.0.113.1'
        with self.assertRaisesRegex(ValueError, 'keinem IP-Bereich'):
            self.convert()
        member['server_ip'] = '10.96.37.21'
        other = self.data['services']['service-2']['portgroups']['portgroup001']['members'][0]
        other['server_name'] = member['server_name']
        with self.assertRaisesRegex(ValueError, 'widersprüchliche'):
            self.convert()

    def test_duplicate_members(self):
        group = self.data['services']['service-1']['portgroups']['portgroup001']
        group['members'].append(dict(group['members'][0]))
        with self.assertLogs('importer', level='WARNING') as logs:
            converted = self.convert()
        self.assertTrue(any('Doppeltes Mitglied' in line for line in logs.output))
        self.assertEqual(len(converted['service-1']['portgroups']['portgroup001']['local_members']), 1)

    def test_preserve_other_settings_and_escape(self):
        prefix = '# services = {}\nsecret = "brace } and \\\" quote"\n'
        suffix = '\nother = { nested = "hello" }\n'
        original = prefix + 'services = { old = { value = "}" /* } */ } }' + suffix
        updated = importer.merge_services(original, {'example': {'value': '${literal}%{literal}'}})
        self.assertTrue(updated.startswith(prefix))
        self.assertTrue(updated.endswith(suffix))
        self.assertIn('$${literal}%%{literal}', updated)
        self.assertIn('old = { value = "}" /* } */ }', updated)
        for invalid in ('services = {}\nservices = {}', 'services = {', 'value = <<EOF\nservices = {}\nEOF'):
            with self.assertRaises(ValueError):
                importer.merge_services(invalid, {})

    def test_merge_updates_and_preserves_unrelated_services(self):
        original = ('services = {\n'
                    '  # keep this comment\n'
                    '  untouched = { value = "keep" },\n'
                    '  "existing" = { value = "old" },\n'
                    '}\nother = "keep"\n')
        incoming = {'existing': {'value': 'new'}, 'added': {'value': 'added'}}
        updated = importer.merge_services(original, incoming)
        self.assertIn('# keep this comment\n  untouched = { value = "keep" },', updated)
        self.assertNotIn('"old"', updated)
        self.assertEqual(updated.count('"existing" ='), 1)
        self.assertEqual(updated.count('"added" ='), 1)
        self.assertTrue(updated.endswith('\nother = "keep"\n'))
        self.assertEqual(importer.merge_services(updated, incoming), updated)
        with self.assertRaisesRegex(ValueError, 'Doppelter Service'):
            importer.merge_services('services = { same = {} "same" = {} }', incoming)

    def test_change_report_shows_old_new_and_removed_content(self):
        before = {'cs_vip': '192.0.2.1', 'portgroups': {
            'portgroup001': {'ports': [80], 'local_members': [
                {'server_name': 'old-server', 'server_ip': '10.96.37.1'}]},
            'portgroup002': {'ports': [443]}}}
        after = {'cs_vip': '192.0.2.2', 'portgroups': {
            'portgroup001': {'ports': [8080], 'local_members': [
                {'server_name': 'new-server', 'server_ip': '10.96.37.2'}]}}}
        original = 'secret = "do-not-log"\nservices = ' + importer.hcl({'example': before})
        with self.assertLogs('importer', level='INFO') as captured:
            updated = importer.merge_services(original, {'example': after})
        report = '\n'.join(captured.output)
        self.assertIn('Vorhandener Service wird ersetzt/geändert', report)
        for old_value in ('192.0.2.1', 'old-server', '10.96.37.1', 'portgroup002', '[80]', '[443]'):
            self.assertTrue(any(line.startswith('INFO:importer:-') and old_value in line
                                for line in captured.output), old_value)
        for new_value in ('192.0.2.2', 'new-server', '10.96.37.2', '[8080]'):
            self.assertTrue(any(line.startswith('INFO:importer:+') and new_value in line
                                for line in captured.output), new_value)
        self.assertNotIn('do-not-log', report)
        with self.assertLogs('importer', level='INFO') as repeated:
            self.assertEqual(importer.merge_services(updated, {'example': after}), updated)
        self.assertIn('Service unverändert', '\n'.join(repeated.output))
        self.assertNotIn('ersetzt/geändert', '\n'.join(repeated.output))

    def test_cli_backup_dry_run_and_repeat(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / 'terraform.tfvars'
            original = 'other = "keep"\nservices = {}\n'
            target.write_text(original)
            target.chmod(0o600)
            args = [str(importer.ROOT / 'services.example.json'), '--site', 'wi',
                    '--local-ip', '10.96.37.x', '--remote-ip', '10.96.5.x', '--output', str(target)]
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(importer.main(args + ['--dry-run']), 0)
            self.assertEqual(target.read_text(), original)
            self.assertEqual(len(list(Path(directory).glob('*.bak'))), 0)
            self.assertEqual(importer.main(args), 0)
            self.assertTrue(target.read_text().startswith('other = "keep"\n'))
            backup, = Path(directory).glob('*.bak')
            self.assertEqual(backup.read_text(), original)
            self.assertEqual(target.stat().st_mode & 0o777, 0o600)
            self.assertEqual(backup.stat().st_mode & 0o777, 0o600)
            self.assertEqual(importer.main(args), 0)
            self.assertEqual(len(list(Path(directory).glob('*.bak'))), 1)
            before = target.read_bytes()
            args[args.index('wi')] = 'mz'
            args[args.index('10.96.37.x')] = '10.96.5.0/24'
            args[args.index('10.96.5.x')] = '10.96.37.0/24'
            self.assertEqual(importer.main(args), 1)
            self.assertEqual(target.read_bytes(), before)


if __name__ == '__main__':
    unittest.main()
