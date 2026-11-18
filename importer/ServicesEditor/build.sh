#!/usr/bin/env bash
set -euo pipefail
editor_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
configuration="${CONFIGURATION:-Release}"
targets=("${@}")
if ((${#targets[@]} == 0)); then targets=(win-x64 linux-x64); fi
for target in "${targets[@]}"; do
    case "$target" in win-x64|win-arm64|linux-x64|linux-arm64) ;; *) echo "Nicht unterstütztes Ziel: $target" >&2; exit 2 ;; esac
    output_dir="$editor_dir/dist/$target"
    dotnet publish "$editor_dir/ServicesEditor.csproj" -c "$configuration" \
        -r "$target" --self-contained true -o "$output_dir" \
        -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true \
        -p:DebugType=None -p:DebugSymbols=false
    cp "$editor_dir/README.md" "$output_dir/README.md"
    python3 - "$output_dir" "$editor_dir/dist/services-editor-1.0.0-$target.zip" <<'PY'
import hashlib
import pathlib
import sys
import zipfile
source = pathlib.Path(sys.argv[1])
for symbols in source.rglob('*.pdb'):
    symbols.unlink()
with zipfile.ZipFile(sys.argv[2], 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(source.rglob('*')):
        if path.is_file():
            archive.write(path, path.relative_to(source))
archive_path = pathlib.Path(sys.argv[2])
checksum = hashlib.sha256(archive_path.read_bytes()).hexdigest()
archive_path.with_suffix('.zip.sha256').write_text(f'{checksum}  {archive_path.name}\n')
print(sys.argv[2])
PY
done
