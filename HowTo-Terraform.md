# HowTo: Terraform mit Git integrieren

## Ziel

Dieses How-To beschreibt ein grobes Konzept, wie Terraform-Code (`*.tf`) und Terraform State sauber mit Git integriert werden können.

Ziel ist, dass Infrastrukturänderungen nachvollziehbar, überprüfbar und reproduzierbar sind.

---

## Grundprinzip

Git verwaltet den Terraform-Code, aber nicht den produktiven Terraform State.

```text
Git Repository  -> Terraform-Code, Module, Doku, Pipeline-Dateien
Remote Backend  -> Terraform State, Locking, Versionierung
CI/CD Pipeline  -> Prüfung, Plan, Apply mit Freigabe
```

Der Terraform State enthält Informationen über reale Ressourcen. Deshalb sollte er nicht lokal auf einzelnen Rechnern oder direkt im Git Repository gepflegt werden.

---

## Repository-Struktur

Beispielstruktur:

```text
terraform-infrastructure/
├── README.md
├── HowTo-Terraform.md
├── .gitignore
├── modules/
│   ├── network/
│   ├── compute/
│   └── database/
└── environments/
    ├── dev/
    │   ├── provider.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars.example
    ├── test/
    │   ├── provider.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars.example
    └── prod/
        ├── provider.tf
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars.example
```

Empfehlung:

- Pro Umgebung ein eigener Ordner.
- Pro Umgebung ein eigener State.
- Wiederverwendbare Logik in `modules/` auslagern.
- Produktive Änderungen immer über Pull Request oder Merge Request nachvollziehen.

---

## Was gehört in Git?

In Git gehören:

```text
*.tf
*.tf.json
*.tfvars.example
README.md
HowTo-Terraform.md
.gitignore
CI/CD-Konfigurationen
Dokumentation
```

Beispiele:

```text
main.tf
variables.tf
outputs.tf
backend.tf
provider.tf
terraform.tfvars.example
.gitlab-ci.yml
.github/workflows/terraform.yml
```

---

## Was gehört nicht in Git?

Nicht in Git gehören:

```text
*.tfstate
*.tfstate.*
.terraform/
*.tfvars mit Secrets
crash.log
override.tf
*_override.tf
```

Beispiel `.gitignore`:

```gitignore
# Terraform Arbeitsverzeichnis
.terraform/

# Terraform State
*.tfstate
*.tfstate.*

# Crash Logs
crash.log
crash.*.log

# Sensitive Variablenwerte
*.tfvars
*.tfvars.json

# Lokale Overrides
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# CLI Config
.terraformrc
terraform.rc

# Plan-Dateien
*.tfplan
plan.out
```

Wichtig: `*.tfvars` werden ignoriert, weil sie häufig sensible Werte enthalten. Stattdessen sollte eine `terraform.tfvars.example` ohne Secrets committed werden.

Beispiel `terraform.tfvars.example`:

```hcl
project_name = "example"
environment  = "dev"
region       = "eu-central-1"
```

---

## Terraform State Konzept

Der State wird in einem Remote Backend gespeichert.

Beispiel AWS S3:

```hcl
terraform {
  backend "s3" {
    bucket       = "company-terraform-state"
    key          = "prod/network/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

Empfohlene Eigenschaften des Backends:

- Remote Speicherung statt lokaler State-Dateien.
- Verschlüsselung aktivieren.
- Versionierung aktivieren.
- State Locking aktivieren.
- Zugriff über IAM/Rollen einschränken.
- Pro Umgebung separaten State verwenden.

Beispiel State-Aufteilung:

```text
dev/network/terraform.tfstate
dev/compute/terraform.tfstate
test/network/terraform.tfstate
test/compute/terraform.tfstate
prod/network/terraform.tfstate
prod/compute/terraform.tfstate
```

Vorteil:

- Änderungen sind besser isoliert.
- Fehler in `dev` beeinflussen nicht direkt `prod`.
- Locking verhindert parallele Schreibzugriffe auf denselben State.

---

## Git Workflow

Empfohlener Ablauf:

```bash
git checkout -b feature/change-network

terraform fmt
terraform validate
terraform plan

git add .
git commit -m "Change network subnet layout"
git push origin feature/change-network
```

Danach:

1. Pull Request oder Merge Request erstellen.
2. Review durchführen.
3. Terraform Plan prüfen.
4. Änderungen freigeben.
5. Merge nach `main`.
6. Apply über CI/CD Pipeline ausführen.

---

## Branching-Modell

Ein einfaches Modell:

```text
main
 ├── feature/add-vpc
 ├── feature/change-tags
 └── bugfix/fix-security-group
```

Regeln:

- `main` enthält nur geprüfte Änderungen.
- Direkte Commits auf `main` vermeiden.
- Änderungen erfolgen über Feature Branches.
- Jeder Merge Request enthält einen Terraform Plan.
- Für `prod` ist eine manuelle Freigabe erforderlich.

---

## CI/CD Pipeline Konzept

### Bei Pull Request / Merge Request

Pipeline-Schritte:

```text
terraform fmt -check
terraform init
terraform validate
terraform plan
```

Ziel:

- Format prüfen.
- Syntax prüfen.
- Plan erzeugen.
- Reviewern zeigen, welche Infrastruktur geändert wird.

### Nach Merge nach main

Pipeline-Schritte:

```text
terraform init
terraform plan
manuelle Freigabe
terraform apply
```

Für produktive Umgebungen sollte `terraform apply` nur nach Freigabe ausgeführt werden.

---

## Beispiel GitLab CI

```yaml
stages:
  - validate
  - plan
  - apply

