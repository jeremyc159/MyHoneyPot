#!/bin/bash

# Handler for generic reverse shell port (4444)
set -euo pipefail

app_home="${APP_HOME:-$(dirname $(dirname $(realpath "$0")))}"
logs_dir="${LOGS_DIR:-$app_home/logs}"
port="${PORT:-4444}"

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

# Send reverse shell greeting
handshake=$'Reverse shell ready\r\n'
printf "%b" "$handshake"

# Log and echo back data
while IFS= read -r -t 2 line; do
  echo "Received: $line" >> "$log_file"
  # echo back what was received
  printf "%s\r\n" "$line"
done

exit 0