#!/bin/bash

# Handler for Webmin/Backup port (10000)
set -euo pipefail

app_home="${APP_HOME:-$(dirname $(dirname $(realpath "$0")))}"
logs_dir="${LOGS_DIR:-$app_home/logs}"
port="${PORT:-10000}"

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

# Webmin style HTTP response
handshake=$'HTTP/1.1 200 OK\r\nServer: MiniServ/1.890\r\n\r\n'
printf "%b" "$handshake"

while IFS= read -r -t 2 line; do
  [[ -z "$line" ]] && break
  echo "Received: $line" >> "$log_file"
done

exit 0