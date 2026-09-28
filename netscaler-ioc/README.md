# NetScaler IOC-Prüfung

Python 3.11 oder neuer. SSH nutzt wie die Alteon-Skripte `paramiko`;
für SCP wird das Linux-Kommando `scp` (OpenSSH) benötigt.

```bash
python3 -m venv netscaler-ioc/.venv
netscaler-ioc/.venv/bin/pip install -r netscaler-ioc/requirements.txt
cp netscaler-ioc/ips.example.txt netscaler-ioc/ips.txt
# ips.txt mit den tatsächlichen Ziel-IPs bearbeiten.
PYTHON=netscaler-ioc/.venv/bin/python bash netscaler-ioc/run.sh \
  --ips netscaler-ioc/ips.txt --script /pfad/ioc-script-v1.sh
```

Die Anmeldung verwendet `TF_VAR_netscaler_username` und
`TF_VAR_netscaler_password` aus der Umgebung. Fehlende Werte werden abgefragt,
das Passwort verdeckt. Der Benutzer benötigt SCP- und Shell-Berechtigungen.
SSH-Hostschlüssel müssen in `~/.ssh/known_hosts` oder einer mit
`--known-hosts DATEI` angegebenen Datei hinterlegt sein.

Die Datei wird direkt als `ioc-script-v1.sh` in einem neu angelegten
Verzeichnis `/var/ioc-<ID>` auf jedem ADC gespeichert und dort ausgeführt.
Die vorgegebene Skript-Prüfsumme wird lokal und nach dem Upload geprüft. Für eine andere
freigegebene Prüfsumme gibt es `--sha256 HASH`.

`--check-only` prüft die Eingaben lokal ohne SSH-Verbindung.

Pro IP erfolgen SCP-Upload, SSH-Ausführung über `shell /bin/sh -c` und
SCP-Download. Ein neues Verzeichnis `/var/ioc-<ID>` verhindert, dass alte
`result.txt`-Dateien als neue Ergebnisse übernommen werden. Erwartet wird,
dass das Skript `result.txt` im Arbeitsverzeichnis erzeugt. Die Remote-Dateien
bleiben zur Diagnose erhalten. Das Skript erhält keine interaktiven Antworten.

Lokale Ausgabe (über `--output` änderbar):

```text
ioc-results/<UTC-Zeit>-<ID>/
  summary.json
  <IP>/
    result.txt
    execution.log
    status.json
```

IPv6-Doppelpunkte werden im Verzeichnisnamen durch Unterstriche ersetzt.
Fehler werden je Gerät protokolliert; weitere Geräte werden weiterhin bearbeitet.
Der Gesamt-Exitcode ist bei mindestens einem Fehler 1, sonst 0.
Mit `--timeout SEKUNDEN` lässt sich die Laufzeitgrenze von standardmäßig
1800 Sekunden pro Skript ändern. Nach einem Timeout kann der Remote-Prozess
noch laufen; nicht ungeprüft einen weiteren Lauf starten.

Lokale Tests: `python3 -m unittest discover -s netscaler-ioc -p 'test_*.py'`.
Ein echter ADC-Test ist separat erforderlich.
