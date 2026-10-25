#!/usr/bin/env bash
set -euo pipefail

# Run on a Linux x86_64 competition server with nginx:
#   sudo bash scripts/install-pprotein-agent.sh

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
  echo "This installer supports Linux x86_64 only." >&2
  exit 1
fi

for command_name in curl tar sha256sum install mv cp cmp date systemctl; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing command: $command_name" >&2
    exit 1
  fi
done

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
service_file="${script_dir}/../pprotein/pprotein-agent.service"
if [[ ! -f "$service_file" ]]; then
  echo "Missing systemd unit: $service_file" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -r -- "$tmp_dir"' EXIT

archive="${tmp_dir}/pprotein.tar.gz"
curl --fail --location --retry 3 --proto '=https' --tlsv1.2 \
  https://github.com/kaz/pprotein/releases/download/v1.2.4/pprotein_1.2.4_linux_amd64.tar.gz \
  -o "$archive"
printf '%s  %s\n' \
  04d57cf5177ae828121989be0be7bb49d4a8b2a7b907b9502e66a7807d325a01 \
  "$archive" | sha256sum --check --status
tar -xzf "$archive" -C "$tmp_dir" pprotein-agent
# Replace atomically so rerunning the installer works while the old agent runs.
install -m 0755 "$tmp_dir/pprotein-agent" /usr/local/bin/pprotein-agent.new
mv -f /usr/local/bin/pprotein-agent.new /usr/local/bin/pprotein-agent

installed_service="/etc/systemd/system/pprotein-agent.service"
if [[ -f "$installed_service" ]] && ! cmp -s "$service_file" "$installed_service"; then
  service_backup="${installed_service}.backup-$(date +%Y%m%d%H%M%S)"
  cp -p -- "$installed_service" "$service_backup"
  echo "Backed up existing systemd unit: $service_backup"
fi
install -m 0644 "$service_file" "$installed_service"
systemctl daemon-reload
systemctl enable pprotein-agent.service
systemctl restart pprotein-agent.service
systemctl is-active --quiet pprotein-agent.service
echo "pprotein-agent is active on port 19000"
