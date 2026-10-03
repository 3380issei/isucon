#!/usr/bin/env bash
set -euo pipefail

VERSION="v1.0.21"
INSTALL_PATH="/usr/local/bin/alp"

if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
  echo "このスクリプトは Linux x86_64 専用です" >&2
  exit 1
fi

for command_name in curl unzip sudo; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "$command_name が必要です。Ubuntuなら sudo apt-get install -y curl unzip sudo" >&2
    exit 1
  fi
done

tmp_dir="$(mktemp -d)"
trap 'rm -r -- "$tmp_dir"' EXIT

curl -fL --retry 3 \
  "https://github.com/tkuchiki/alp/releases/download/${VERSION}/alp_linux_amd64.zip" \
  -o "$tmp_dir/alp.zip"

unzip -q "$tmp_dir/alp.zip" -d "$tmp_dir"
sudo install -m 0755 "$tmp_dir/alp" "$INSTALL_PATH"

"$INSTALL_PATH" --version
