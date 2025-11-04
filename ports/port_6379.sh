#!/bin/bash

# Handler for Redis port (6379)
set -euo pipefail

app_home="${APP_HOME:-$(dirname $(dirname $(realpath "$0")))}"
logs_dir="${LOGS_DIR:-$app_home/logs}"
port="${PORT:-6379}"

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

# Send Redis PONG on connect
handshake=$'+PONG\r\n'
printf "%b" "$handshake"

# Log and respond to PING with PONG
while IFS= read -r -t 2 line; do
  echo "Received: $line" >> "$log_file"
  if [[ "$line" =~ ^PING ]]; then
    printf "+PONG\r\n"
  fi
done

exit 0