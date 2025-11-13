#!/usr/bin/env bash
# setup.sh - install recommended dependencies (Debian/Ubuntu)
set -euo pipefail

echo "[*] Updating package lists..."
sudo apt update || true

echo "[*] Installing recommended packages..."
sudo apt install -y nmap jq nikto gobuster sslscan clamav dos2unix make || true

echo "[*] Done. Install may require sudo privileges. To run the wrapper use WSL/WSL-remote in VS Code."
