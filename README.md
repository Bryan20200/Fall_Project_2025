<<<<<<< HEAD
# VulnWrap – Automated Vulnerability Scanner Wrapper

## Overview
VulnWrap automates multiple common security tools into a single streamlined Bash workflow.  
It scans, analyzes, and visualizes system vulnerabilities for quicker assessment.

## Features
- 🔍 **Information Discovery:** Nmap service & OS detection  
- 🌐 **Web Scanning:** Nikto & Gobuster for HTTP endpoints  
- 🔒 **SSL Analysis:** SSLScan for certificate and cipher checks  
- 🧩 **File Scanning:** ClamAV integrity & malware checks  
- 📊 **Data Analysis:** JQ-based risk scoring system  
- 📈 **Report Visualization:** Auto-generated HTML report with charts

## Usage
```bash
./bin/vulnwrap.sh -t ip
# VulnWrap - Vulnerability Scanner Wrapper

Run in WSL/Ubuntu (recommended). Creates reports from nmap/nikto/gobuster/sslscan and scores findings.

Quick usage (in WSL):
1. chmod +x bin/vulnwrap.sh setup.sh lib/scanner_utils.sh
2. ./setup.sh   # installs tools (requires sudo)
3. make run TARGET=<IP>
=======
# Fall_Project_2025
>>>>>>> 9bfa8b0ef2b1ecc8c08a8bb715155302c23cb36a
