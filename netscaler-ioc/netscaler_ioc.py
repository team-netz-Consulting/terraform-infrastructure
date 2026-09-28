#!/usr/bin/env python3
"""Upload an IOC script, run it via NetScaler shell, collect results per IP."""

import argparse
from datetime import datetime, timezone
import getpass
import hashlib
import ipaddress
import json
import os
from pathlib import Path
import re
import shlex
import sys
import time
import uuid

SHA256 = "3f4f3afb631b6e75c470ee492e20999939f520fdf05e1491347870deb586fa92"
SCRIPT = "ioc-script-v1.sh"


def read_ips(path):
    addresses = []
    for number, line in enumerate(path.read_text().splitlines(), 1):
        value = line.split("#", 1)[0].strip()
        if not value:
            continue
        try:
            address = str(ipaddress.ip_address(value))
        except ValueError as error:
            raise ValueError(f"{path}:{number}: ungültige IP-Adresse") from error
        if address not in addresses:
            addresses.append(address)
    if not addresses:
        raise ValueError("Die IP-Datei enthält keine Zieladressen.")
    return addresses


def inspect_script(path, checksum):
    """Verify the local script before connecting to any ADC."""
    with path.open("rb") as script:
        digest = hashlib.file_digest(script, "sha256").hexdigest()
    if digest != checksum:
        raise ValueError(f"SHA256 stimmt nicht überein: {digest}")


def run_shell(client, command, timeout, log):
    """Use NetScaler's shell command; drain output before reading exit status."""
    token = "IOC_DONE_" + uuid.uuid4().hex
    wrapped = command + f'; rc=$?; printf "\\n{token}:%s\\n" "$rc"; exit "$rc"'
    remote = "shell /bin/sh -c " + shlex.quote(wrapped)
    channel = client.get_transport().open_session(timeout=30)
    output = bytearray()
    deadline = time.monotonic() + timeout
    try:
        channel.settimeout(30)
        channel.exec_command(remote)
        channel.shutdown_write()
        while True:
            for ready, receive in ((channel.recv_ready, channel.recv),
                                   (channel.recv_stderr_ready, channel.recv_stderr)):
                if ready():
                    data = receive(65536)
                    output.extend(data)
                    log.write(data)
                    log.flush()
            if channel.exit_status_ready() and not channel.recv_ready() and not channel.recv_stderr_ready():
                break
            if time.monotonic() >= deadline:
                raise TimeoutError("SSH-Zeitlimit überschritten; der Remote-Prozess kann noch laufen.")
            time.sleep(0.05)
        matches = re.findall(rb"(?:\r?\n)" + token.encode() + rb":(\d+)\r?\n", output)
        status = channel.recv_exit_status()
        if not matches:
            raise RuntimeError("Kein Shell-Abschlussmarker empfangen; siehe execution.log.")
        if status != 0 or matches[-1] != b"0":
            raise RuntimeError(f"Remote-Befehl fehlgeschlagen (Status {matches[-1].decode()}); siehe execution.log.")
    finally:
        channel.close()


def process_host(ip, args, username, password, run_dir, paramiko, scp_class):
    destination = run_dir / ip.replace(":", "_")
    destination.mkdir(mode=0o700)
    # A unique directory prevents downloading a result from an earlier run.
    remote_dir = "/var/ioc-" + uuid.uuid4().hex
    record = {"ip": ip, "remote_directory": remote_dir, "success": False}
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    if args.known_hosts:
        client.load_host_keys(str(args.known_hosts))
    try:
        client.connect(ip, port=args.port, username=username, password=password,
                       look_for_keys=False, allow_agent=False, timeout=30,
                       auth_timeout=30, banner_timeout=30)
        with (destination / "execution.log").open("wb") as log:
            run_shell(client, f"umask 077; mkdir {shlex.quote(remote_dir)}", 60, log)
            with scp_class(client.get_transport(), socket_timeout=60) as transfer:
                transfer.put(str(args.script), remote_path=remote_dir + "/" + SCRIPT)
            prepare = (
                f"cd {shlex.quote(remote_dir)} && "
                f'test "$(sha256 -q {SCRIPT})" = {shlex.quote(args.sha256)} && '
                f"chmod 700 {SCRIPT}"
            )
            run_shell(client, prepare, 120, log)
            # Preserve output even when the IOC script exits nonzero.
            run_error = None
            try:
                run_shell(client, f"cd {shlex.quote(remote_dir)} && ./{SCRIPT}", args.timeout, log)
            except RuntimeError as error:
                run_error = error
            with scp_class(client.get_transport(), socket_timeout=60) as transfer:
                transfer.get(remote_dir + "/result.txt", local_path=str(destination / "result.txt.part"))
            (destination / "result.txt.part").replace(destination / "result.txt")
            if run_error:
                raise run_error
        record["success"] = True
        print(f"[{ip}] OK: {destination / 'result.txt'}")
    except Exception as error:
        record["error"] = str(error).replace(password, "***")
        print(f"[{ip}] FEHLER: {record['error']}", file=sys.stderr)
    finally:
        client.close()
        (destination / "status.json").write_text(json.dumps(record, indent=2) + "\n")
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ips", required=True, type=Path, help="Textdatei: eine Ziel-IP pro Zeile")
    parser.add_argument("--script", required=True, type=Path, help="Pfad zu ioc-script-v1.sh")
    parser.add_argument("--output", type=Path, default=Path("ioc-results"))
    parser.add_argument("--sha256", default=SHA256, help="Erwartete SHA256 des Skripts")
    parser.add_argument("--port", type=int, default=22)
    parser.add_argument("--timeout", type=int, default=1800, help="Maximale Skriptlaufzeit pro ADC in Sekunden")
    parser.add_argument("--known-hosts", type=Path, help="Zusätzliche SSH-known_hosts-Datei")
    parser.add_argument("--check-only", action="store_true", help="IP-Datei, Skript und Prüfsumme lokal prüfen; keine Verbindung")
    args = parser.parse_args()
    os.umask(0o077)
    try:
        args.sha256 = args.sha256.lower()
        if not re.fullmatch(r"[0-9a-f]{64}", args.sha256):
            raise ValueError("SHA256 muss aus 64 Hex-Zeichen bestehen.")
        if args.timeout <= 0 or not 1 <= args.port <= 65535:
            raise ValueError("Ungültiger Port oder ungültiges Zeitlimit.")
        ips = read_ips(args.ips)
        inspect_script(args.script, args.sha256)
        print(f"Prüfung OK: {len(ips)} Ziel-IP(s), SHA256 stimmt überein.")
        if args.check_only:
            return 0
        try:
            import paramiko
            from scp import SCPClient
        except ImportError as error:
            raise ValueError("Abhängigkeiten fehlen: pip install -r netscaler-ioc/requirements.txt") from error
        username = os.environ.get("TF_VAR_netscaler_username") or input("NetScaler Username: ").strip()
        password = os.environ.get("TF_VAR_netscaler_password") or getpass.getpass("NetScaler Passwort: ")
        if not username or not password:
            raise ValueError("Benutzername und Passwort dürfen nicht leer sein.")
        run_dir = args.output / (datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8])
        run_dir.mkdir(parents=True, mode=0o700)
        records = [process_host(ip, args, username, password, run_dir, paramiko, SCPClient) for ip in ips]
        (run_dir / "summary.json").write_text(json.dumps(records, indent=2) + "\n")
        print(f"Ergebnisse: {run_dir}")
        return 0 if all(record["success"] for record in records) else 1
    except (OSError, ValueError, EOFError) as error:
        print(f"Fehler: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
