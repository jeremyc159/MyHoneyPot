#!/bin/bash

# Handler for MySQL port (3306)
set -euo pipefail

app_home="${APP_HOME:-$(dirname $(dirname $(realpath "$0")))}"
logs_dir="${LOGS_DIR:-$app_home/logs}"
port="${PORT:-3306}"

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

# Simplified MySQL handshake banner (server greeting)
handshake=$'5.7.31-0ubuntu0.18.04.1\n'
printf "%b" "$handshake"

# Log any incoming handshake attempts
while IFS= read -r -t 2 -n 1024 line; do
  printf 'Received: %s\n' "$line" >> "$log_file"
done

exit 0