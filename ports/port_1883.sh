#!/bin/bash

# Handler for MQTT port (1883).  Sends a simple CONNACK packet
# (0x20 0x02 0x00 0x00) to acknowledge the connection.
set -euo pipefail

app_home="${APP_HOME:-$(dirname $(dirname $(realpath "$0")))}"
logs_dir="${LOGS_DIR:-$app_home/logs}"
port="${PORT:-1883}"

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

# Send MQTT CONNACK (Connection Accepted) packet
printf '\x20\x02\x00\x00'

# Log any MQTT payload
while IFS= read -r -t 2 -n 1024 line; do
  printf 'Received: %s\n' "$line" >> "$log_file"
done

exit 0