variables:
  TF_IN_AUTOMATION: "true"

before_script:
  - terraform --version
  - terraform init

validate:
  stage: validate
  script:
    - terraform fmt -check
    - terraform validate

plan:
  stage: plan
  script:
    - terraform plan -out=plan.tfplan
  artifacts:
    paths:
      - plan.tfplan
    expire_in: 1 day

apply:
  stage: apply
  script:
    - terraform apply -auto-approve plan.tfplan
  when: manual
  only:
    - main
```

Hinweis: In der Praxis sollte die Pipeline pro Umgebung getrennt laufen, zum Beispiel mit separaten Jobs für `dev`, `test` und `prod`.

---

## Beispiel GitHub Actions

```yaml
name: Terraform

on:
  pull_request:
  push:
    branches:
      - main

jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format
        run: terraform fmt -check

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
```

Hinweis: Für produktive Umgebungen sollte zusätzlich ein Approval-Mechanismus verwendet werden.

---

## Secrets und Variablen

Sensible Werte gehören nicht in Git.

Geeignete Orte für Secrets:

- CI/CD Secret Store
- HashiCorp Vault
- Cloud Secret Manager
- GitHub Actions Secrets
- GitLab CI/CD Variables
- AWS Secrets Manager
- Azure Key Vault
- Google Secret Manager

Beispiele für sensible Werte:

```text
Passwörter
API Keys
Tokens
Private Keys
Zugangsdaten
```

Variablen ohne Secrets können als Beispiel committed werden:

```hcl
# terraform.tfvars.example
project_name = "example"
environment  = "dev"
region       = "eu-central-1"
```

---

## Nachvollziehbarkeit

Änderungen werden nachvollziehbar durch:

```text
Git Commit History
Pull Requests / Merge Requests
Code Reviews
Terraform Plan als Artefakt
CI/CD Logs
Remote State Versioning
Backend Access Logs
```

Jede Änderung sollte beantworten können:

```text
Wer hat geändert?
Was wurde geändert?
Warum wurde geändert?
Wann wurde geändert?
Welche Ressourcen waren betroffen?
Wer hat freigegeben?
```

---

## Empfohlene Commit Messages

Beispiele:

```text
Add dev VPC module
Change prod subnet CIDR ranges
Fix security group ingress rule
Add tagging standard for S3 buckets
Refactor network module variables
```

Optional kann ein Commit-Stil genutzt werden:

```text
feat: add network module
fix: restrict database ingress
refactor: simplify environment variables
docs: add terraform state concept
```

---

## Betriebsregeln

Empfohlene Regeln für Teams:

1. Kein produktiver State in Git.
2. Kein lokales `terraform apply` auf `prod`.
3. Änderungen nur über Pull Request oder Merge Request.
4. Jeder Merge Request benötigt einen aktuellen Terraform Plan.
5. State Backend muss Locking verwenden.
6. State Backend muss versioniert sein.
7. Secrets dürfen nicht committed werden.
8. `main` ist geschützt.
9. `prod` benötigt manuelle Freigabe.
10. Terraform Module werden wiederverwendbar aufgebaut.

---

## Minimaler Ablauf für Entwickler

```bash
# Repository klonen
git clone <repository-url>
cd terraform-infrastructure/environments/dev

# Neuen Branch erstellen
git checkout -b feature/my-change

# Terraform initialisieren
terraform init

# Formatieren und prüfen
terraform fmt
terraform validate

# Änderung planen
terraform plan

# Änderungen committen
git add .
git commit -m "Describe infrastructure change"
git push origin feature/my-change
```

Danach Pull Request oder Merge Request erstellen.

---

## Review Checkliste

Vor dem Merge prüfen:

```text
Ist der Terraform Plan plausibel?
Werden unerwartet Ressourcen gelöscht?
Sind Secrets ausgeschlossen?
Sind Namen, Tags und Regionen korrekt?
Ist die Änderung auf die richtige Umgebung begrenzt?
Wurde das Modul wiederverwendbar umgesetzt?
Ist der State getrennt von anderen Umgebungen?
```

---

## Quellen und Referenzen

- Terraform State Backends: https://developer.hashicorp.com/terraform/language/state/backends
- Terraform S3 Backend: https://developer.hashicorp.com/terraform/language/backend/s3
- Terraform State Locking: https://developer.hashicorp.com/terraform/language/state/locking
- Terraform Sensitive Variables: https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables
- Terraform Variables: https://developer.hashicorp.com/terraform/language/values/variables
- GitHub Terraform .gitignore Vorlage: https://github.com/github/gitignore/blob/main/Terraform.gitignore

---

## Kurzfazit

Terraform-Code gehört in Git. Terraform State gehört in ein Remote Backend.

So werden Infrastrukturänderungen über Git, Reviews, Plans, CI/CD Logs und State-Versionierung nachvollziehbar.
