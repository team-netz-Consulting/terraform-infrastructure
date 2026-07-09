#!/usr/bin/env python3
"""Terraform Umgebungsverwaltung mit GitLab-Integration.

Dieses Skript ist als plattformunabhaengige Alternative zum bisherigen Bash-Skript
gedacht und laeuft unter Linux und Windows (Python 3 vorausgesetzt).
"""

# Versionshistorie
# -----------------------------------------------------------------------------
# Version: 0.2.0
# Build:   20260709-001
# Changes:
#   - Zielbranch pro Umgebung zwischen develop und master umschaltbar gemacht.
#   - GitLab-Funktionen fuer Pull, Commit, Push und Remote/Local-Diff erweitert.
#   - Aktive Umgebung und Terraform-Zielbranch in Header und Menues sichtbar gemacht.
#
# Version: 0.1.0
# Build:   20260708-001
# Changes:
#   - Erste Python-Version der Terraform-Umgebungsverwaltung erstellt.
#   - Grundkonfiguration, lokale Umgebungen und GitLab-Anbindung umgesetzt.

from __future__ import annotations

import argparse
import atexit
import base64
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from urllib import error, parse, request


SCRIPT_VERSION = "0.2.0"
SCRIPT_BUILD = "20260709-001"
SCRIPT_CHANGELOG = (
    "Zielbranch pro Umgebung zwischen develop und master umschaltbar gemacht.",
    "GitLab-Funktionen fuer Pull, Commit, Push und Remote/Local-Diff erweitert.",
    "Aktive Umgebung und Terraform-Zielbranch in Header und Menues sichtbar gemacht.",
)


@dataclass
class ApiResult:
    status_code: int
    body: str


