#!/bin/bash

# install.sh - Install dependencies for the listener application
#
# This script checks for the presence of required third‑party tools
# used by the listener application.  If any tool is missing, it will
# perform an apt‑based installation.  Run this script on a new
# system before using run.sh to ensure all dependencies are
# satisfied.

set -euo pipefail

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Please run with sudo." >&2
  exit 1
fi

echo "Updating package lists..."
apt-get update -qq

# Check and install ncat (provided by the nmap package)
if ! command -v ncat >/dev/null 2>&1; then
  echo "Installing nmap (provides ncat)..."
  apt-get install -y -qq nmap
else
  echo "ncat already installed."
fi

# Check and install iptables
if ! command -v iptables >/dev/null 2>&1; then
  echo "Installing iptables..."
  apt-get install -y -qq iptables
else
  echo "iptables already installed."
fi

# Check and install net-tools for arp command
if ! command -v arp >/dev/null 2>&1; then
  echo "Installing net-tools (provides arp)..."
  apt-get install -y -qq net-tools
else
  echo "arp (net-tools) already installed."
fi

echo "All dependencies are installed."