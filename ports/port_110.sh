#!/bin/bash

# Handler for POP3 port (110)
set -euo pipefail

app_home="${APP_HOME:-$(dirname $(dirname $(realpath "$0")))}"
logs_dir="${LOGS_DIR:-$app_home/logs}"
port="${PORT:-110}"

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

# POP3 greeting
handshake=$'+OK POP3 server ready\r\n'
printf "%b" "$handshake"

# Log client commands
while IFS= read -r -t 2 line; do
  echo "Received: $line" >> "$log_file"
  # Provide simple POP3 responses
  if [[ "$line" =~ ^QUIT ]]; then
    printf "+OK Bye\r\n"
    break
  else
    printf "+OK\r\n"
  fi
done

exit 0