class TerraformManager:
    script_version = SCRIPT_VERSION
    script_build = SCRIPT_BUILD

    def __init__(self, config_file: Optional[Path] = None) -> None:
        self.script_dir = Path(__file__).resolve().parent
        self.config_file = config_file or Path(
            os.environ.get("TERRAFORM_MANAGER_CONFIG", self.script_dir / "manage-terraform.conf")
        )
        self.askpass_script: Optional[Path] = None
        self.config: Dict[str, str] = {}

        atexit.register(self.cleanup_git_askpass)

    def defaults(self) -> Dict[str, str]:
        root_dir = str(self.script_dir)
        return {
            "ROOT_DIR": root_dir,
            "TEMPLATE_DIR": "${ROOT_DIR}/template",
            "ENVIRONMENTS_DIR": "${ROOT_DIR}/environments",
            "MASTER_BRANCH": "master",
            "DEVELOP_BRANCH": "develop",
            "GIT_REMOTE_NAME": "origin",
            "GIT_GROUP_URL": "https://gitlab.team-netz.net/team-netz",
            "GIT_REMOTE_URL": "",
            "GIT_USERNAME": "",
            "GIT_PASSWORD": "",
            "GIT_ACCESS_TOKEN": "",
            "GIT_CREATE_REMOTE_PROJECTS": "true",
            "GITLAB_API_URL": "",
            "GIT_COMMIT_AUTHOR_NAME": "Terraform Manager",
            "GIT_COMMIT_AUTHOR_EMAIL": "terraform-manager@example.local",
            "GIT_TEST_PROJECT_PREFIX": "terraform-manager-test",
            "ACTIVE_ENVIRONMENT": "",
            "TERRAFORM_TARGET_BRANCH": "develop",
        }

    def create_default_config(self) -> None:
        defaults = self.defaults()
        lines = ["# Grundkonfiguration fuer manage-terraform.py"]
        for key, value in defaults.items():
            lines.append(f'{key}="{value}"')
        self.config_file.write_text("\n".join(lines) + "\n", encoding="utf-8")

    def load_config(self) -> None:
        if not self.config_file.exists():
            self.create_default_config()
            print(f"Parameterdatei wurde erstellt: {self.config_file}")

        raw = self.parse_config_file(self.config_file)
        cfg = self.defaults()
        cfg.update(raw)
        cfg = self.expand_config_vars(cfg)

        # Harte Fallbacks wie im Bash-Skript.
        cfg["ROOT_DIR"] = cfg.get("ROOT_DIR", str(self.script_dir)) or str(self.script_dir)
        cfg["TEMPLATE_DIR"] = cfg.get("TEMPLATE_DIR", f'{cfg["ROOT_DIR"]}/template') or f'{cfg["ROOT_DIR"]}/template'
        cfg["ENVIRONMENTS_DIR"] = cfg.get("ENVIRONMENTS_DIR", f'{cfg["ROOT_DIR"]}/environments') or f'{cfg["ROOT_DIR"]}/environments'
        cfg["MASTER_BRANCH"] = cfg.get("MASTER_BRANCH", "master") or "master"
        cfg["DEVELOP_BRANCH"] = cfg.get("DEVELOP_BRANCH", "develop") or "develop"
        cfg["GIT_REMOTE_NAME"] = cfg.get("GIT_REMOTE_NAME", "origin") or "origin"
        cfg["GIT_GROUP_URL"] = cfg.get("GIT_GROUP_URL", "https://gitlab.team-netz.net/team-netz") or "https://gitlab.team-netz.net/team-netz"
        cfg["GIT_REMOTE_URL"] = cfg.get("GIT_REMOTE_URL", "") or ""
        cfg["GIT_USERNAME"] = cfg.get("GIT_USERNAME", "") or ""
        cfg["GIT_PASSWORD"] = cfg.get("GIT_PASSWORD", "") or ""
        cfg["GIT_ACCESS_TOKEN"] = cfg.get("GIT_ACCESS_TOKEN", "") or ""
        cfg["GIT_CREATE_REMOTE_PROJECTS"] = cfg.get("GIT_CREATE_REMOTE_PROJECTS", "true") or "true"
        cfg["GITLAB_API_URL"] = cfg.get("GITLAB_API_URL", "") or ""
        cfg["GIT_COMMIT_AUTHOR_NAME"] = cfg.get("GIT_COMMIT_AUTHOR_NAME", "Terraform Manager") or "Terraform Manager"
        cfg["GIT_COMMIT_AUTHOR_EMAIL"] = cfg.get("GIT_COMMIT_AUTHOR_EMAIL", "terraform-manager@example.local") or "terraform-manager@example.local"
        cfg["GIT_TEST_PROJECT_PREFIX"] = cfg.get("GIT_TEST_PROJECT_PREFIX", "terraform-manager-test") or "terraform-manager-test"
        cfg["ACTIVE_ENVIRONMENT"] = cfg.get("ACTIVE_ENVIRONMENT", "") or ""
        cfg["TERRAFORM_TARGET_BRANCH"] = cfg.get("TERRAFORM_TARGET_BRANCH", "develop") or "develop"

        if cfg["TERRAFORM_TARGET_BRANCH"] not in ("develop", "master"):
            cfg["TERRAFORM_TARGET_BRANCH"] = "develop"

        self.config = cfg
        self.validate_config()

    def validate_config(self) -> None:
        errors: List[str] = []

        root_dir = Path(self.config["ROOT_DIR"]).expanduser()
        template_dir = Path(self.config["TEMPLATE_DIR"]).expanduser()
        environments_dir = Path(self.config["ENVIRONMENTS_DIR"]).expanduser()

        if not root_dir.is_dir():
            errors.append(f"ROOT_DIR ist kein gueltiges Verzeichnis: {root_dir}")
        if not template_dir.is_dir():
            errors.append(f"TEMPLATE_DIR ist kein gueltiges Verzeichnis: {template_dir}")

        try:
            environments_dir.mkdir(parents=True, exist_ok=True)
        except OSError as exc:
            errors.append(f"ENVIRONMENTS_DIR kann nicht erstellt werden: {environments_dir} ({exc})")
        else:
            if not environments_dir.is_dir():
                errors.append(f"ENVIRONMENTS_DIR ist kein gueltiges Verzeichnis: {environments_dir}")

        for key in ("MASTER_BRANCH", "DEVELOP_BRANCH", "GIT_REMOTE_NAME", "GIT_GROUP_URL"):
            if not self.config[key].strip():
                errors.append(f"{key} darf nicht leer sein.")

        if not parse.urlsplit(self.config["GIT_GROUP_URL"]).scheme:
            errors.append(f"GIT_GROUP_URL ist keine gueltige URL: {self.config['GIT_GROUP_URL']}")

        active_environment = self.config.get("ACTIVE_ENVIRONMENT", "").strip()
        if active_environment and not self.validate_environment_name(active_environment):
            errors.append(f"ACTIVE_ENVIRONMENT enthaelt ungueltige Zeichen: {active_environment}")

        if errors:
            print("Konfiguration ist ungueltig:")
            for item in errors:
                print(f"- {item}")
            print(f"Bitte Einstellungen in {self.config_file} pruefen.")
            raise SystemExit(1)

    @staticmethod
    def parse_config_file(path: Path) -> Dict[str, str]:
        cfg: Dict[str, str] = {}
        line_re = re.compile(r'^\s*([A-Z0-9_]+)\s*=\s*"(.*)"\s*$')
        for raw_line in path.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            match = line_re.match(line)
            if match:
                key, value = match.groups()
                cfg[key] = value
        return cfg

    @staticmethod
    def expand_config_vars(cfg: Dict[str, str]) -> Dict[str, str]:
        pattern = re.compile(r"\$\{([A-Z0-9_]+)\}")

        def _expand(value: str, depth: int = 0) -> str:
            if depth > 10:
                return value

            def repl(match: re.Match[str]) -> str:
                var = match.group(1)
                return cfg.get(var, "")

            expanded = pattern.sub(repl, value)
            if expanded == value:
                return expanded
            return _expand(expanded, depth + 1)

        out = dict(cfg)
        for k, v in out.items():
            out[k] = _expand(v)
        return out

    def cleanup_git_askpass(self) -> None:
        if self.askpass_script and self.askpass_script.exists():
            try:
                self.askpass_script.unlink()
            except OSError:
                pass

    def save_config(self) -> None:
        ordered_keys = [
            "ROOT_DIR",
            "TEMPLATE_DIR",
            "ENVIRONMENTS_DIR",
            "MASTER_BRANCH",
            "DEVELOP_BRANCH",
            "GIT_REMOTE_NAME",
            "GIT_GROUP_URL",
            "GIT_REMOTE_URL",
            "GIT_USERNAME",
            "GIT_PASSWORD",
            "GIT_ACCESS_TOKEN",
            "GIT_CREATE_REMOTE_PROJECTS",
            "GITLAB_API_URL",
            "GIT_COMMIT_AUTHOR_NAME",
            "GIT_COMMIT_AUTHOR_EMAIL",
            "GIT_TEST_PROJECT_PREFIX",
            "ACTIVE_ENVIRONMENT",
            "TERRAFORM_TARGET_BRANCH",
        ]

        lines = ["# Grundkonfiguration fuer manage-terraform.py"]
        for key in ordered_keys:
            value = self.config.get(key, "")
            escaped = value.replace("\\", "\\\\").replace('"', '\\"')
            lines.append(f'{key}="{escaped}"')
        self.config_file.write_text("\n".join(lines) + "\n", encoding="utf-8")

    def pause(self) -> None:
        try:
            input("Weiter mit Enter...")
        except EOFError:
            pass

    def print_header(self) -> None:
        if sys.stdout.isatty():
            os.system("cls" if os.name == "nt" else "clear")
        print(f"Terraform Umgebungsverwaltung - Version {self.script_version} (Build {self.script_build})")
        print(f'Root: {self.config["ROOT_DIR"]}')
        print(f"Parameterdatei: {self.config_file}")
        terraform_branch_output = f'Terraform-Zielbranch: {self.config["TERRAFORM_TARGET_BRANCH"]}'
        if sys.stdout.isatty():
            terraform_branch_output = f"\033[1;36m{terraform_branch_output}\033[0m"
        print(terraform_branch_output)
        if self.config.get("ACTIVE_ENVIRONMENT"):
            active_environment_output = f'Aktive Umgebung: {self.config["ACTIVE_ENVIRONMENT"]}'
            if sys.stdout.isatty():
                active_environment_output = f"\033[1;32m{active_environment_output}\033[0m"
            print(active_environment_output)
        print()

    def get_selected_branch(self) -> str:
        branch = self.config.get("TERRAFORM_TARGET_BRANCH", "develop")
        return branch if branch in ("develop", "master") else "develop"

    def get_environment_root(self) -> Path:
        return Path(self.config["ENVIRONMENTS_DIR"])

    def get_environment_branch_path(self, environment_name: str) -> Path:
        return self.get_environment_root() / environment_name / self.get_selected_branch()

    def list_local_environments(self) -> List[str]:
        env_dir = self.get_environment_root()
        if not env_dir.is_dir():
            return []

        environments: List[str] = []
        selected_branch = self.get_selected_branch()
        for candidate in sorted([p for p in env_dir.iterdir() if p.is_dir()], key=lambda p: p.name):
            branch_path = candidate / selected_branch
            if branch_path.is_dir():
                environments.append(candidate.name)
        return environments

    def resolve_environment_path_for_branch(self, environment_name: str) -> Path:
        branch_path = self.get_environment_branch_path(environment_name)
        return branch_path

    def select_active_environment(self) -> None:
        self.print_header()
        print("Aktive Umgebung auswaehlen")
        print()

        environments = self.list_local_environments()
        if not environments:
            print(f'Keine Umgebungen gefunden unter: {self.get_environment_root()}')
            self.pause()
            return

        print("Verfuegbare Umgebungen:")
        for idx, env in enumerate(environments, start=1):
            marker = " (aktiv)" if env == self.config.get("ACTIVE_ENVIRONMENT", "") else ""
            print(f"  {idx}) {env}{marker}")
        print("  0) Abbrechen")
        print()

        selected_raw = input("Auswahl: ").strip()
        if selected_raw == "0":
            print("Auswahl abgebrochen.")
            self.pause()
            return

        if not selected_raw.isdigit():
            print("Ungueltige Auswahl.")
            self.pause()
            return

        selected_index = int(selected_raw)
        if selected_index < 1 or selected_index > len(environments):
            print("Ungueltige Auswahl.")
            self.pause()
            return

        self.config["ACTIVE_ENVIRONMENT"] = environments[selected_index - 1]
        self.save_config()
        print(f'Aktive Umgebung gesetzt: {self.config["ACTIVE_ENVIRONMENT"]}')
        self.pause()

    @staticmethod
    def validate_environment_name(name: str) -> bool:
        return bool(re.match(r"^[A-Za-z0-9._-]+$", name))

    def copy_template_files(self, target_dir: Path) -> None:
        template_dir = Path(self.config["TEMPLATE_DIR"])
        target_dir.mkdir(parents=True, exist_ok=True)
        for item in template_dir.iterdir():
            destination = target_dir / item.name
            if item.is_dir():
                shutil.copytree(item, destination)
            else:
                shutil.copy2(item, destination)

    def get_git_remote_url(self) -> str:
        if self.config["GIT_REMOTE_URL"]:
            return self.config["GIT_REMOTE_URL"]
        project_name = Path(self.config["ROOT_DIR"]).name
        return f'{self.config["GIT_GROUP_URL"].rstrip("/")}/{project_name}.git'

    def get_environment_git_remote_url(self, environment_name: str) -> str:
        return f'{self.config["GIT_GROUP_URL"].rstrip("/")}/{environment_name}.git'

    def get_gitlab_api_url(self) -> str:
        if self.config["GITLAB_API_URL"]:
            return self.config["GITLAB_API_URL"].rstrip("/")
        parsed = parse.urlsplit(self.config["GIT_GROUP_URL"])
        return f"{parsed.scheme}://{parsed.netloc}/api/v4"

    def get_gitlab_base_url(self) -> str:
        parsed = parse.urlsplit(self.config["GIT_GROUP_URL"])
        return f"{parsed.scheme}://{parsed.netloc}"

    def get_gitlab_group_path(self) -> str:
        parsed = parse.urlsplit(self.config["GIT_GROUP_URL"])
        return parsed.path.lstrip("/")

    def ensure_curl_available(self) -> bool:
        # In Python nicht noetig, aber fuer kompatible Meldungen belassen.
        return True

    def check_gitlab_required_packages(self) -> None:
        self.print_header()
        print("GitLab - benoetigte Pakete pruefen")
        print()

        required_commands = (
            ("git", "Git-Operationen wie clone, pull, commit und push"),
            ("ssh", "GitLab-Zugriff per SSH-Remote"),
        )
        missing = []

        for command, description in required_commands:
            path = shutil.which(command)
            if path:
                print(f"[OK]      {command}: {path}")
            else:
                print(f"[FEHLT]   {command}: {description}")
                missing.append(command)

        print()
        if missing:
            print("Fehlende Pakete installieren, bevor GitLab-Funktionen verwendet werden:")
            print(f"  {', '.join(missing)}")
        else:
            print("Alle benoetigten Pakete fuer die GitLab-Kommunikation sind installiert.")
        self.pause()

    def ensure_gitlab_authentication_configured(self) -> bool:
        if self.config["GIT_ACCESS_TOKEN"] or (
            self.config["GIT_USERNAME"] and self.config["GIT_PASSWORD"]
        ):
            return True
        print("Keine GitLab-Anmeldedaten konfiguriert.")
        print(f"Bitte GIT_ACCESS_TOKEN oder GIT_USERNAME/GIT_PASSWORD in {self.config_file} setzen.")
        return False

    def api_request(
        self,
        endpoint: str,
        *,
        method: str = "GET",
        params: Optional[Dict[str, str]] = None,
        data: Optional[Dict[str, str]] = None,
    ) -> ApiResult:
        base_url = self.get_gitlab_api_url()
        url = f"{base_url}{endpoint}"
        if params:
            url = f"{url}?{parse.urlencode(params)}"

        headers: Dict[str, str] = {}
        if self.config["GIT_ACCESS_TOKEN"]:
            headers["PRIVATE-TOKEN"] = self.config["GIT_ACCESS_TOKEN"]
        elif self.config["GIT_USERNAME"] and self.config["GIT_PASSWORD"]:
            raw = f'{self.config["GIT_USERNAME"]}:{self.config["GIT_PASSWORD"]}'.encode("utf-8")
            headers["Authorization"] = "Basic " + base64.b64encode(raw).decode("ascii")

        body: Optional[bytes] = None
        if data is not None:
            body = parse.urlencode(data).encode("utf-8")
            headers["Content-Type"] = "application/x-www-form-urlencoded"

        req = request.Request(url, data=body, headers=headers, method=method)
        try:
            with request.urlopen(req, timeout=20) as resp:
                content = resp.read().decode("utf-8", errors="replace")
                return ApiResult(resp.getcode(), content)
        except error.HTTPError as exc:
            content = exc.read().decode("utf-8", errors="replace")
            return ApiResult(exc.code, content)
        except error.URLError as exc:
            return ApiResult(0, str(exc))

    @staticmethod
    def parse_json(body: str) -> Optional[object]:
        try:
            return json.loads(body)
        except json.JSONDecodeError:
            return None

    def get_gitlab_group_response(self) -> Optional[dict]:
        group_path = self.get_gitlab_group_path()
        encoded_group = parse.quote(group_path, safe="")
        result = self.api_request(f"/groups/{encoded_group}")
        if result.status_code != 200:
            return None
        payload = self.parse_json(result.body)
        if isinstance(payload, dict):
            return payload
        return None

    def create_gitlab_project(self, project_name: str) -> bool:
        if not self.ensure_curl_available() or not self.ensure_gitlab_authentication_configured():
            return False

        group_response = self.get_gitlab_group_response()
        if not group_response:
            print(f"GitLab-Gruppe konnte nicht gelesen werden: {self.get_gitlab_group_path()}")
            return False

        namespace_id = group_response.get("id")
        if not isinstance(namespace_id, int):
            print("GitLab-Namespace-ID konnte nicht aus der API-Antwort ermittelt werden.")
            return False

        result = self.api_request(
            "/projects",
            method="POST",
            data={
                "name": project_name,
                "path": project_name,
                "namespace_id": str(namespace_id),
                "visibility": "private",
            },
        )
        if result.status_code in (200, 201):
            return True

        print("GitLab-Projekt konnte nicht erstellt werden.")
        if result.body:
            print(result.body)
        return False

    def print_gitlab_settings(self) -> None:
        print(f"GitLab API: {self.get_gitlab_api_url()}")
        print(f"GitLab Gruppe: {self.get_gitlab_group_path()}")
        print(f'Git Remote-Basis: {self.config["GIT_GROUP_URL"].rstrip("/")}')
        if self.config["GIT_ACCESS_TOKEN"]:
            print("Authentifizierung: Access Token")
        elif self.config["GIT_USERNAME"] and self.config["GIT_PASSWORD"]:
            print("Authentifizierung: Benutzer/Passwort")
        else:
            print("Authentifizierung: nicht konfiguriert")

    def prepare_git_authentication(self) -> None:
        if not self.ensure_gitlab_authentication_configured():
            return

        username = self.config["GIT_USERNAME"] or "oauth2"
        password = self.config["GIT_ACCESS_TOKEN"] or self.config["GIT_PASSWORD"]

        temp_dir = Path(tempfile.gettempdir())
        if os.name == "nt":
            script_path = temp_dir / "terraform_manager_git_askpass.cmd"
            script_content = "\n".join(
                [
                    "@echo off",
                    "set PROMPT_TEXT=%~1",
                    "echo %PROMPT_TEXT% | findstr /I \"Username\" >NUL && (echo %TERRAFORM_MANAGER_GIT_USERNAME% & exit /b 0)",
                    "echo %PROMPT_TEXT% | findstr /I \"Password\" >NUL && (echo %TERRAFORM_MANAGER_GIT_PASSWORD% & exit /b 0)",
                    "echo.",
                ]
            )
        else:
            script_path = temp_dir / "terraform_manager_git_askpass.sh"
            script_content = (
                "#!/usr/bin/env sh\n"
                "case \"$1\" in\n"
                "  *Username*) printf '%s\\n' \"$TERRAFORM_MANAGER_GIT_USERNAME\" ;;\n"
                "  *Password*) printf '%s\\n' \"$TERRAFORM_MANAGER_GIT_PASSWORD\" ;;\n"
                "  *) printf '\\n' ;;\n"
                "esac"
            )

        script_path.write_text(script_content + "\n", encoding="utf-8")
        if os.name != "nt":
            script_path.chmod(0o700)

        self.askpass_script = script_path
        os.environ["TERRAFORM_MANAGER_GIT_USERNAME"] = username
        os.environ["TERRAFORM_MANAGER_GIT_PASSWORD"] = password

    def git_env(self, auth: bool = False) -> Dict[str, str]:
        env = os.environ.copy()
        env["GIT_EDITOR"] = "true"
        if auth:
            self.prepare_git_authentication()
            if self.askpass_script:
                env["GIT_ASKPASS"] = str(self.askpass_script)
            env["GIT_TERMINAL_PROMPT"] = "0"
        return env

    def run_git(
        self,
        args: List[str],
        *,
        cwd: Optional[Path] = None,
        auth: bool = False,
        capture: bool = False,
        check: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        command = ["git", *args]
        completed = subprocess.run(
            command,
            cwd=str(cwd) if cwd else None,
            env=self.git_env(auth=auth),
            text=True,
            capture_output=capture,
        )
        if check and completed.returncode != 0:
            stderr_output = (completed.stderr or "").strip()
            stdout_output = (completed.stdout or "").strip()
            msg = stderr_output or stdout_output or f"Git-Befehl fehlgeschlagen (Exit-Code {completed.returncode})"
            raise RuntimeError(msg)
        return completed

    def git_available(self) -> bool:
        try:
            self.run_git(["--version"], capture=True, check=True)
            return True
        except Exception:
            return False

    def configure_gitlab_login_for_session(self) -> None:
        self.print_header()
        print("GitLab Anmeldung setzen")
        print()
        print("1) Access Token verwenden")
        print("2) Benutzer und Passwort verwenden")
        print("0) Abbrechen")
        print()

        choice = input("Auswahl: ").strip()
        if choice == "1":
            token = input("GitLab Access Token: ").strip()
            if not token:
                print("Kein Token angegeben.")
                self.pause()
                return
            self.config["GIT_ACCESS_TOKEN"] = token
            self.config["GIT_USERNAME"] = ""
            self.config["GIT_PASSWORD"] = ""
            print("Access Token wurde fuer diese Sitzung gesetzt.")
        elif choice == "2":
            username = input("GitLab Benutzername: ").strip()
            password = input("GitLab Passwort: ").strip()
            if not username or not password:
                print("Benutzername oder Passwort fehlt.")
                self.pause()
                return
            self.config["GIT_USERNAME"] = username
            self.config["GIT_PASSWORD"] = password
            self.config["GIT_ACCESS_TOKEN"] = ""
            print("Benutzer/Passwort wurden fuer diese Sitzung gesetzt.")
        elif choice == "0":
            return
        else:
            print("Ungueltige Auswahl.")

        self.pause()

    def test_gitlab_login(self) -> None:
        self.print_header()
        print("GitLab Anmeldung testen")
        print()
        self.print_gitlab_settings()
        print()

        if not self.ensure_gitlab_authentication_configured():
            self.pause()
            return

        result = self.api_request("/user")
        if result.status_code != 200:
            print("Anmeldung fehlgeschlagen.")
            if result.body:
                print(result.body)
            self.pause()
            return

        payload = self.parse_json(result.body)
        if not isinstance(payload, dict):
            print("Anmeldung fehlgeschlagen: Unerwartete API-Antwort.")
            self.pause()
            return

        print("Anmeldung erfolgreich.")
        print(
            f"Benutzer: {payload.get('name', 'unbekannt')} ({payload.get('username', 'unbekannt')}), "
            f"ID: {payload.get('id', 'unbekannt')}"
        )
        self.pause()

    def show_gitlab_group(self) -> None:
        self.print_header()
        print("GitLab Gruppe pruefen")
        print()
        self.print_gitlab_settings()
        print()

        if not self.ensure_gitlab_authentication_configured():
            self.pause()
            return

        group = self.get_gitlab_group_response()
        if not group:
            print("GitLab-Gruppe konnte nicht gelesen werden.")
            self.pause()
            return

        print("Gruppe gefunden.")
        print(f"Name: {group.get('name', 'unbekannt')}")
        print(f"Pfad: {group.get('full_path', 'unbekannt')}")
        print(f"ID: {group.get('id', 'unbekannt')}")
        print(f"URL: {group.get('web_url', 'unbekannt')}")
        self.pause()

    def list_gitlab_projects_data(self) -> Optional[List[dict]]:
        if not self.ensure_gitlab_authentication_configured():
            return None

        encoded_group = parse.quote(self.get_gitlab_group_path(), safe="")
        result = self.api_request(
            f"/groups/{encoded_group}/projects",
            params={"per_page": "100", "order_by": "name", "sort": "asc"},
        )
        if result.status_code != 200:
            return None

        payload = self.parse_json(result.body)
        if isinstance(payload, list):
            return [item for item in payload if isinstance(item, dict)]
        return None

    def list_gitlab_projects(self) -> None:
        self.print_header()
        print("GitLab Projekte auflisten")
        print()
        self.print_gitlab_settings()
        print()

        projects = self.list_gitlab_projects_data()
        if projects is None:
            print("Projekte konnten nicht gelesen werden.")
            self.pause()
            return

        if not projects:
            print("Keine Projekte in der Gruppe gefunden.")
            self.pause()
            return

        print("Projekte:")
        for proj in projects:
            print(f"  - {proj.get('path_with_namespace', 'unbekannt')} ({proj.get('web_url', 'unbekannt')})")
        self.pause()

    def create_gitlab_test_project(self) -> None:
        self.print_header()
        print("GitLab Testprojekt erstellen")
        print()
        self.print_gitlab_settings()
        print()

        default_name = f'{self.config["GIT_TEST_PROJECT_PREFIX"]}-{self._now_stamp()}'
        entered = input(f"Name des Testprojekts [{default_name}]: ").strip()
        project_name = entered or default_name

        if not self.validate_environment_name(project_name):
            print("Ungueltiger Name. Erlaubt sind Buchstaben, Zahlen, Punkt, Unterstrich und Bindestrich.")
            self.pause()
            return

        remote_url = self.get_environment_git_remote_url(project_name)
        if self.git_available():
            try:
                self.run_git(["ls-remote", remote_url], auth=True, check=True, capture=True)
                print(f"Projekt ist bereits per Git erreichbar: {remote_url}")
                self.pause()
                return
            except Exception:
                pass

        print(f"Lege Testprojekt '{project_name}' an...")
        if self.create_gitlab_project(project_name):
            print(f"Testprojekt wurde erstellt: {remote_url}")
        else:
            print("Testprojekt konnte nicht erstellt werden.")
        self.pause()

    def run_gitlab_full_test(self) -> None:
        self.print_header()
        print("GitLab Gesamttest")
        print()
        self.print_gitlab_settings()
        print()

        if not self.ensure_gitlab_authentication_configured():
            self.pause()
            return

        print("1/3 Anmeldung pruefen...")
        if self.api_request("/user").status_code == 200:
            print("  OK")
        else:
            print("  Fehler")
            self.pause()
            return

        print("2/3 Gruppe pruefen...")
        if self.get_gitlab_group_response() is not None:
            print("  OK")
        else:
            print("  Fehler")
            self.pause()
            return

        print("3/3 Projektliste pruefen...")
        projects = self.list_gitlab_projects_data()
        if projects is not None:
            print("  OK")
        else:
            print("  Fehler")
            self.pause()
            return

        print()
        print("GitLab-Anbindung sieht gut aus.")
        self.pause()

    def show_gitlab_test_menu(self) -> None:
        while True:
            self.print_header()
            print("GitLab-Anbindung testen")
            print()
            self.print_gitlab_settings()
            print()
            print("1) Anmelden fuer diese Sitzung")
            print("2) Gesamttest ausfuehren")
            print("3) Anmeldung testen")
            print("4) Gruppe pruefen")
            print("5) Projekte auflisten")
            print("6) Testprojekt erstellen")
            print("0) Zurueck")
            print()

            choice = input("Auswahl: ").strip()
            if choice == "1":
                self.configure_gitlab_login_for_session()
            elif choice == "2":
                self.run_gitlab_full_test()
            elif choice == "3":
                self.test_gitlab_login()
            elif choice == "4":
                self.show_gitlab_group()
            elif choice == "5":
                self.list_gitlab_projects()
            elif choice == "6":
                self.create_gitlab_test_project()
            elif choice == "0":
                return
            else:
                print("Ungueltige Auswahl.")
                self.pause()

    def create_gitlab_project_if_missing(self, project_name: str, remote_url: str) -> bool:
        if self.config["GIT_CREATE_REMOTE_PROJECTS"].lower() != "true":
            return True

        try:
            self.run_git(["ls-remote", remote_url], auth=True, capture=True)
            return True
        except Exception:
            print(f"GitLab-Projekt '{project_name}' existiert noch nicht oder ist nicht erreichbar.")
            print(f"Lege Projekt in Gruppe '{self.get_gitlab_group_path()}' an...")
            return self.create_gitlab_project(project_name)

    def ensure_environment_git_repository(self, environment_name: str, target_dir: Path) -> bool:
        remote_url = self.get_environment_git_remote_url(environment_name)
        if not self.git_available():
            print("Git ist nicht installiert oder nicht im PATH. Umgebung wurde ohne Git erstellt.")
            return True

        if not self.create_gitlab_project_if_missing(environment_name, remote_url):
            print(f"Remote-Projekt konnte nicht angelegt werden. Lokale Umgebung bleibt bestehen: {target_dir}")
            return False

        try:
            self.run_git(["rev-parse", "--is-inside-work-tree"], cwd=target_dir, capture=True)
        except Exception:
            try:
                self.run_git(["init", "--initial-branch", self.config["MASTER_BRANCH"]], cwd=target_dir)
            except Exception:
                self.run_git(["init"], cwd=target_dir)

        remote_name = self.config["GIT_REMOTE_NAME"]
        try:
            self.run_git(["remote", "get-url", remote_name], cwd=target_dir, capture=True)
            self.run_git(["remote", "set-url", remote_name, remote_url], cwd=target_dir)
        except Exception:
            self.run_git(["remote", "add", remote_name, remote_url], cwd=target_dir)

        try:
            self.run_git(["config", "user.name"], cwd=target_dir, capture=True)
        except Exception:
            self.run_git(["config", "user.name", self.config["GIT_COMMIT_AUTHOR_NAME"]], cwd=target_dir)

        try:
            self.run_git(["config", "user.email"], cwd=target_dir, capture=True)
        except Exception:
            self.run_git(["config", "user.email", self.config["GIT_COMMIT_AUTHOR_EMAIL"]], cwd=target_dir)

        self.run_git(["add", "."], cwd=target_dir)

        needs_commit = True
        try:
            self.run_git(["diff", "--cached", "--quiet"], cwd=target_dir)
            needs_commit = False
        except Exception:
            needs_commit = True

        if needs_commit:
            self.run_git(["commit", "-m", f"Initial Terraform environment {environment_name}"], cwd=target_dir)

        self.run_git(["branch", "-M", self.config["MASTER_BRANCH"]], cwd=target_dir)
        self.run_git(["push", "-u", remote_name, self.config["MASTER_BRANCH"]], cwd=target_dir, auth=True)
        return True

    def ensure_git_repository(self) -> bool:
        try:
            self.run_git(["rev-parse", "--is-inside-work-tree"], cwd=Path(self.config["ROOT_DIR"]), capture=True)
            return True
        except Exception:
            print(f'Kein gueltiges Git-Repository gefunden: {self.config["ROOT_DIR"]}')
            print(f"Bitte Repository initialisieren oder ROOT_DIR in {self.config_file} anpassen.")
            return False

    def ensure_git_remote(self) -> bool:
        remote_name = self.config["GIT_REMOTE_NAME"]
        try:
            self.run_git(["remote", "get-url", remote_name], cwd=Path(self.config["ROOT_DIR"]), capture=True)
            return True
        except Exception:
            remote_url = self.get_git_remote_url()
            if not remote_url:
                print("Kein Git-Remote konfiguriert.")
                return False
            self.run_git(["remote", "add", remote_name, remote_url], cwd=Path(self.config["ROOT_DIR"]))
            return True

    def checkout_git_branch(self, branch_name: str) -> None:
        root = Path(self.config["ROOT_DIR"])
        remote_name = self.config["GIT_REMOTE_NAME"]

        try:
            self.run_git(["show-ref", "--verify", "--quiet", f"refs/heads/{branch_name}"], cwd=root)
            self.run_git(["checkout", branch_name], cwd=root)
            return
        except Exception:
            pass

        try:
            self.run_git(["ls-remote", "--exit-code", "--heads", remote_name, branch_name], cwd=root, auth=True, capture=True)
            self.run_git(["checkout", "-b", branch_name, "--track", f"{remote_name}/{branch_name}"], cwd=root)
            return
        except Exception:
            pass

        self.run_git(["checkout", "-b", branch_name], cwd=root)

    def ensure_repo_branch(self, repo_dir: Path, branch_name: str) -> None:
        remote_name = self.config["GIT_REMOTE_NAME"]

        current_branch = self.get_current_branch_name(repo_dir)
        if current_branch == branch_name:
            return

        try:
            self.run_git(["show-ref", "--verify", "--quiet", f"refs/heads/{branch_name}"], cwd=repo_dir)
            self.run_git(["checkout", branch_name], cwd=repo_dir)
            return
        except Exception:
            pass

        try:
            self.run_git(
                ["ls-remote", "--exit-code", "--heads", remote_name, branch_name],
                cwd=repo_dir,
                auth=True,
                capture=True,
            )
            self.run_git(["checkout", "-b", branch_name, "--track", f"{remote_name}/{branch_name}"], cwd=repo_dir)
            return
        except Exception:
            pass

        self.run_git(["checkout", "-b", branch_name], cwd=repo_dir)

    def remote_branch_exists(self, repo_dir: Path, branch_name: str) -> bool:
        remote_name = self.config["GIT_REMOTE_NAME"]
        try:
            self.run_git(
                ["ls-remote", "--exit-code", "--heads", remote_name, branch_name],
                cwd=repo_dir,
                auth=True,
                capture=True,
            )
            return True
        except Exception:
            return False

    def resolve_git_conflicts(self, repo_dir: Path, *, mode: str) -> bool:
        conflicted = self.run_git(["diff", "--name-only", "--diff-filter=U"], cwd=repo_dir, capture=True).stdout.splitlines()
        if not conflicted:
            return True

        print()
        print("Konflikte gefunden:")
        for file_name in conflicted:
            print(f"  - {file_name}")
        print()
        print("Welche Version soll fuer alle Konfliktdateien uebernommen werden?")
        print("1) Lokal")
        print("2) Remote")
        print("0) Abbrechen")
        print()

        choice = input("Auswahl: ").strip()
        if choice == "0":
            if mode == "rebase":
                self.run_git(["rebase", "--abort"], cwd=repo_dir, check=False)
            elif mode == "merge":
                self.run_git(["merge", "--abort"], cwd=repo_dir, check=False)
            print("Vorgang abgebrochen.")
            return False

        if choice not in ("1", "2"):
            print("Ungueltige Auswahl.")
            return False

        if mode == "rebase":
            checkout_side = "--theirs" if choice == "1" else "--ours"
        else:
            checkout_side = "--ours" if choice == "1" else "--theirs"

        self.run_git(["checkout", checkout_side, "--", *conflicted], cwd=repo_dir)
        self.run_git(["add", *conflicted], cwd=repo_dir)
        return True

    def continue_git_conflict_operation(self, repo_dir: Path, *, mode: str) -> bool:
        if not self.resolve_git_conflicts(repo_dir, mode=mode):
            return False

        try:
            if mode == "rebase":
                self.run_git(["rebase", "--continue"], cwd=repo_dir)
            elif mode == "merge":
                self.run_git(["commit", "--no-edit"], cwd=repo_dir)
            return True
        except Exception as exc:
            print("Fortsetzen nach Konfliktloesung fehlgeschlagen.")
            print(str(exc))
            return False

    def handle_diverging_pull(self, repo_dir: Path, branch_name: str) -> bool:
        remote_name = self.config["GIT_REMOTE_NAME"]
        remote_branch = f"{remote_name}/{branch_name}"

        print()
        print("Lokaler und Remote-Branch sind auseinander gelaufen.")
        print("Was soll gemacht werden?")
        print("1) Rebase: lokale Commits auf Remote neu aufsetzen")
        print("2) Merge: Remote in lokalen Branch mergen")
        print("3) Remote hart uebernehmen (lokale Commits/Aenderungen verwerfen)")
        print("0) Abbrechen")
        print()

        choice = input("Auswahl: ").strip()
        try:
            if choice == "1":
                try:
                    self.run_git(["rebase", remote_branch], cwd=repo_dir)
                    return True
                except Exception:
                    return self.continue_git_conflict_operation(repo_dir, mode="rebase")
            if choice == "2":
                try:
                    self.run_git(["merge", "--no-ff", "--no-edit", remote_branch], cwd=repo_dir)
                    return True
                except Exception:
                    return self.continue_git_conflict_operation(repo_dir, mode="merge")
            if choice == "3":
                confirm = input(f"Lokalen Branch wirklich hart auf '{remote_branch}' setzen? [ja/NEIN] ").strip()
                if confirm != "ja":
                    print("Pull abgebrochen.")
                    return False
                self.run_git(["reset", "--hard", remote_branch], cwd=repo_dir)
                self.run_git(["clean", "-fd"], cwd=repo_dir)
                return True
            if choice == "0":
                print("Pull abgebrochen.")
                return False
        except Exception as exc:
            print("Ausgewaehlte Pull-Strategie fehlgeschlagen.")
            print(str(exc))
            return False

        print("Ungueltige Auswahl.")
        return False

    def ensure_active_environment_repo_for_selected_branch(self) -> Optional[Path]:
        active_environment = self.config.get("ACTIVE_ENVIRONMENT", "")
        if not active_environment:
            print("Keine aktive Umgebung gesetzt.")
            print("Bitte zuerst 'Aktive Umgebung auswaehlen' ausfuehren.")
            return None

        target_dir = self.get_environment_branch_path(active_environment)
        if target_dir.is_dir():
            return target_dir

        target_dir.parent.mkdir(parents=True, exist_ok=True)
        remote_url = self.get_environment_git_remote_url(active_environment)
        print(f"Lokale Struktur fehlt, klone Umgebung neu: {remote_url}")
        print(f"Zielpfad: {target_dir}")

        try:
            self.run_git(["clone", remote_url, str(target_dir)], auth=True)
            self.ensure_repo_branch(target_dir, self.get_selected_branch())
            return target_dir
        except Exception as exc:
            print("Klonen der Umgebung fehlgeschlagen.")
            print(str(exc))
            return None

    def open_selected_branch_for_active_environment(self) -> None:
        self.print_header()
        branch_name = self.get_selected_branch()
        remote_name = self.config["GIT_REMOTE_NAME"]
        print(f"Pull remote to local ({branch_name})")
        print()

        if not self.git_available():
            print("Git ist nicht installiert oder nicht im PATH.")
            self.pause()
            return

        if not self.ensure_gitlab_authentication_configured():
            self.pause()
            return

        target_dir = self.ensure_active_environment_repo_for_selected_branch()
        if target_dir is None:
            self.pause()
            return

        print(f"Arbeitsverzeichnis: {target_dir}")
        try:
            self.ensure_repo_branch(target_dir, branch_name)
        except Exception as exc:
            print("Branch-Wechsel fehlgeschlagen.")
            print(str(exc))
            self.pause()
            return

        if self.remote_branch_exists(target_dir, branch_name):
            try:
                if self.has_uncommitted_changes(target_dir):
                    print("Es gibt lokale, nicht committete Aenderungen.")
                    force_pull = input("Lokale Aenderungen verwerfen und Pull erzwingen? [ja/NEIN] ").strip()
                    if force_pull != "ja":
                        print("Pull abgebrochen.")
                        self.pause()
                        return
                    self.run_git(["fetch", remote_name, branch_name], cwd=target_dir, auth=True)
                    self.run_git(["reset", "--hard", f"{remote_name}/{branch_name}"], cwd=target_dir)
                    self.run_git(["clean", "-fd"], cwd=target_dir)
                else:
                    try:
                        self.run_git(["pull", "--ff-only", remote_name, branch_name], cwd=target_dir, auth=True)
                    except Exception as exc:
                        print("Fast-forward Pull nicht moeglich.")
                        print(str(exc))
                        self.run_git(["fetch", remote_name, branch_name], cwd=target_dir, auth=True)
                        if not self.handle_diverging_pull(target_dir, branch_name):
                            self.pause()
                            return
                print(f"Branch '{branch_name}' wurde aktualisiert.")
            except Exception as exc:
                print("Pull fehlgeschlagen.")
                print(str(exc))
                self.pause()
                return
        else:
            print(
                f"Remote-Branch '{branch_name}' existiert nicht. "
                "Lokaler Branch wurde angelegt, aber es wurde kein Pull ausgefuehrt."
            )

        print(f"Branch '{branch_name}' ist bereit.")
        self.pause()

    def show_git_diff_remote_local(self) -> None:
        self.print_header()
        branch_name = self.get_selected_branch()
        remote_name = self.config["GIT_REMOTE_NAME"]
        print(f"GitLab - Diff remote / local ({branch_name})")
        print()

        if not self.git_available():
            print("Git ist nicht installiert oder nicht im PATH.")
            self.pause()
            return

        env_path = self.ensure_active_environment_path()
        if env_path is None:
            self.pause()
            return

        try:
            self.run_git(["rev-parse", "--is-inside-work-tree"], cwd=env_path, capture=True)
        except Exception:
            print(f"Kein gueltiges Git-Repository fuer aktive Umgebung gefunden: {env_path}")
            self.pause()
            return

        if not self.remote_branch_exists(env_path, branch_name):
            print(f"Remote-Branch '{remote_name}/{branch_name}' existiert nicht.")
            self.pause()
            return

        try:
            self.run_git(["fetch", remote_name, branch_name], cwd=env_path, auth=True)
            status = self.run_git(["status", "--short", "--branch"], cwd=env_path, capture=True).stdout.strip()
            commits = self.run_git(
                ["log", "--left-right", "--cherry-pick", "--oneline", f"HEAD...{remote_name}/{branch_name}"],
                cwd=env_path,
                capture=True,
            ).stdout.strip()
            diff_stat = self.run_git(["diff", "--stat", f"HEAD..{remote_name}/{branch_name}"], cwd=env_path, capture=True).stdout.strip()
        except Exception as exc:
            print("Diff konnte nicht ermittelt werden.")
            print(str(exc))
            self.pause()
            return

        print(f"Arbeitsverzeichnis: {env_path}")
        print()
        print(status or "Keine lokalen Status-Aenderungen.")
        print()
        print("Commit-Differenz:")
        print(commits or "Keine Commit-Differenz zwischen lokalem HEAD und Remote.")
        print()
        print("Datei-Differenz:")
        print(diff_stat or "Keine Datei-Differenz zwischen lokalem HEAD und Remote.")
        self.pause()

    def open_git_branch(self, menu_name: str, branch_name: str) -> None:
        self.print_header()
        print(f"{menu_name}-Branch oeffnen ({branch_name})")
        print()

        if not self.git_available():
            print("Git ist nicht installiert oder nicht im PATH.")
            self.pause()
            return

        if not self.ensure_git_repository():
            self.pause()
            return

        if not self.ensure_git_remote():
            self.pause()
            return

        print(f"Wechsle auf Branch '{branch_name}'...")
        try:
            self.checkout_git_branch(branch_name)
        except Exception as exc:
            print()
            print("Branch-Wechsel fehlgeschlagen.")
            print(str(exc))
            self.pause()
            return

        print()
        print(f"Hole aktuelle Aenderungen von {self.config['GIT_REMOTE_NAME']}/{branch_name}...")
        try:
            self.run_git(
                ["pull", "--ff-only", self.config["GIT_REMOTE_NAME"], branch_name],
                cwd=Path(self.config["ROOT_DIR"]),
                auth=True,
            )
        except Exception:
            print()
            print("Pull fehlgeschlagen. Bitte lokale Aenderungen oder Branch-Konflikte pruefen.")
            self.pause()
            return

        print()
        print(f"Branch '{branch_name}' ist aktuell.")
        self.pause()

    def get_current_branch_name(self, repo_dir: Path) -> Optional[str]:
        try:
            branch = self.run_git(["branch", "--show-current"], cwd=repo_dir, capture=True).stdout.strip()
            return branch if branch else None
        except Exception:
            return None

    def confirm_branch_mismatch(self, current_branch: Optional[str]) -> bool:
        selected_branch = self.get_selected_branch()
        if not current_branch or current_branch == selected_branch:
            return True

        print(
            f"Warnung: Aktueller Branch ist '{current_branch}', aber Terraform-Zielbranch ist '{selected_branch}'."
        )
        confirmation = input("Trotzdem fortfahren? [ja/NEIN] ").strip()
        return confirmation == "ja"

    def commit_git_changes(self) -> None:
        self.print_header()
        print("GitLab - Commit lokal")
        print()

        if not self.git_available():
            print("Git ist nicht installiert oder nicht im PATH.")
            self.pause()
            return

        env_path = self.ensure_active_environment_path()
        if env_path is None:
            self.pause()
            return

        print(f"Zielpfad: {env_path}")

        try:
            self.run_git(["rev-parse", "--is-inside-work-tree"], cwd=env_path, capture=True)
        except Exception:
            print(f"Kein gueltiges Git-Repository fuer aktive Umgebung gefunden: {env_path}")
            self.pause()
            return

        current_branch = self.get_current_branch_name(env_path)
        print(f"Aktueller Branch: {current_branch or 'unbekannt'}")
        print(f"Zielbranch: {self.get_selected_branch()}")
        print()

        if not self.confirm_branch_mismatch(current_branch):
            print("Commit abgebrochen.")
            self.pause()
            return

        try:
            self.run_git(["add", "."], cwd=env_path)
            self.run_git(["diff", "--cached", "--quiet"], cwd=env_path)
        except Exception:
            pass
        else:
            print("Keine lokalen Aenderungen zum Committen gefunden.")
            self.pause()
            return

        message = input("Commit-Nachricht: ").strip()
        if not message:
            message = f"Lokale Aenderungen {self._now_stamp()}"

        try:
            self.run_git(["commit", "-m", message], cwd=env_path)
        except Exception as exc:
            print()
            print("Commit fehlgeschlagen.")
            print(str(exc))
            self.pause()
            return

        print()
        print("Lokaler Commit wurde erstellt.")
        self.pause()

    def push_git_changes(self) -> None:
        self.print_header()
        print("GitLab - Push remote")
        print()

        if not self.git_available():
            print("Git ist nicht installiert oder nicht im PATH.")
            self.pause()
            return

        env_path = self.ensure_active_environment_path()
        if env_path is None:
            self.pause()
            return

        print(f"Zielpfad: {env_path}")

        try:
            self.run_git(["rev-parse", "--is-inside-work-tree"], cwd=env_path, capture=True)
        except Exception:
            print(f"Kein gueltiges Git-Repository fuer aktive Umgebung gefunden: {env_path}")
            self.pause()
            return

        remote_name = self.config["GIT_REMOTE_NAME"]
        try:
            self.run_git(["remote", "get-url", remote_name], cwd=env_path, capture=True)
        except Exception:
            print(f"Kein Git-Remote '{remote_name}' fuer aktive Umgebung konfiguriert: {env_path}")
            self.pause()
            return

        current_branch = self.get_current_branch_name(env_path)
        print(f"Aktueller Branch: {current_branch or 'unbekannt'}")
        print(f"Zielbranch: {self.get_selected_branch()}")
        print()

        if not self.confirm_branch_mismatch(current_branch):
            print("Push abgebrochen.")
            self.pause()
            return

        try:
            branch = current_branch or ""
            if not branch:
                raise RuntimeError("Aktueller Branch konnte nicht ermittelt werden.")
            self.run_git(["push", "-u", remote_name, branch], cwd=env_path, auth=True)
        except Exception as exc:
            print()
            print("Push fehlgeschlagen.")
            print(str(exc))
            self.pause()
            return

        print()
        print("Aenderungen wurden zum Remote gepusht.")
        self.pause()

    def show_gitlab_menu(self) -> None:
        while True:
            self.print_header()
            print("GitLab")
            print()
            print(f"Zielbranch: {self.get_selected_branch()}")
            print("1) Zielbranch festlegen (develop/master)")
            print("2) Pull (remote to local)")
            print("3) Commit lokal")
            print("4) Push (local to remote)")
            print("5) Diff (remote / local)")
            print("6) Anbindung testen")
            print("7) Benoetigte Pakete pruefen")
            print("0) Zurueck")
            print()

            choice = input("Auswahl: ").strip()
            if choice == "1":
                self.set_terraform_target_branch()
            elif choice == "2":
                self.open_selected_branch_for_active_environment()
            elif choice == "3":
                self.commit_git_changes()
            elif choice == "4":
                self.push_git_changes()
            elif choice == "5":
                self.show_git_diff_remote_local()
            elif choice == "6":
                self.show_gitlab_test_menu()
            elif choice == "7":
                self.check_gitlab_required_packages()
            elif choice == "0":
                return
            else:
                print("Ungueltige Auswahl.")
                self.pause()

    def set_terraform_target_branch(self) -> None:
        self.print_header()
        print("Terraform-Zielbranch festlegen")
        print()
        print(f"Aktuell: {self.get_selected_branch()}")
        print("1) develop")
        print("2) master")
        print("0) Abbrechen")
        print()

        choice = input("Auswahl: ").strip()
        if choice == "0":
            print("Abgebrochen.")
            self.pause()
            return

        if choice == "1":
            selected = "develop"
        elif choice == "2":
            selected = "master"
        else:
            print("Ungueltige Auswahl.")
            self.pause()
            return

        self.config["TERRAFORM_TARGET_BRANCH"] = selected
        self.save_config()
        print(f"Terraform-Zielbranch gesetzt: {selected}")
        self.pause()

    def ensure_active_environment_path(self) -> Optional[Path]:
        active_environment = self.config.get("ACTIVE_ENVIRONMENT", "")
        if not active_environment:
            print("Keine aktive Umgebung gesetzt.")
            print("Bitte zuerst 'Aktive Umgebung auswaehlen' im Hauptmenü ausfuehren.")
            return None

        env_path = self.resolve_environment_path_for_branch(active_environment)
        if not env_path.is_dir():
            print(
                f"Aktive Umgebung nicht gefunden fuer Branch '{self.get_selected_branch()}': "
                f"{self.get_environment_branch_path(active_environment)}"
            )
            return None

        return env_path

    def run_terraform_in_active_environment(self, terraform_args: List[str]) -> None:
        self.print_header()
        print("Terraform ausfuehren")
        print()

        if shutil.which("terraform") is None:
            print("Terraform ist nicht installiert oder nicht im PATH.")
            self.pause()
            return

        env_path = self.ensure_active_environment_path()
        if env_path is None:
            self.pause()
            return

        print(f"Branch: {self.get_selected_branch()}")
        print(f"Umgebung: {self.config['ACTIVE_ENVIRONMENT']}")
        print(f"Pfad: {env_path}")
        print(f"Befehl: terraform {' '.join(terraform_args)}")
        print()

        result = subprocess.run(
            ["terraform", *terraform_args],
            cwd=str(env_path),
            text=True,
            capture_output=True,
        )

        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr)

        if result.returncode == 0:
            print("Terraform-Befehl erfolgreich.")
        else:
            print(f"Terraform-Befehl fehlgeschlagen (Exit-Code {result.returncode}).")
        self.pause()

    def show_terraform_menu(self) -> None:
        while True:
            self.print_header()
            print("Terraform")
            print()
            print(f"Zielbranch: {self.get_selected_branch()}")
            print("1) terraform init")
            print("2) terraform validate")
            print("3) terraform plan")
            print("4) terraform apply")
            print("0) Zurueck")
            print()

            choice = input("Auswahl: ").strip()
            if choice == "1":
                self.run_terraform_in_active_environment(["init"])
            elif choice == "2":
                self.run_terraform_in_active_environment(["validate"])
            elif choice == "3":
                self.run_terraform_in_active_environment(["plan"])
            elif choice == "4":
                if self.get_selected_branch() != "master":
                    print("terraform apply ist nur auf dem Zielbranch 'master' moeglich.")
                    self.pause()
                    continue
                confirm = input("Achtung: apply auf Zielbranch 'master'. Fortfahren? [ja/NEIN] ").strip()
                if confirm != "ja":
                    print("Abgebrochen.")
                    self.pause()
                    continue
                self.run_terraform_in_active_environment(["apply"])
            elif choice == "0":
                return
            else:
                print("Ungueltige Auswahl.")
                self.pause()

    def create_environment(self) -> None:
        self.print_header()
        print("Neue Umgebung erstellen")
        print()

        template_dir = Path(self.config["TEMPLATE_DIR"])
        if not template_dir.is_dir():
            print(f"Template-Ordner nicht gefunden: {template_dir}")
            self.pause()
            return

        environment_name = input("Name der neuen Umgebung: ").strip()
        if not environment_name:
            print("Kein Umgebungsname angegeben.")
            self.pause()
            return

        if not self.validate_environment_name(environment_name):
            print("Ungueltiger Name. Erlaubt sind Buchstaben, Zahlen, Punkt, Unterstrich und Bindestrich.")
            self.pause()
            return

        env_dir = self.get_environment_root()
        env_dir.mkdir(parents=True, exist_ok=True)
        target_dir = self.get_environment_branch_path(environment_name)
        if target_dir.exists():
            print(f"Die Umgebung existiert bereits: {target_dir}")
            self.pause()
            return

        self.copy_template_files(target_dir)
        print(f"Umgebung wurde erstellt: {target_dir}")

        print()
        print("Verbinde Umgebung mit Git...")
        if self.ensure_environment_git_repository(environment_name, target_dir):
            print(f"Git-Repository wurde verbunden: {self.get_environment_git_remote_url(environment_name)}")
        else:
            print("Git-Anbindung konnte nicht vollstaendig abgeschlossen werden.")

        self.pause()

    def has_uncommitted_changes(self, repo_dir: Path) -> bool:
        status = self.run_git(["status", "--porcelain"], cwd=repo_dir, capture=True)
        return bool(status.stdout.strip())

    def delete_environment(self) -> None:
        self.print_header()
        print("Bestehende Umgebung loeschen")
        print()

        env_dir = self.get_environment_root()
        if not env_dir.is_dir():
            print(f"Es existiert noch kein Umgebungsordner: {env_dir}")
            self.pause()
            return

        environments = self.list_local_environments()
        if not environments:
            print("Keine Umgebungen gefunden.")
            self.pause()
            return

        print("Vorhandene Umgebungen:")
        for idx, env in enumerate(environments, start=1):
            print(f"  {idx}) {env}")
        print()

        selected_raw = input("Nummer der zu loeschenden Umgebung: ").strip()
        if not selected_raw.isdigit():
            print("Ungueltige Auswahl.")
            self.pause()
            return

        selected_index = int(selected_raw)
        if selected_index < 1 or selected_index > len(environments):
            print("Ungueltige Auswahl.")
            self.pause()
            return

        selected_environment = environments[selected_index - 1]
        target_dir = self.resolve_environment_path_for_branch(selected_environment)
        environment_base_dir = env_dir / selected_environment

        if not target_dir.is_dir():
            print(
                f"Die Umgebung '{selected_environment}' existiert nicht fuer Branch "
                f"'{self.get_selected_branch()}': {self.get_environment_branch_path(selected_environment)}"
            )
            self.pause()
            return

        branch_dirs = sorted(
            [p for p in environment_base_dir.iterdir() if p.is_dir()],
            key=lambda p: p.name,
        )

        print("Loeschmodus:")
        print(f"1) Nur aktuellen Branch loeschen ({self.get_selected_branch()}): {target_dir}")
        if branch_dirs:
            print(f"2) Gesamte Umgebung loeschen (alle Branches): {', '.join([p.name for p in branch_dirs])}")
        else:
            print("2) Gesamte Umgebung loeschen (alle Branches)")
        print("0) Abbrechen")
        print()

        delete_mode = input("Auswahl: ").strip()
        if delete_mode == "0":
            print("Loeschen abgebrochen.")
            self.pause()
            return

        if delete_mode not in ("1", "2"):
            print("Ungueltige Auswahl.")
            self.pause()
            return

        delete_all_branches = delete_mode == "2"
        targets_to_check = branch_dirs if delete_all_branches and branch_dirs else [target_dir]

        if self.git_available():
            dirty_paths: List[Path] = []
            for path in targets_to_check:
                try:
                    self.run_git(["rev-parse", "--is-inside-work-tree"], cwd=path, capture=True)
                    if self.has_uncommitted_changes(path):
                        dirty_paths.append(path)
                except Exception:
                    continue

            if dirty_paths:
                print("Warnung: Es gibt lokale, nicht committete Aenderungen in:")
                for path in dirty_paths:
                    print(f"  - {path}")
                force_delete = input("Trotzdem loeschen? [ja/NEIN] ").strip()
                if force_delete != "ja":
                    print("Loeschen abgebrochen.")
                    self.pause()
                    return

        if delete_all_branches:
            confirm_text = (
                f"Gesamte Umgebung '{selected_environment}' inkl. aller Branches wirklich loeschen? [ja/NEIN] "
            )
        else:
            confirm_text = (
                f"Umgebung '{selected_environment}' nur fuer Branch '{self.get_selected_branch()}' wirklich loeschen? [ja/NEIN] "
            )

        confirm = input(confirm_text).strip()
        if confirm != "ja":
            print("Loeschen abgebrochen.")
            self.pause()
            return

        if delete_all_branches:
            shutil.rmtree(environment_base_dir)
            print(f"Umgebung wurde vollstaendig geloescht: {environment_base_dir}")
        else:
            shutil.rmtree(target_dir)
            if environment_base_dir.exists() and not any(environment_base_dir.iterdir()):
                environment_base_dir.rmdir()
            print(f"Umgebung wurde geloescht: {target_dir}")

        if self.config.get("ACTIVE_ENVIRONMENT") == selected_environment:
            self.config["ACTIVE_ENVIRONMENT"] = ""
            self.save_config()
            print("Aktive Umgebung wurde zurueckgesetzt.")
        self.pause()

    def show_environments(self) -> None:
        self.print_header()
        print("Lokale Umgebungen")
        print()

        env_dir = self.get_environment_root()
        if not env_dir.is_dir():
            print(f"Es existiert noch kein Umgebungsordner: {env_dir}")
            self.pause()
            return

        environments = self.list_local_environments()
        if not environments:
            print("Keine Umgebungen gefunden.")
            self.pause()
            return

        print("Vorhandene Umgebungen:")
        for env in environments:
            marker = " (aktiv)" if env == self.config.get("ACTIVE_ENVIRONMENT", "") else ""
            print(f"  - {env}{marker} [{self.get_selected_branch()}]")
        self.pause()

    def clone_environment_from_gitlab(self) -> None:
        self.print_header()
        print("Umgebung aus GitLab klonen")
        print()
        self.print_gitlab_settings()
        print()

        if not self.git_available():
            print("Git ist nicht installiert oder nicht im PATH.")
            self.pause()
            return

        if not self.ensure_gitlab_authentication_configured():
            self.pause()
            return

        projects = self.list_gitlab_projects_data()
        if projects is None:
            print("Projekte konnten nicht gelesen werden.")
            self.pause()
            return
        if not projects:
            print("Keine Projekte in der Gruppe gefunden.")
            self.pause()
            return

        env_dir = self.get_environment_root()
        env_dir.mkdir(parents=True, exist_ok=True)

        print("Verfuegbare Projekte:")
        project_paths = [str(item.get("path_with_namespace", "")) for item in projects if item.get("path_with_namespace")]
        for idx, path in enumerate(project_paths, start=1):
            print(f"  {idx}) {path}")
        print("  0) Abbrechen")
        print()

        selected_raw = input("Nummer des zu klonenden Projekts: ").strip()
        if selected_raw == "0":
            print("Klonen abgebrochen.")
            self.pause()
            return

        if not selected_raw.isdigit():
            print("Ungueltige Auswahl.")
            self.pause()
            return

        selected_index = int(selected_raw)
        if selected_index < 1 or selected_index > len(project_paths):
            print("Ungueltige Auswahl.")
            self.pause()
            return

        selected_project_path = project_paths[selected_index - 1]
        environment_name = selected_project_path.split("/")[-1]
        target_dir = self.get_environment_branch_path(environment_name)

        if target_dir.exists():
            print(f"Zielordner existiert bereits: {target_dir}")
            self.pause()
            return

        remote_url = f"{self.get_gitlab_base_url()}/{selected_project_path}.git"
        print(f"Klonen: {remote_url}")
        print(f"Zielpfad: {target_dir}")

        try:
            target_dir.parent.mkdir(parents=True, exist_ok=True)
            self.run_git(["clone", remote_url, str(target_dir)], auth=True)
            self.ensure_repo_branch(target_dir, self.get_selected_branch())
            print(f"Umgebung wurde geklont: {target_dir}")
            print(f"Aktiver Branch in der geklonten Umgebung: {self.get_current_branch_name(target_dir) or 'unbekannt'}")
        except Exception as exc:
            print("Klonen fehlgeschlagen.")
            print(str(exc))

        self.pause()

    def show_environment_management_menu(self) -> None:
        while True:
            self.print_header()
            print("Umgebungen verwalten")
            print()
            print("1) Neue Umgebung erstellen")
            print("2) Bestehende Umgebung loeschen")
            print("3) Bestehende Umgebungen anzeigen")
            print("4) Umgebung aus GitLab klonen")
            print("0) Zurueck")
            print()

            choice = input("Auswahl: ").strip()
            if choice == "1":
                self.create_environment()
            elif choice == "2":
                self.delete_environment()
            elif choice == "3":
                self.show_environments()
            elif choice == "4":
                self.clone_environment_from_gitlab()
            elif choice == "0":
                return
            else:
                print("Ungueltige Auswahl.")
                self.pause()

    def show_menu(self) -> None:
        while True:
            self.print_header()
            root_repo_output = f'Master/Develop Branches basieren auf Root-Repo: {self.config["ROOT_DIR"]}'
            if sys.stdout.isatty():
                root_repo_output = f"\033[1;33m{root_repo_output}\033[0m"
            print(root_repo_output)
            print("1) Aktive Umgebung auswaehlen")
            print("2) Terraform")
            print("3) GitLab")
            print("4) Umgebungen verwalten")
            print("0) Beenden")
            print()
            
            choice = input("Auswahl: ").strip()
            if choice == "1":
                self.select_active_environment()
            elif choice == "2":
                self.show_terraform_menu()
            elif choice == "3":
                self.show_gitlab_menu()
            elif choice == "4":
                self.show_environment_management_menu()
            elif choice == "0":
                print("Skript beendet.")
                return
            else:
                print("Ungueltige Auswahl.")
                self.pause()

    @staticmethod
    def _now_stamp() -> str:
        from datetime import datetime

        return datetime.now().strftime("%Y%m%d-%H%M%S")

def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Terraform Umgebungsverwaltung")
    parser.add_argument(
        "-v",
        "--version",
        action="version",
        version=f"%(prog)s {SCRIPT_VERSION} (Build {SCRIPT_BUILD})",
    )
    parser.add_argument(
        "-c",
        "--config",
        type=Path,
        help="Alternative Konfigurationsdatei verwenden",
    )
    return parser.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> int:
    args = parse_args(argv)
    manager = TerraformManager(args.config)
    manager.load_config()
    manager.show_menu()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
