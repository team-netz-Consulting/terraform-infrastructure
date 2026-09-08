# Terraform Infrastructure Manager

Kurze Beschreibung: Dieses Projekt stellt ein menuegefuehrtes Verwaltungswerkzeug fuer Terraform-Umgebungen mit GitLab-Anbindung bereit. Es hilft dabei, lokale Terraform-Umgebungen aus Templates zu erstellen, nach Branches zu trennen und Git-Workflows wie Pull, Commit, Push, Diff und Branch-Auswahl einheitlich auszufuehren.

## Zweck

Das Projekt soll die Arbeit mit Terraform-Infrastruktur reproduzierbarer und leichter bedienbar machen. Statt Terraform-Umgebungen und Git-Kommandos manuell zusammenzusuchen, fuehrt `manage-terraform.py` durch die wichtigsten Aufgaben:

- aktive Terraform-Umgebung auswaehlen
- Zielbranch `develop` oder `master` festlegen
- Umgebung aus einem Alteon- oder NetScaler-ADC-Template erstellen
- Umgebung aus GitLab klonen
- lokale und entfernte Aenderungen per Git verwalten
- Terraform-Befehle wie `init`, `validate`, `plan` und `apply` ausfuehren

Die lokale Struktur ist auf getrennte Branch-Verzeichnisse ausgelegt, zum Beispiel:

```text
environments/
└── voh/
    ├── develop/
    └── master/
```

## Start

Unter Linux kann das Wrapper-Skript verwendet werden:

```bash
./manage-terraform.sh
```

Alternativ kann das Python-Skript direkt gestartet werden:

```bash
python3 manage-terraform.py
```

Beim ersten Start wird bei Bedarf eine Konfigurationsdatei `manage-terraform.conf` angelegt.

## Voraussetzungen

- Python 3
- Git
- Terraform
- Zugriff auf die konfigurierte GitLab-Gruppe
- GitLab Access Token oder Benutzer/Passwort fuer GitLab-Operationen

## Konfiguration

Die wichtigsten Einstellungen liegen in `manage-terraform.conf`, unter anderem:

- `ROOT_DIR`: Projektwurzel
- `TEMPLATE_DIR`: Stammordner der ADC-Vorlagen (`alteon`, `alteon-*`,
  `netscaler` und `netscaler-*`)
- `ENVIRONMENTS_DIR`: Ablageort der Umgebungen
- `UPDATE_CHECK_ENABLED`: lokale Updatepruefung beim Programmstart aktivieren
- `UPDATE_SOURCE_DIR`: Quellordner einer neueren Programmversion
- `GIT_GROUP_URL_NETSCALER`: Wurzelgruppe für alle NetScaler-Projekte
- `GIT_GROUP_URL_ALTEON`: Wurzelgruppe für alle Alteon-Projekte
- `GIT_GROUP_URL`: gemeinsamer Rückwärtskompatibilitäts-Fallback
- `GIT_REMOTE_URL`: separates Git-Remote des Hauptprojekts (GitHub)
- `TERRAFORM_TARGET_BRANCH`: aktueller Zielbranch, `develop` oder `master`
- `ACTIVE_ENVIRONMENT`: aktuell ausgewaehlte Umgebung
- `ALTEON_USE_LINUXENV`: Alteon-Zugangsdaten vor Terraform-Aufrufen abfragen
- `NETSCALER_USE_LINUXENV`: NetScaler-Zugangsdaten vor Terraform-Aufrufen abfragen

Ist `UPDATE_SOURCE_DIR` gesetzt, vergleicht das Programm beim Start die dortige
`SCRIPT_VERSION` und `SCRIPT_BUILD` mit der installierten Version. Eine neuere
Version wird nur nach Bestaetigung uebernommen. `manage-terraform.conf` und
`environments/` werden dabei nicht ueberschrieben.

Beim Erstellen einer Umgebung wird zuerst der ADC-Typ und danach das konkrete
Template ausgewählt. Neben den Standardverzeichnissen `alteon` und `netscaler`
werden automatisch alle Verzeichnisse mit dem Präfix `alteon-` beziehungsweise
`netscaler-` angeboten. Beispielsweise erscheinen für NetScaler die Templates
`netscaler (Standard)`, `netscaler-basis` und `netscaler-gslb`. Ein
Template-Verzeichnis muss mindestens eine `.tf`-Datei enthalten. Das
Alteon-Template verwendet `Radware/alteon`, das NetScaler-Template
`citrix/citrixadc`. Fuer
NetScaler muss `netscaler_endpoint` beispielsweise in einer `terraform.tfvars`
oder als `TF_VAR_netscaler_endpoint` gesetzt werden. Passwoerter werden nicht in
der Konfigurationsdatei gespeichert.

Neue Environment-Repositories erhalten automatisch einen initialen `master`-
Branch und einen davon abgeleiteten `develop`-Branch. Beide Branches werden zum
Environment-Remote gepusht; anschließend bleibt `develop` lokal ausgecheckt.

