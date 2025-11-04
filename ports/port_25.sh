#!/bin/bash

# Handler for SMTP port (25)
set -euo pipefail

app_home="${APP_HOME:-$(dirname $(dirname $(realpath "$0")))}"
logs_dir="${LOGS_DIR:-$app_home/logs}"
port="${PORT:-25}"

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

# SMTP greeting
handshake=$'220 mail.example.com ESMTP Postfix (Ubuntu)\r\n'
printf "%b" "$handshake"

# Log any commands from the client
while IFS= read -r -t 2 line; do
  echo "Received: $line" >> "$log_file"
  # Provide minimal SMTP response codes
  if [[ "$line" =~ ^HELO ]]; then
    printf "250 mail.example.com Hello\r\n"
  elif [[ "$line" =~ ^EHLO ]]; then
    printf "250-mail.example.com Hello\r\n250 AUTH LOGIN PLAIN\r\n"
  elif [[ "$line" =~ ^QUIT ]]; then
    printf "221 Bye\r\n"
    break
  else
    printf "250 OK\r\n"
  fi
done

exit 0