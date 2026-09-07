#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${TERRAFORM_MANAGER_CONFIG:-${SCRIPT_DIR}/manage-terraform.conf}"

if [[ ! -r "${CONFIG_FILE}" ]]; then
  echo "Konfigurationsdatei nicht lesbar: ${CONFIG_FILE}" >&2
  exit 1
fi

# Konfiguration ohne Shell-Auswertung lesen. So werden Sonderzeichen in Werten
# nicht als Befehle interpretiert.
config_assignments="$(python3 - "${CONFIG_FILE}" <<'PY'
import re
import shlex
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
line_re = re.compile(r'^\s*([A-Z0-9_]+)\s*=\s*(?:"(.*)"|([^#\s]+))\s*(?:#.*)?$')
values = {}
for raw_line in config_path.read_text(encoding="utf-8").splitlines():
    match = line_re.match(raw_line)
    if match:
        key, quoted, plain = match.groups()
        values[key] = quoted if quoted is not None else plain

variable_re = re.compile(r'\$\{([A-Z0-9_]+)\}')
for _ in range(10):
    changed = False
    for key, value in list(values.items()):
        expanded = variable_re.sub(lambda match: values.get(match.group(1), ""), value)
        changed = changed or expanded != value
        values[key] = expanded
    if not changed:
        break

for key, value in values.items():
    print(f"{key}={shlex.quote(value)}")
PY
)"
eval "${config_assignments}"

environment_name="${1:-${ACTIVE_ENVIRONMENT:-}}"
target_branch="${2:-${TERRAFORM_TARGET_BRANCH:-develop}}"

if [[ -z "${environment_name}" ]]; then
  echo "Keine aktive Umgebung konfiguriert." >&2
  echo "Aufruf: $0 [environment-pfad] [develop|master]" >&2
  exit 1
fi
if [[ "${environment_name}" == /* || "${environment_name}" == *".."* ]]; then
  echo "Ungueltiger Environment-Pfad: ${environment_name}" >&2
  exit 1
fi
if [[ "${target_branch}" != "develop" && "${target_branch}" != "master" ]]; then
  echo "Ungueltiger Branch: ${target_branch}" >&2
  exit 1
fi

environment_root="${ENVIRONMENTS_DIR:-${SCRIPT_DIR}/environments}"
if [[ "${ENVIRONMENT_FOLDER_STRUCTURE:-master_develop}" == "single" ]]; then
  environment_dir="${environment_root}/${environment_name}"
else
  environment_dir="${environment_root}/${environment_name}/${target_branch}"
fi
if [[ ! -d "${environment_dir}" ]]; then
  echo "Environment-Verzeichnis nicht gefunden: ${environment_dir}" >&2
  exit 1
fi

provider=""
if grep -Eqs 'provider[[:space:]]+"citrixadc"|source[[:space:]]*=[[:space:]]*"citrix/citrixadc"' "${environment_dir}"/*.tf 2>/dev/null; then
  provider="netscaler"
elif grep -Eqs 'provider[[:space:]]+"alteon"|source[[:space:]]*=[[:space:]]*"Radware/alteon"' "${environment_dir}"/*.tf 2>/dev/null; then
  provider="alteon"
fi

is_true() {
  case "${1,,}" in
    1|true|yes|ja|on) return 0 ;;
    *) return 1 ;;
  esac
}

if [[ "${provider}" == "netscaler" ]] && is_true "${NETSCALER_USE_LINUXENV:-false}"; then
  read -r -p "NetScaler Username [${NETSCALER_USERNAME:-}]: " entered_username
  export TF_VAR_netscaler_username="${entered_username:-${NETSCALER_USERNAME:-}}"
  read -r -s -p "NetScaler Passwort: " TF_VAR_netscaler_password
  echo
  export TF_VAR_netscaler_password
  if [[ -z "${TF_VAR_netscaler_username}" || -z "${TF_VAR_netscaler_password}" ]]; then
    echo "NetScaler Username und Passwort duerfen nicht leer sein." >&2
    exit 1
  fi
elif [[ "${provider}" == "alteon" ]] && is_true "${ALTEON_USE_LINUXENV:-false}"; then
  read -r -p "Alteon Username [${ALTEON_USERNAME:-}]: " entered_username
  export TF_VAR_alteon_username="${entered_username:-${ALTEON_USERNAME:-}}"
  read -r -s -p "Alteon Passwort: " TF_VAR_alteon_password
  echo
  export TF_VAR_alteon_password
  if [[ -z "${TF_VAR_alteon_username}" || -z "${TF_VAR_alteon_password}" ]]; then
    echo "Alteon Username und Passwort duerfen nicht leer sein." >&2
    exit 1
  fi
fi

askpass_file=""
cleanup() {
  if [[ -n "${askpass_file}" && -f "${askpass_file}" ]]; then
    rm -f -- "${askpass_file}"
  fi
}
trap cleanup EXIT HUP INT TERM

if [[ -n "${GIT_ACCESS_TOKEN:-}" || ( -n "${GIT_USERNAME:-}" && -n "${GIT_PASSWORD:-}" ) ]]; then
  askpass_file="$(mktemp "${TMPDIR:-/tmp}/terraform-cli-askpass.XXXXXX")"
  printf '%s\n' '#!/usr/bin/env bash' \
    'case "$1" in' \
    '  *Username*) printf "%s\n" "$TERRAFORM_MANAGER_GIT_USERNAME" ;;' \
    '  *Password*) printf "%s\n" "$TERRAFORM_MANAGER_GIT_PASSWORD" ;;' \
    '  *) printf "\n" ;;' \
    'esac' >"${askpass_file}"
  chmod 700 "${askpass_file}"
  export TERRAFORM_MANAGER_GIT_USERNAME="${GIT_USERNAME:-oauth2}"
  export TERRAFORM_MANAGER_GIT_PASSWORD="${GIT_ACCESS_TOKEN:-${GIT_PASSWORD:-}}"
  export GIT_ASKPASS="${askpass_file}"
  export GIT_TERMINAL_PROMPT=0
fi

export TERRAFORM_MANAGER_ENVIRONMENT="${environment_name}"
export TERRAFORM_MANAGER_BRANCH="${target_branch}"
export TERRAFORM_MANAGER_PROVIDER="${provider}"

echo "Environment: ${environment_name}"
echo "Branch:      ${target_branch}"
echo "Provider:    ${provider:-unbekannt}"
echo "Pfad:        ${environment_dir}"
echo "Die CLI-Shell mit 'exit' verlassen."

cd "${environment_dir}"
"${SHELL:-/bin/bash}" -i
