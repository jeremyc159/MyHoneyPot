#!/bin/bash

# Handler for generic service port (9000).  Returns a 404 for HTTP style requests.
set -euo pipefail

app_home="${APP_HOME:-$(dirname $(dirname $(realpath "$0")))}"
logs_dir="${LOGS_DIR:-$app_home/logs}"
port="${PORT:-9000}"

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

# Always return 404 Not Found
handshake=$'HTTP/1.1 404 Not Found\r\n\r\n'
printf "%b" "$handshake"

while IFS= read -r -t 2 line; do
  [[ -z "$line" ]] && break
  echo "Received: $line" >> "$log_file"
done

exit 0