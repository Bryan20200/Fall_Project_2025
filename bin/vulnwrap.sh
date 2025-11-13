#!/usr/bin/env bash
# bin/vulnwrap.sh - real wrapper: run scans, parse, score, report, serve & open
set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd -P)"
LIB="$ROOT_DIR/lib/scanner_utils.sh"
TEMPLATE="$ROOT_DIR/templates/report_template.html"
CONF="$ROOT_DIR/config/scoring.conf"

TARGET=""
OUTDIR=""
SKIP_HEAVY=0

usage(){ echo "Usage: $0 -t <target> [-o outdir] [-s (skip heavy web scans)]"; exit 1; }

while getopts ":t:o:s" opt; do
  case $opt in
    t) TARGET="$OPTARG" ;;
    o) OUTDIR="$OPTARG" ;;
    s) SKIP_HEAVY=1 ;;
    *) usage ;;
  esac
done

if [[ -z "$TARGET" ]]; then usage; fi

# create scan folder if not provided
SCAN_FOLDER="scan_$(date +%Y%m%d_%H%M%S)"
OUTDIR="${OUTDIR:-$ROOT_DIR/reports/$SCAN_FOLDER}"
mkdir -p "$OUTDIR"

# source helpers
if [[ -f "$LIB" ]]; then
  # shellcheck source=/dev/null
  source "$LIB"
else
  echo "[!] Missing $LIB. Create lib/scanner_utils.sh and re-run."
  exit 2
fi

log "Starting VulnWrap real scan on $TARGET -> $OUTDIR"

# Stage 1: discovery (real nmap)
run_nmap "$TARGET" "$OUTDIR"

# Stage 2: web/ssl/file (skip heavy if requested)
run_ssl_check "$TARGET" "$OUTDIR"
run_web_scans "$TARGET" "$OUTDIR" "$SKIP_HEAVY"
run_file_scan "$OUTDIR"

# Stage 3: parse & score (produces findings.json)
parse_nmap "$OUTDIR"
score_findings "$OUTDIR" "$CONF"

# Stage 4: build report (copies template -> report.html and points to findings.json)
build_html_report "$OUTDIR" "$TEMPLATE"

log "Scan complete. Report: $OUTDIR/report.html"

# Serve the report and open in Windows browser (WSL)
# start tiny HTTP server in background bound to localhost
(
  cd "$OUTDIR"
  # serve on port 8000; background it and redirect output
  python3 -m http.server 8000 >/dev/null 2>&1 &
  sleep 0.8
)

# Try to open in Windows default browser (powershell). If unavailable, print URL.
if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -NoProfile -Command Start-Process "http://localhost:8000/report.html"
  log "Report served at http://localhost:8000/report.html (opening Windows browser)..."
else
  log "Report served at http://localhost:8000/report.html. Open in your browser."
fi

exit 0
