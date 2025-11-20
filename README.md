# Vulnerability Scanner Bash Wrapper (VulnWrap)

> **Video Presentation:**  
> *(Add your video link here at the top once it’s ready.)*

## Project Purpose

VulnWrap is a Bash-based vulnerability scanning wrapper that automates running multiple security tools and combines their results into a single, easy-to-read report. Instead of manually running each scanner, saving outputs, and trying to interpret them one by one, this project provides a single command that:

- Performs network discovery and port scanning  
- Runs optional web and file/malware checks (if the tools are installed)  
- Parses and scores the findings  
- Generates an HTML report with a simple visualization of risk scores  

The goal is not to replace full enterprise scanners, but to provide a lightweight, scriptable tool that is useful for students, labs, and small environments.

---

## Dependencies & Required Tools

This project is designed to run in a Linux environment (for example, WSL on Windows).

### Core requirements

- **Bash**
- **make**
- **nmap** – network/port scanning
- **jq** – JSON processing
- **python3** – used to serve the HTML report locally (optional but recommended)

### Optional / recommended tools

These are used if installed, but the script will still run if they are missing:

- **nikto** – web server vulnerability scanner  
- **gobuster** – directory brute-forcing tool for web paths  
- **sslscan** – SSL/TLS scan (certificate/protocol information)  
- **clamscan** (ClamAV) – example file/malware scanner  

If any of these optional tools are not installed, VulnWrap will log a message and skip those steps instead of failing.

---

## Project Structure

The key files and directories are:

- `bin/vulnwrap.sh` – main Bash wrapper script (entry point)
- `lib/scanner_utils.sh` – helper functions for running tools and processing results
- `config/scoring.conf` – mapping of services to numeric risk scores
- `wordlists/small-dirlist.txt` – wordlist for Gobuster directory brute forcing
- `templates/report_template.html` – base HTML template used for the report
- `reports/` – output directory where scan results and reports are stored
- `Makefile` – provides shortcuts like `make run` to execute the scanner
- `README.md` – project documentation (this file)

Each scan creates a timestamped folder under `reports/` containing Nmap output, optional scanner results, JSON files, and the HTML report.

---

## Setup Instructions

These steps assume you are in a Linux shell (such as WSL) and inside your project directory.

1. **Install required packages**

   On Debian/Ubuntu-based systems (including many WSL setups):

   ```bash
   sudo apt update
   sudo apt install -y nmap jq python3

2. **Make scripts executable**

From the project root directory, run:

chmod +x bin/vulnwrap.sh
chmod +x lib/scanner_utils.sh
chmod +x setup.sh  # if this file exists in your project


3. **Verify project layout**

Your project directory should look similar to:

bin/
  vulnwrap.sh
lib/
  scanner_utils.sh
config/
  scoring.conf
templates/
  report_template.html
wordlists/
  small-dirlist.txt
reports/
Makefile
README.md


4. **Test a basic scan**

From the project root, run:

make run TARGET= IP


This will create a timestamped folder under reports/ containing Nmap output, JSON files, and an HTML report (for example: reports/scan_YYYYMMDD_HHMMSS/).

5. **View the HTML report**

Change into the scan folder and start a simple web server:

cd reports/scan_YYYYMMDD_HHMMSS
python3 -m http.server 8000


Then open a browser on your host machine and go to:

http://localhost:8000/report.html