GitLab-Projekte in vorhandenen Untergruppen werden rekursiv erkannt. Die Suche
beginnt exakt bei `GIT_GROUP_URL_NETSCALER` beziehungsweise
`GIT_GROUP_URL_ALTEON`; der Manager hängt keinen festen Gruppennamen an. Der
Pfad relativ zur jeweiligen Wurzelgruppe wird lokal unter dem ADC-Typ
gespiegelt. Ein Projekt `team-netz/netscalerADC/kunde/ns1/gslb` liegt daher
beispielsweise unter `environments/netscaler/kunde/ns1/gslb`. Beim Erstellen einer Umgebung wird
eine vorhandene Ziel-Subgroup passend zum gewählten ADC-Typ ausgewählt; das
Werkzeug erstellt keine Subgroups.

## Git-Befehle ohne Python-Menü

Die folgenden Befehle bilden den Ablauf von `manage-terraform.py` manuell ab.
Im Beispiel lautet das GitLab-Projekt:

```text
https://gitlab.team-netz.net/team-netz/netscalerADC/kunde/ns1/gslb
```

### Neue lokale Umgebung mit einem leeren GitLab-Projekt verbinden

Zuerst in das Verzeichnis wechseln, das die Terraform-Dateien enthält:

```bash
cd environments/netscaler/kunde/ns1/gslb
```

Bei der Struktur `master_develop` stattdessen in den gewünschten Branch-Ordner
wechseln, beispielsweise:

```bash
cd environments/netscaler/kunde/ns1/gslb/develop
```

Danach das Repository initialisieren und das GitLab-Remote eintragen:

```bash
git init --initial-branch master
git remote add origin https://gitlab.team-netz.net/team-netz/netscalerADC/kunde/ns1/gslb.git
git remote -v
```

Falls `origin` bereits existiert, wird – wie im Python-Manager – seine URL
aktualisiert:

```bash
git remote set-url origin https://gitlab.team-netz.net/team-netz/netscalerADC/kunde/ns1/gslb.git
```

Den initialen Stand committen und `master` veröffentlichen:

```bash
git add .
git commit -m "Initial Terraform environment netscaler/kunde/ns1/gslb"
git branch -M master
git push -u origin master
```

Anschließend den Arbeitsbranch `develop` anlegen und veröffentlichen:

```bash
git checkout -b develop master
git push -u origin develop
```

Damit entspricht das Ergebnis dem geführten Python-Ablauf: `master` und
`develop` existieren auf GitLab, und lokal ist anschließend `develop`
ausgecheckt.

### Vorhandenes GitLab-Projekt klonen

Bei `ENVIRONMENT_FOLDER_STRUCTURE=single`:

```bash
git clone https://gitlab.team-netz.net/team-netz/netscalerADC/kunde/ns1/gslb.git \
  environments/netscaler/kunde/ns1/gslb
cd environments/netscaler/kunde/ns1/gslb
git checkout develop
```

Bei `ENVIRONMENT_FOLDER_STRUCTURE=master_develop` kann jeder Branch in sein
eigenes Verzeichnis geklont werden:

```bash
git clone --branch develop \
  https://gitlab.team-netz.net/team-netz/netscalerADC/kunde/ns1/gslb.git \
  environments/netscaler/kunde/ns1/gslb/develop

git clone --branch master \
  https://gitlab.team-netz.net/team-netz/netscalerADC/kunde/ns1/gslb.git \
  environments/netscaler/kunde/ns1/gslb/master
```

### Täglicher Git-Ablauf

```bash
git status
git pull --ff-only origin develop
git add .
git commit -m "Beschreibung der Änderung"
git push origin develop
```

Vor dem Wechsel auf `master` sollten Änderungen zuerst geprüft und kontrolliert
übernommen werden:

```bash
git checkout master
git pull --ff-only origin master
git fetch origin develop
git merge --no-ff origin/develop
git push origin master
```

`git push -f` beziehungsweise die kombinierte Form `git push -uf` wird hier
nicht verwendet, weil ein Force-Push vorhandene Remote-Historie überschreiben
kann. Der Python-Manager verwendet ebenfalls `git push -u` ohne `-f`.

Die Standardbranches stammen aus `MASTER_BRANCH` und `DEVELOP_BRANCH` in
`manage-terraform.conf`. Soll stattdessen `main` verwendet werden, muss
`MASTER_BRANCH="main"` konfiguriert und in den obigen Befehlen `master` durch
`main` ersetzt werden.

## Direkte CLI-Shell

Das Skript `terraform-cli.sh` öffnet eine interaktive Shell im aktiven
Environment. Es liest `manage-terraform.conf`, erkennt den Terraform-Provider
und setzt die dazugehörigen Alteon- oder NetScaler-Zugangsdaten. Außerdem wird
die konfigurierte GitLab-Anmeldung über ein temporäres Askpass-Skript für
Git-Kommandos bereitgestellt:

```bash
./terraform-cli.sh
./terraform-cli.sh netscaler/kunde/ns1/gslb develop
```

Die erste Variante verwendet `ACTIVE_ENVIRONMENT` und
`TERRAFORM_TARGET_BRANCH`. Terraform lädt vorhandene `terraform.tfvars` im
Environment weiterhin automatisch. Zugangspasswörter gelten nur innerhalb der
geöffneten Subshell und das temporäre Askpass-Skript wird beim Verlassen
entfernt.

## Terraform-Hinweis

Terraform State sollte nicht direkt in diesem Repository verwaltet werden. Fuer produktive Nutzung wird ein Remote Backend mit Locking und Versionierung empfohlen. Weitere Hinweise stehen in `HowTo-Terraform.md`.

## Lizenz

Das Skript und die Projektdateien stehen unter der Apache License 2.0.
