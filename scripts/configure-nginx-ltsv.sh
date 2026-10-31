#!/usr/bin/env bash
set -euo pipefail

# Run on a competition server using the stock Ubuntu nginx.conf:
#   sudo bash scripts/configure-nginx-ltsv.sh

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

for command_name in nginx python3 systemctl; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing command: $command_name" >&2
    exit 1
  fi
done

nginx_config="/etc/nginx/nginx.conf"
if [[ ! -f "$nginx_config" ]]; then
  echo "Missing nginx config: $nginx_config" >&2
  exit 1
fi

# Modify only the known Ubuntu nginx.conf access_log line. Keep a timestamped
# backup and roll back if nginx rejects the new configuration.
python3 - "$nginx_config" <<'PY'
from datetime import datetime
from pathlib import Path
import shutil
import subprocess
import sys

path = Path(sys.argv[1])
lines = path.read_text().splitlines(keepends=True)
original = "access_log /var/log/nginx/access.log;"
configured = "access_log /var/log/nginx/access.log ltsv;"
matches = [i for i, line in enumerate(lines) if line.strip() in (original, configured)]
has_format = any(line.lstrip().startswith("log_format ltsv ") for line in lines)

if len(matches) != 1:
    raise SystemExit("Expected exactly one nginx access_log for /var/log/nginx/access.log")

index = matches[0]
if lines[index].strip() == configured and has_format:
    print("nginx LTSV logging is already configured")
elif lines[index].strip() != original or has_format:
    raise SystemExit("nginx has a partial/custom LTSV configuration; inspect it manually")
else:
    indent = lines[index][: len(lines[index]) - len(lines[index].lstrip())]
    replacement = r"""log_format ltsv 'time:$time_iso8601'
                '\tmethod:$request_method'
                '\turi:$request_uri'
                '\tstatus:$status'
                '\tsize:$body_bytes_sent'
                '\treqtime:$request_time'
                '\tapptime:$upstream_response_time';

access_log /var/log/nginx/access.log ltsv;
"""
    backup = path.with_name(
        path.name + ".backup-" + datetime.now().strftime("%Y%m%d%H%M%S%f")
    )
    shutil.copy2(path, backup)
    lines[index] = "".join(
        indent + line if line.strip() else line
        for line in replacement.splitlines(keepends=True)
    )
    path.write_text("".join(lines))
    try:
        subprocess.run(["nginx", "-t"], check=True)
    except subprocess.CalledProcessError:
        shutil.copy2(backup, path)
        raise SystemExit(f"nginx -t failed; restored {backup}")
    subprocess.run(["systemctl", "reload", "nginx"], check=True)
    print(f"Configured nginx LTSV logging; backup: {backup}")
PY
