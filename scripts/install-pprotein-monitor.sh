#!/usr/bin/env bash
set -euo pipefail

# Run on the Amazon Linux 2023 monitoring EC2 instance from this repository:
#   sudo bash scripts/install-pprotein-monitor.sh

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
  echo "This installer supports Linux x86_64 only (the Terraform t3.small instance)." >&2
  exit 1
fi

for command_name in curl tar sha256sum dnf systemctl; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing command: $command_name" >&2
    exit 1
  fi
done

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
service_file="${script_dir}/../pprotein/pprotein.service"
if [[ ! -f "$service_file" ]]; then
  echo "Missing systemd unit: $service_file" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -r -- "$tmp_dir"' EXIT

download_and_verify() {
  local name="$1" version="$2" sha256="$3" url="$4"
  local archive="${tmp_dir}/${name}.tar.gz"
  local unpack_dir="${tmp_dir}/${name}"

  curl --fail --location --retry 3 --proto '=https' --tlsv1.2 "$url" -o "$archive"
  printf '%s  %s\n' "$sha256" "$archive" | sha256sum --check --status
  mkdir -p "$unpack_dir"
  tar -xzf "$archive" -C "$unpack_dir"
  echo "Verified ${name} ${version}"
}

download_and_verify pprotein v1.2.4 \
  04d57cf5177ae828121989be0be7bb49d4a8b2a7b907b9502e66a7807d325a01 \
  https://github.com/kaz/pprotein/releases/download/v1.2.4/pprotein_1.2.4_linux_amd64.tar.gz

download_and_verify alp v1.0.22 \
  e5830a70ca064aa89b6ed4715a71591e83e0fe9c85284bbec4208b7d949cbc42 \
  https://github.com/tkuchiki/alp/releases/download/v1.0.22/alp_linux_amd64.tar.gz

download_and_verify slp v0.2.3 \
  d1721686f82d120d472f300d0223ec98c766421a93d38642100c578d7089dfd6 \
  https://github.com/tkuchiki/slp/releases/download/v0.2.3/slp_linux_amd64.tar.gz

dnf install -y graphviz
install -m 0755 "$tmp_dir/pprotein/pprotein" /usr/local/bin/pprotein
install -m 0755 "$tmp_dir/alp/alp" /usr/local/bin/alp
install -m 0755 "$tmp_dir/slp/slp" /usr/local/bin/slp
install -m 0644 "$service_file" /etc/systemd/system/pprotein.service

systemctl daemon-reload
systemctl enable pprotein.service
systemctl restart pprotein.service

for ((attempt = 1; attempt <= 10; attempt++)); do
  if curl --fail --silent --output /dev/null http://127.0.0.1:9000/; then
    echo "pprotein is ready at http://127.0.0.1:9000/"
    exit 0
  fi
  sleep 1
done

echo "pprotein did not become ready; inspect: journalctl -u pprotein -n 100 --no-pager" >&2
exit 1
