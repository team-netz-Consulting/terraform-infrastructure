# Services JSON Editor 1.0.0

Desktop-Editor in C# mit Avalonia für Windows und Linux. Er bearbeitet die
Services-Dateien des Importers, ohne Terraform auszuführen.

## Verwendung

Das ZIP für die eigene Plattform entpacken und `ServicesEditor.exe` (Windows)
bzw. `./ServicesEditor` (Linux) starten. Eine separate .NET- oder Python-Installation
ist für die veröffentlichten Anwendungen nicht erforderlich. Unter Linux werden
eine grafische Sitzung mit X11/XWayland und die üblichen Desktopbibliotheken
(u. a. libX11, libICE, libSM und libfontconfig) benötigt.

1. Mit **Öffnen** eine Services-JSON laden oder mit **Neu** beginnen.
2. Links einen Service auswählen oder über **+ Service** hinzufügen.
   Die Suche filtert nach dem Service-Namen.
3. Rechts die Felder bearbeiten. Environment, Stage und Auftrag sind Auswahllisten.
   Portgruppen und Server lassen sich hinzufügen, umbenennen bzw. entfernen.
   Ports durch Komma trennen, beispielsweise `443, 8443`.
4. **Prüfen** zeigt Schemafehler mit JSON-Pfad und verletzter Regel.
   Der Reiter **JSON-Vorschau** zeigt den aktuellen Dokumentinhalt.
5. **Speichern** oder **Speichern unter** verwenden. Vor jedem Speichern wird das
   gesamte Dokument geprüft. Ungültige Daten werden nicht gespeichert.

Neue Services und Server enthalten leere IP-Felder, die vor dem Speichern
vervollständigt werden müssen. Änderungen werden im Fenstertitel mit `*` markiert.
Beim Öffnen, Anlegen oder Schließen wird nach ungespeicherten Änderungen gefragt.
Das Löschen eines Services entfernt ihn aus der Datei. Der Auftrag `task: delete`
bleibt dagegen ein Eintrag in der Datei; der Editor führt diesen Auftrag nicht aus.

## Prüfung und Dateischutz

Die Anwendung bettet das originale `../services.schema.json` (Draft 2020-12) beim
Build ein. Die Prüfung erfolgt mit JsonSchema.Net einschließlich IPv4-Formaten,
Pflichtfeldern, Wertebereichen, eindeutigen Ports, Namen und unbekannten Eigenschaften.
Es werden keine Dateien oder Konfigurationsdaten an einen Server übertragen.

Unbekannte JSON-Eigenschaften bleiben beim Laden erhalten und erscheinen als
Schemafehler. Strukturen, die die Maske nicht darstellen kann, sowie doppelte
JSON-Schlüssel werden beim Öffnen mit einer Fehlermeldung abgelehnt. Eine
fehlerhafte Datei ersetzt das bereits geöffnete Dokument nicht.

Vor dem Überschreiben entsteht neben der Zieldatei eine Sicherung mit Zeitstempel
(`services.json.<Zeitstempel>.bak`). Anschließend ersetzt eine temporäre Datei im
selben Verzeichnis die Zieldatei. Seit dem Öffnen extern geänderte oder gelöschte
Dateien werden nicht überschrieben; dafür **Speichern unter** oder neu öffnen.
JSON wird beim Speichern mit Einrückung neu formatiert.

Die Schema-Prüfung ersetzt nicht die zusätzlichen fachlichen Prüfungen des
Importers, etwa Standortzuordnung und standortübergreifende IP-Konflikte.
Vor einem Import weiterhin dessen `--dry-run` verwenden.

## Entwicklung und Build unter Linux

Voraussetzungen: .NET SDK 10, Internetzugriff auf NuGet für die Pakete; Python 3
für die ZIP-Erstellung. Paketversionen sind im Projekt festgelegt. Die
`packages.lock.json`-Dateien werden mit versioniert.

Aus der Repository-Wurzel:

```bash
# Oberfläche unter Linux starten
dotnet run --project importer/ServicesEditor

# Modell-, Schema-, Dateischutz- und Headless-Oberflächentests
dotnet run --project importer/ServicesEditor.Tests -c Release

# Windows x64 und Linux x64 inklusive Laufzeit und ZIP bauen
./importer/ServicesEditor/build.sh

# Einzelnes Ziel oder ARM64
./importer/ServicesEditor/build.sh win-x64
./importer/ServicesEditor/build.sh win-arm64 linux-arm64
```

Ausgaben: `importer/ServicesEditor/dist/<Ziel>/` und
`importer/ServicesEditor/dist/services-editor-1.0.0-<Ziel>.zip`.
Die Einzeldatei-Veröffentlichung entpackt native Bibliotheken beim Start in das
plattformübliche temporäre .NET-Verzeichnis. Dafür ist ein beschreibbarer
Benutzer-/Tempbereich erforderlich. Kein Native-AOT-Build.

Der Windows-Build wird unter Linux erzeugt. Eine abschließende Prüfung der
Windows-Dateidialoge, Darstellung und Ausführung muss auf Windows erfolgen.

## Versionshistorie

- **1.0.0 (2026-11-18):** Erste Ausgabe mit Service-Liste, Detailmasken,
  Portgruppen-/Serverbearbeitung, Schema-Prüfung, Sicherungen und Linux-Cross-Build.
