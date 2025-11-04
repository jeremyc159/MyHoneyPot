# MyHoneyPot — README

## Overview
A lightweight Bash honeypot for Ubuntu that launches simulated listeners on a curated set of common service ports. Each listener provides minimal, credible protocol banners (useful for `nmap -sS -sV` scans), logs every connection and payload, and temporarily manages firewall rules while running.

**Structure**
```
listener_app/
├─ run.sh           # main launcher (requires sudo for binding low ports & iptables)
├─ install.sh       # installs dependencies (for setup)
├─ ports/           # individual per-port handler scripts (port_20.sh, port_21.sh, ...)
└─ logs/            # runtime logs (created by run.sh)
```

## Supported ports
20,21,22,23,25,53,80,110,135,139,143,443,465,554,587,993,995,1433,1521,1723,1883,2049,2375,2376,3306,3389,4444,5432,5900,5985,5986,6379,8080,8443,9000,9200,9300,9418,10000,27017

Each port has a dedicated handler in `ports/` which:
- returns a minimal protocol-appropriate banner or handshake
- logs connection metadata and any data received
- creates one log file per TCP connection

## Installation
> Run these steps on an Ubuntu system. `install.sh` tries to install utilities via `apt`.

```bash
# unzip the package (if zipped)
unzip listener_app.zip
cd listener_app

# inspect install.sh before running
less install.sh

# install dependencies (requires sudo)
sudo bash install.sh
```

**Dependencies** (installed by `install.sh`):
- `ncat` / `netcat` (for runtime listener dispatch)
- `iptables` (for firewall manipulation)
- `tcpdump` (optional, for MAC discovery)
- `arp` / `iproute2`
- `zip` / `unzip` (optional)

## Usage
Run `run.sh` with sudo and a comma-separated list of ports to activate. Example:

```bash
# show help and supported ports
bash run.sh -h

# run listeners on SSH and HTTP
sudo bash run.sh 22,80
```

Behavior:
- The script ensures `logs/` exists.
- It checks requested ports against the supported list.
- For each port:
    - If the port is blocked by firewall, `iptables` ACCEPT rule is inserted (tracked).
    - A background `ncat` listener is started that hands off the connection to the appropriate `ports/port_XXX.sh` handler.
    - Each connection results in a log file `logs/YYYY-MM-DD_HH-MM-SS_Port_XXX.log` containing:
        - timestamp, client IP and port
        - attempt to resolve MAC via ARP (if available)
        - the full raw payload received (up to handler limits)
- On exit (Ctrl+C or termination), the script:
    - stops all background listeners
    - removes any `iptables` rules it added

## Logs
Log files are created under `logs/` with the filename format:
```
YYYY-MM-DD_HH-MM-SS_Port_XXX.log
```

Each log file contains:
- connection metadata (timestamp, source IP, ephemeral port)
- detected MAC (if retrievable)
- the handler banner sent (if any)
- raw data the client sent (text or hex, handler-dependent)

**Note**: handlers rotate large payloads into files and may truncate extremely large binary streams to avoid disk exhaustion.

## Port handler behavior
Each `ports/port_*.sh` script implements a conservative, minimal response tailored to its protocol (for example, SMTP handlers send an initial `220` greeting; HTTP handlers respond with a small HTTP status, MQTT sends a minimal CONNACK, etc.). Handlers intentionally avoid full protocol implementations — their goal is to be identifiable/credible during service/version scans, and to log interaction for analysis.

## Firewall handling & safety
- `run.sh` uses `iptables` to add temporary `ACCEPT` rules for ports it needs. Changes are recorded and **reverted** on exit.
- Running `run.sh` requires root privileges to modify firewall rules and to bind low ports (<1024).
- Inspect `install.sh` and `run.sh` before executing on production systems.

## Security & privacy
- This tool is a honeypot/testing utility — do NOT run it on production systems connected to the public internet without proper safeguards.
- Logs may contain sensitive client payloads. Secure your `logs/` directory and rotate/remove logs as needed.
- Use within legal and ethical boundaries only.

## Customization
- Add or edit `ports/port_XXX.sh` to change banners, logging behavior, or payload handling.
- Modify `run.sh` to change the network interface binding or to add whitelisting/blacklisting logic.

## Troubleshooting
- If a listener fails to start, ensure ports are not already bound and you have root privileges.
- If MAC addresses are not discovered, ensure `arp` is available and that the environment allows ARP lookups (local network).
- If `iptables` is not desired, modify `run.sh` to use `ufw` or skip firewall changes (advanced users).

## License
Provided as-is for testing and research. No warranty. Use responsibly.

## Contact / Contributions
Report issues or suggest improvements by editing scripts and submitting patches. Keep changes minimal and document behavior in the script headers.
