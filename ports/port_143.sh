#!/bin/bash

# Handler for IMAP port (143)
set -euo pipefail

app_home="${APP_HOME:-$(dirname $(dirname $(realpath "$0")))}"
logs_dir="${LOGS_DIR:-$app_home/logs}"
port="${PORT:-143}"

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

# IMAP greeting
handshake=$'* OK [CAPABILITY IMAP4rev1 LITERAL+] IMAP4 server ready\r\n'
printf "%b" "$handshake"

# Log any IMAP commands
while IFS= read -r -t 2 line; do
  echo "Received: $line" >> "$log_file"
  # Respond minimally to LOGIN or CAPABILITY commands
  if [[ "$line" =~ LOGIN ]]; then
    printf "A OK LOGIN completed\r\n"
  elif [[ "$line" =~ CAPABILITY ]]; then
    printf "* CAPABILITY IMAP4rev1 STARTTLS AUTH=PLAIN\r\nA OK CAPABILITY completed\r\n"
  fi
done

exit 0