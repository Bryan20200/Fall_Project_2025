SHELL := /bin/bash
.PHONY: install run lint clean

TARGET ?= 127.0.0.1
SKIP ?= 0
OUTDIR := reports/scan_$$(date +%Y%m%d_%H%M%S)

install:
	@chmod +x bin/vulnwrap.sh setup.sh lib/scanner_utils.sh || true
	@echo "[*] Run ./setup.sh in WSL to install dependencies (requires sudo)."

run:
	@mkdir -p reports
	@if [ "$(SKIP)" = "1" ]; then ./bin/vulnwrap.sh -t $(TARGET) -s -o $(OUTDIR); else ./bin/vulnwrap.sh -t $(TARGET) -o $(OUTDIR); fi

lint:
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck bin/vulnwrap.sh lib/scanner_utils.sh || true; else echo "shellcheck not installed; skipping."; fi

clean:
	@echo "[*] Cleaning old report dirs (keeps last 5)."
	@ls -1dt reports/* 2>/dev/null | tail -n +6 | xargs -r rm -rf || true
