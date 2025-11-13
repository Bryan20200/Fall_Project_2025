#!/usr/bin/env bash
# lib/scanner_utils.sh - real scanner utilities
set -euo pipefail
IFS=$'\n\t'

log(){ echo "[*] $*"; }
which_ok(){ command -v "$1" >/dev/null 2>&1; }

# ----------------- Discovery (nmap) -----------------
run_nmap(){
  local target="$1"; local outdir="${2:-./reports}"
  log "nmap: scanning $target -> $outdir"
  if ! which_ok nmap; then log "nmap not installed; skipping nmap"; return; fi
  mkdir -p "$outdir"
  # All-ports service/version scan; adjust flags if you want lighter scan
  nmap -sV -Pn -p- --min-rate 1000 -oX "$outdir/nmap.xml" -oG "$outdir/nmap.gnmap" "$target" || true
}

# ----------------- Web & directory scanning -----------------
run_web_scans(){
  local target="$1" outdir="$2" skip="${3:-0}"
  if [[ "$skip" -eq 1 ]]; then log "Skipping heavy web scans"; return; fi

  if which_ok nikto; then
    log "nikto: scanning http://$target"
    nikto -host "http://$target" -o "$outdir/nikto.txt" -Format txt || true
  else
    log "nikto not installed; skipping"
  fi

  if which_ok gobuster; then
    local wl="$(dirname "${BASH_SOURCE[0]}")/../wordlists/small-dirlist.txt"
    if [[ -f "$wl" ]]; then
      log "gobuster: dir brute on http://$target using $wl"
      gobuster dir -u "http://$target/" -w "$wl" -o "$outdir/gobuster.txt" -q || true
    else
      log "gobuster wordlist missing: $wl"
    fi
  else
    log "gobuster not installed; skipping"
  fi
}

# ----------------- SSL/TLS checks -----------------
run_ssl_check(){
  local target="$1" outdir="$2"
  if which_ok sslscan; then
    log "sslscan: $target"
    sslscan "$target" > "$outdir/sslscan.txt" 2>&1 || true
  else
    log "sslscan not installed; skipping"
  fi
}

# ----------------- File scan (optional example) -----------------
run_file_scan(){
  local outdir="$1"
  if which_ok clamscan; then
    log "clamscan: scanning /tmp (example)"
    clamscan -r --bell -i /tmp > "$outdir/clamscan.txt" 2>&1 || true
  else
    log "clamscan not installed; skipping file scan"
  fi
}

# ----------------- Parse nmap greppable to JSON -----------------
parse_nmap(){
  local outdir="$1"
  local gnmap="$outdir/nmap.gnmap"
  local parsed="$outdir/parsed_ports.json"
  echo "[]" > "$parsed"
  if ! which_ok jq; then log "jq not found; skipping parse_nmap"; return; fi
  if [[ ! -f "$gnmap" ]]; then log "nmap greppable ($gnmap) not found; skipping parse"; return; fi

  grep "Ports:" "$gnmap" | while read -r line; do
    if [[ $line =~ Ports:\ (.*) ]]; then
      IFS=',' read -ra ports <<< "${BASH_REMATCH[1]}"
      for p in "${ports[@]}"; do
        IFS='/' read -ra parts <<< "$p"
        port="$(echo "${parts[0]}" | xargs)"
        state="$(echo "${parts[1]}" | xargs)"
        proto="$(echo "${parts[2]}" | xargs)"
        svc="$(echo "${parts[4]:-unknown}" | xargs)"
        jq --arg p "$port" --arg s "$svc" --arg st "$state" --arg pr "$proto" \
           '. += [{"port":$p,"service":$s,"state":$st,"proto":$pr}]' "$parsed" > "$parsed.tmp" && mv "$parsed.tmp" "$parsed"
      done
    fi
  done
  log "Parsed nmap -> $parsed"
}

# ----------------- Score findings -> findings.json -----------------
score_findings(){
  local outdir="$1"; local conf="${2:-./config/scoring.conf}"
  local parsed="$outdir/parsed_ports.json"
  local out="$outdir/findings.json"
  echo "[]" > "$out"

  declare -A SCOREMAP=( ["ssh"]=6 ["http"]=6 ["ftp"]=8 ["telnet"]=9 ["unknown"]=5 )

  if [[ -f "$conf" ]]; then
    while IFS='=' read -r k v; do
      [[ -z "$k" || "$k" =~ ^# ]] && continue
      SCOREMAP[$k]="$v"
    done < "$conf"
  fi

  if [[ -f "$parsed" ]] && which_ok jq; then
    jq -c '.[]' "$parsed" | while read -r item; do
      svc=$(echo "$item" | jq -r '.service')
      port=$(echo "$item" | jq -r '.port')
      score=${SCOREMAP[$svc]:-${SCOREMAP["unknown"]}}
      jq --arg svc "$svc" --arg port "$port" --argjson sc "$score" \
         '. += [{"type":"service","service":$svc,"port":$port,"score":$sc}]' "$out" > "$out.tmp" && mv "$out.tmp" "$out"
    done
    log "Scored port/service findings -> $out"
  else
    log "No parsed_ports.json or jq missing; findings.json may be empty"
  fi

  if [[ -f "$outdir/nikto.txt" ]]; then
    if grep -Eq "OSVDB|Server:|Allowed methods" "$outdir/nikto.txt"; then
      jq '. += [{"type":"web","detail":"niktoVuln","score":9}]' "$out" > "$out.tmp" && mv "$out.tmp" "$out"
      log "Added nikto-derived finding"
    fi
  fi
}

# ----------------- Build HTML report from template -----------------
build_html_report(){
  local outdir="$1"; local template="$2"
  if [[ ! -f "$template" ]]; then log "Template missing: $template"; return; fi
  cp "$template" "$outdir/report.html"
  sed -i "s|__FINDINGS_PATH__|findings.json|g" "$outdir/report.html"
  log "Report created: $outdir/report.html"
}
