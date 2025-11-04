#!/bin/bash

# Handler for SMTPS port (465).  We provide a plain text SMTP greeting
# rather than a TLS handshake for simplicity.
set -euo pipefail

app_home="${APP_HOME:-$(dirname $(dirname $(realpath "$0")))}"
logs_dir="${LOGS_DIR:-$app_home/logs}"
port="${PORT:-465}"

ts="$(date +"%Y-%m-%d_%H-%M-%S")"
log_file="${logs_dir}/${ts}_Port_${port}.log"
remote_ip="${NCAT_REMOTE_ADDR:-unknown}"
remote_port="${NCAT_REMOTE_PORT:-unknown}"
mac=$(arp -an "$remote_ip" | awk '{print $4}')
[ -z "$mac" ] && mac="unknown"

{
  echo "Datetime: $(date)"
  echo "Port: $port"
  echo "Remote IP: $remote_ip"
  echo "Remote Port: $remote_port"
  echo "MAC: $mac"
} >> "$log_file"

# Send SMTP greeting
handshake=$'220 mail.example.com ESMTP Postfix (Ubuntu)\r\n'
printf "%b" "$handshake"

# Log any client interaction
while IFS= read -r -t 2 line; do
  echo "Received: $line" >> "$log_file"
done

exit 0