#!/bin/bash
set -euo pipefail

APP_HOME="$(dirname "$(realpath "$0")")"
PORTS_DIR="$APP_HOME/ports"
LOGS_DIR="$APP_HOME/logs"

echo "[INFO] Application directory: $APP_HOME"
echo "[INFO] Ports directory: $PORTS_DIR"
echo "[INFO] Logs directory: $LOGS_DIR"
mkdir -p "$LOGS_DIR" && echo "[INFO] Logs directory ensured."

declare -A PORT_DESCRIPTIONS=(
  [20]="FTP Data Transfer"
  [21]="FTP Control"
  [22]="SSH"
  [23]="Telnet"
  [25]="SMTP"
  [53]="DNS"
  [80]="HTTP"
  [110]="POP3"
  [135]="Microsoft RPC"
  [139]="NetBIOS Session Service"
  [143]="IMAP"
  [443]="HTTPS"
  [465]="SMTPS"
  [554]="RTSP"
  [587]="Mail Submission (SMTP)"
  [993]="IMAPS"
  [995]="POP3S"
  [1433]="Microsoft SQL Server"
  [1521]="Oracle DB"
  [1723]="PPTP"
  [1883]="MQTT"
  [2049]="NFS"
  [2375]="Docker REST API (plain)"
  [2376]="Docker REST API (TLS)"
  [3306]="MySQL"
  [3389]="RDP"
  [4444]="Reverse Shell (Metasploit)"
  [5432]="PostgreSQL"
  [5900]="VNC"
  [5985]="WinRM (HTTP)"
  [5986]="WinRM (HTTPS)"
  [6379]="Redis"
  [8080]="HTTP Alternate"
  [8443]="HTTPS Alternate"
  [9000]="Web Service (Generic)"
  [9200]="Elasticsearch (REST)"
  [9300]="Elasticsearch Node Transport"
  [9418]="Git (Smart Protocol)"
  [10000]="Webmin/Backup Agents"
  [27017]="MongoDB"
)

ADDED_RULES=()
LISTENER_PIDS=()

usage() {
  cat <<EOF
Usage: $0 [-h] <port1,port2,...>
EOF
}

show_ports() {
  printf "Supported ports:\n"
  for port in "${!PORT_DESCRIPTIONS[@]}"; do
    printf "  %5s : %s\n" "$port" "${PORT_DESCRIPTIONS[$port]}"
  done | sort -n
}

allow_port() {
  local port="$1"
  echo "[INFO] Checking firewall for port $port..."
  if iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null; then
    echo "[DEBUG] Firewall already allows port $port."
    return
  fi
  echo "[ACTION] Allowing TCP port $port through firewall."
  iptables -I INPUT -p tcp --dport "$port" -j ACCEPT
  ADDED_RULES+=("$port")
}

revert_firewall() {
  echo "[CLEANUP] Reverting firewall rules..."
  for port in "${ADDED_RULES[@]}"; do
    echo "[CLEANUP] Removing firewall rule for port $port..."
    while iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null; do
      iptables -D INPUT -p tcp --dport "$port" -j ACCEPT || break
    done
  done
  ADDED_RULES=()
}

cleanup_listeners() {
  echo "[CLEANUP] Terminating background listeners..."
  for pid in "${LISTENER_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      echo "[DEBUG] Killing listener PID $pid..."
      kill "$pid" || true
    fi
  done
  LISTENER_PIDS=()
}

on_exit() {
  echo "[EXIT] Stopping listeners and restoring firewall rules..."
  cleanup_listeners
  revert_firewall
  echo "[EXIT] Cleanup complete."
}

trap on_exit INT TERM EXIT

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

INPUT_PORTS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      show_ports
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "[ERROR] Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      INPUT_PORTS="$1"
      shift
      ;;
  esac
done

if [[ -z "$INPUT_PORTS" ]]; then
  echo "[ERROR] No ports specified."
  usage
  exit 1
fi

IFS=',' read -r -a REQUESTED_PORTS <<< "$INPUT_PORTS"
echo "[INFO] Requested ports: ${REQUESTED_PORTS[*]}"

for port in "${REQUESTED_PORTS[@]}"; do
  port="$(echo "$port" | xargs)"
  echo "[DEBUG] Processing port: $port"
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "[WARN] Skipping invalid port: $port"
    continue
  fi
  if [[ -z "${PORT_DESCRIPTIONS[$port]+x}" ]]; then
    echo "[WARN] Skipping unsupported port: $port"
    continue
  fi
  allow_port "$port"
  echo "[ACTION] Launching listener on port $port (${PORT_DESCRIPTIONS[$port]})..."
  env APP_HOME="$APP_HOME" LOGS_DIR="$LOGS_DIR" PORT="$port" \
    ncat --keep-open --listen "$port" --exec "$PORTS_DIR/port_${port}.sh" &
  pid=$!
  LISTENER_PIDS+=("$pid")
  echo "[INFO] Listener started on port $port (PID: $pid)"
done

if [[ ${#LISTENER_PIDS[@]} -eq 0 ]]; then
  echo "[ERROR] No valid ports were started. Exiting."
  exit 1
fi

echo "[READY] All listeners active. Press Ctrl+C to stop."
wait
