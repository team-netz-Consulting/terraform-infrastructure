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
- `TEMPLATE_DIR`: Stammordner der ADC-Vorlagen (`alteon` und `netscaler`)
- `ENVIRONMENTS_DIR`: Ablageort der Umgebungen
- `GIT_GROUP_URL`: GitLab-Gruppe fuer Umgebungs-Repositories
- `TERRAFORM_TARGET_BRANCH`: aktueller Zielbranch, `develop` oder `master`
- `ACTIVE_ENVIRONMENT`: aktuell ausgewaehlte Umgebung
- `ALTEON_USE_LINUXENV`: Alteon-Zugangsdaten vor Terraform-Aufrufen abfragen
- `NETSCALER_USE_LINUXENV`: NetScaler-Zugangsdaten vor Terraform-Aufrufen abfragen

Beim Erstellen einer Umgebung wird der ADC-Typ ausgewaehlt. Das Alteon-Template
verwendet `Radware/alteon`, das NetScaler-Template `citrix/citrixadc`. Fuer
NetScaler muss `netscaler_endpoint` beispielsweise in einer `terraform.tfvars`
oder als `TF_VAR_netscaler_endpoint` gesetzt werden. Passwoerter werden nicht in
der Konfigurationsdatei gespeichert.

## Terraform-Hinweis

Terraform State sollte nicht direkt in diesem Repository verwaltet werden. Fuer produktive Nutzung wird ein Remote Backend mit Locking und Versionierung empfohlen. Weitere Hinweise stehen in `HowTo-Terraform.md`.

## Lizenz

Das Skript und die Projektdateien stehen unter der Apache License 2.0.
