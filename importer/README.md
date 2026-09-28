# Services-Importer

Python 3.9 oder neuer; keine zusätzlichen Pakete erforderlich. Eingaben werden
anhand der Regeln des mitgelieferten `services.schema.json` geprüft.

Aus dem Repository-Verzeichnis zunächst einen Probelauf starten:

```bash
python3 importer/import_services.py importer/services.example.json \
  --site wi --local-ip 10.96.37.x --remote-ip 10.96.5.x --dry-run
```

Zum Schreiben `--dry-run` weglassen. Standardziel ist
`environments/ns-test/terraform.tfvars`, unabhängig vom Arbeitsverzeichnis.
Ein anderes bestehendes Ziel lässt sich mit `--output PFAD` wählen.

Für MZ werden die Netze vertauscht:

```bash
python3 importer/import_services.py daten.json \
  --site mz --local-ip 10.96.5.0/24 --remote-ip 10.96.37.0/24 --dry-run
```

- `--site` bestimmt `local_site`, den jeweils anderen Standort als `remote_site`
  und die Auswahl von `cs_vip_wi` bzw. `cs_vip_mz` für Terraform `cs_vip`.
  Abweichende Standortangaben aus JSON werden mit einer Info überschrieben.
- `--local-ip` und `--remote-ip` bestimmen die Member-Zuordnung. Unterstützt
  werden IPv4-CIDR-Netze sowie abschließende `x`- oder `*`-Oktette (Sternmuster
  in der Shell in Anführungszeichen setzen). Auch `--local_ip` und
  `--remote_ip` werden akzeptiert. Die Bereiche dürfen sich nicht überschneiden.
- Neue Services werden im bestehenden `services`-Block ergänzt. Gleichnamige
  Services werden vollständig mit der JSON-Konfiguration aktualisiert (einschließlich
  ihrer Portgruppen und Member). Services, die nicht in der JSON-Datei stehen,
  bleiben mit ihrer Formatierung und ihren Kommentaren erhalten. Auch alle
  anderen Variablen bleiben unverändert. Ergänzungen und Aktualisierungen werden
  einzeln ausgegeben. Bei einem vorhandenen, geänderten Service erscheint eine
  Warnung sowie ein zeilenweiser Vergleich: `-` zeigt den bisherigen, `+` den
  neuen Inhalt (auch Ports, Portgruppen und Member). Formatierungsänderungen
  sind ebenfalls sichtbar. Diese Änderungsvorschau erscheint auch bei
  `--dry-run`; erst nach erfolgreichem Schreiben wird die Übernahme bestätigt.
  Unveränderte Services werden entsprechend gemeldet, ohne Vergleichsausgabe.
  Der Importer führt Terraform selbst nicht aus.
- Vor Änderungen entsteht eine datierte `.bak`-Datei neben dem Ziel, mit dessen
  Dateirechten. Anschließend wird die Zieldatei atomar ersetzt. Sicherungen
  enthalten auch die übrigen tfvars-Einstellungen einschließlich Zugangsdaten.
  Bei identischem Ergebnis erfolgt kein erneutes Schreiben.
- Unbekannte IPs, ungültige Eingaben, mehrfach vergebene Ports innerhalb eines
  Services, widersprüchliche IPs für denselben Servernamen oder fehlende lokale
  Mitglieder führen zum Abbruch ohne Änderung der Zieldatei (Exitcode 1).
- Identische Member innerhalb einer Portgruppe werden mit Warnung dedupliziert.
  Fehlende Remote-Member und mehrfach verwendete CS-VIPs erzeugen Warnungen.
- Das mitgelieferte Beispiel funktioniert für WI. Für MZ fehlen in den jeweiligen
  `portgroup002` lokale Mitglieder; der Import wird deshalb abgelehnt.
- Das Ziel muss einen literalen `services = { ... }`-Block enthalten. Heredocs
  im Ziel werden nicht unterstützt und führen zum Abbruch.
- Infos und Warnungen stehen auf stderr, die Vorschau des zusammengeführten Services-Blocks auf
  stdout. Die übrigen Einstellungen werden nicht ausgegeben. Exitcode 0 bedeutet
  Erfolg, auch bei Warnungen; CLI-Fehler liefern Exitcode 2.

Tests:

```bash
python3 -m unittest discover -s importer -p 'test_*.py'
```
