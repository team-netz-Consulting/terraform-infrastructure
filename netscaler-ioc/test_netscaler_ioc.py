import hashlib
import io
from pathlib import Path
import re
import tempfile
import unittest
from unittest.mock import Mock

import netscaler_ioc as ioc


class LocalChecks(unittest.TestCase):
    def test_ips(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "ips"
            path.write_text("# comment\n192.0.2.1\n192.0.2.1\n2001:db8::1 # IPv6\n")
            self.assertEqual(ioc.read_ips(path), ["192.0.2.1", "2001:db8::1"])
            path.write_text("192.0.2.1; command")
            with self.assertRaises(ValueError):
                ioc.read_ips(path)

    def test_script_checksum(self):
        script = b"#!/bin/sh\necho test\n"
        digest = hashlib.sha256(script).hexdigest()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / ioc.SCRIPT
            path.write_bytes(script)
            self.assertIsNone(ioc.inspect_script(path, digest))
            with self.assertRaises(ValueError):
                ioc.inspect_script(path, "0" * 64)
            path.unlink()
            with self.assertRaises(FileNotFoundError):
                ioc.inspect_script(path, digest)

    def test_shell_checks_completion_marker(self):
        for status in (0, 1, None):
            channel = Mock()
            data = []

            def execute(command):
                command = command.decode("utf-8")
                token = re.search(r"IOC_DONE_[a-f0-9]+", command).group()
                data.append((f"\n{token}:{status}\n" if status is not None else "ERROR: shell denied\n").encode())

            channel.sendall.side_effect = execute
            channel.recv_ready.side_effect = lambda: bool(data)
            channel.recv.side_effect = lambda size: data.pop()
            channel.recv_stderr_ready.return_value = False
            channel.exit_status_ready.return_value = True
            channel.recv_exit_status.return_value = 0
            client = Mock()
            client.get_transport.return_value.open_session.return_value = channel
            if status == 0:
                ioc.run_shell(client, "true", 1, io.BytesIO())
            else:
                with self.assertRaises(RuntimeError) as raised:
                    ioc.run_shell(client, "false", 1, io.BytesIO())
                if status is None:
                    self.assertIn("SSH-Status 0", str(raised.exception))
                    self.assertIn("ERROR: shell denied", str(raised.exception))
            channel.close.assert_called_once()
            channel.exec_command.assert_called_once_with("shell /bin/sh -s")
            channel.shutdown_write.assert_called_once()


if __name__ == "__main__":
    unittest.main()
