# Services JSON Editor 1.1.2

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

Die Anwendung lädt `services.schema.json` (Draft 2020-12) als externe Datei aus
**dem Verzeichnis der Anwendung**, unabhängig vom aktuellen Arbeitsverzeichnis.
Die ZIP-Ausgaben enthalten diese Datei neben der EXE bzw. Linux-Anwendung.
Sie kann ohne Neubau ausgetauscht oder erweitert werden. Über **Schema wählen**
kann eine andere lokale Schema-Datei ausgewählt werden. Nach erfolgreichem Laden
wird deren vollständiger Pfad als `LastSchemaPath` in `appsettings.json` neben der
Anwendung gespeichert. Beim nächsten Start wird dieser Pfad wieder geladen.
Die Auswahl bleibt auch beim Öffnen oder Anlegen von Dokumenten erhalten.
Der aktive vollständige Schema-Pfad steht unten im Fenster.

Fehlt `appsettings.json`, wird sie mit dem Standard-Schema-Pfad angelegt und ein
kurzer Hinweis angezeigt. Fehlt die gespeicherte Schema-Datei, erscheint ebenfalls
ein Hinweis; der Pfad bleibt erhalten und über **Schema wählen** kann eine andere
Datei geladen werden. Eine fehlerhafte Einstellungsdatei wird nicht überschrieben;
der Editor meldet das Problem und verwendet zunächst den Standard-Pfad.
Das Anwendungsverzeichnis muss zum Speichern der Einstellungen beschreibbar sein.
Bei einem Speicherfehler bleibt die aktuelle Schema-Auswahl aktiv, wird aber nicht
für den nächsten Start gespeichert. Bereits vorhandene Einstellungen bleiben beim
Aktualisieren des Schema-Pfads erhalten.

Beispiel für `appsettings.json` (wird bei Bedarf automatisch angelegt):

```json
{
  "LastSchemaPath": "C:/Konfiguration/services.schema.json"
}
```

Bei jedem **Prüfen** und **Speichern** wird die Datei erneut eingelesen; es gibt
keinen Rückfall auf eine eingebettete oder zwischengespeicherte Version.
**Schema neu laden** aktualisiert zusätzlich die Detailmasken. Fehlt die Datei oder
ist sie syntaktisch bzw. nach dem Draft-2020-12-Metaschema ungültig, erscheint eine
Fehlermeldung und das Speichern bleibt gesperrt. Die Schema-Datei selbst kann nicht
mit Servicedaten überschrieben werden.

Die Prüfung erfolgt mit JsonSchema.Net einschließlich IPv4-Formaten,
Pflichtfeldern, Wertebereichen, eindeutigen Ports, Namen und unbekannten Eigenschaften.
Es werden keine Dateien oder Konfigurationsdaten an einen Server übertragen.

Neue Felder in `properties` der Service-, Portgruppen- und Member-Definitionen
erscheinen nach dem Neuladen automatisch. String-Felder werden als Textfelder,
String-Enums als Auswahllisten, Zahlen als Zahlen-Eingaben und Boolean-Felder als
Checkboxen dargestellt. `required`, `title` und `description` werden berücksichtigt.
Optionale Felder lassen sich entfernen; ein leerer Checkbox-Zustand entfernt die
Eigenschaft. Lokale `$ref`-Verweise, beispielsweise auf `$defs`, werden für diese
Masken aufgelöst. Geänderte Enumwerte sind ohne Programmanpassung auswählbar.

Objekte, Arrays, gemischte Typen und sonstige komplexe Erweiterungen erhalten einen
JSON-Bearbeitungsdialog. Über **JSON bearbeiten** lässt sich außerdem das komplette
Dokument ändern, einschließlich neuer Eigenschaften auf der obersten Ebene. Das
Übernehmen erfordert syntaktisch gültiges JSON ohne doppelte Schlüssel. Schemafehler
dürfen während der Bearbeitung bestehen bleiben; das Speichern erfordert ein
gültiges Dokument. Die JSON-Vorschau bleibt schreibgeschützt.

Die Anwendung bleibt ein Services-Editor: Die Grundstruktur `services` als Objekt
mit Service-Objekten sowie die vorhandene Portgruppen-/Member-Struktur müssen
erhalten bleiben. Bedingte Schemata (`oneOf`, `if` usw.) und externe `$ref`-Dateien
werden nicht automatisch in eigene Masken übersetzt; komplexe Felder können über
den JSON-Dialog bearbeitet werden. Das Schema ist auch für neue Felder bei der
Prüfung maßgeblich.

Unbekannte JSON-Eigenschaften bleiben beim Laden erhalten und erscheinen als
Schemafehler, wenn das aktive Schema sie nicht erlaubt. Strukturen, die die Maske nicht darstellen kann, sowie doppelte
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
`importer/ServicesEditor/dist/services-editor-1.1.2-<Ziel>.zip`.
Die Einzeldatei-Veröffentlichung entpackt native Bibliotheken beim Start in das
plattformübliche temporäre .NET-Verzeichnis. Dafür ist ein beschreibbarer
Benutzer-/Tempbereich erforderlich. Kein Native-AOT-Build.

Der Windows-Build wird unter Linux erzeugt. Eine abschließende Prüfung der
Windows-Dateidialoge, Darstellung und Ausführung muss auf Windows erfolgen.

## Versionshistorie

- **1.1.2 (2026-11-19):** Letzten Schema-Pfad in `appsettings.json` speichern,
  beim Start wiederherstellen und auf fehlende Dateien hinweisen.

- **1.1.1 (2026-11-19):** Kleinere Schrift in Masken, Listen und Dialogen (12),
  ergänzende Texte (11) und Service-Überschriften (20).

- **1.1.0 (2026-11-19):** Externes, bei jeder Prüfung neu gelesenes Schema,
  Schemaauswahl, dynamische Felder und Enumwerte sowie JSON-Bearbeitung für Erweiterungen.
- **1.0.0 (2026-11-18):** Erste Ausgabe mit Service-Liste, Detailmasken,
  Portgruppen-/Serverbearbeitung, Schema-Prüfung, Sicherungen und Linux-Cross-Build.
