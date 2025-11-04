#!/bin/bash

# Handler for HTTPS port (443).  To keep things simple we do not
# implement TLS.  Instead we return a generic HTTP error code.  This
# will still appear as an HTTP service under basic service scans.
set -euo pipefail

app_home="${APP_HOME:-$(dirname $(dirname $(realpath "$0")))}"
logs_dir="${LOGS_DIR:-$app_home/logs}"
port="${PORT:-443}"

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

handshake=$'HTTP/1.1 400 Bad Request\r\n\r\n'
printf "%b" "$handshake"

# Log request lines (although TLS clients will send gibberish)
while IFS= read -r -t 2 line; do
  echo "Received: $line" >> "$log_file"
done

exit 0