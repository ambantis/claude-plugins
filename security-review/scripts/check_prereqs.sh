#!/usr/bin/env bash
# check_prereqs.sh — Verify the prerequisite for trivy-scan skill:
#   1. Trivy binary installed
#
# Exit codes:
#   0 = all hard requirements met (scan can proceed)
#   1 = one or more hard requirements missing

set -euo pipefail

PASS="✅"
FAIL="❌"
hard_fail=false

echo "╔══════════════════════════════════════════════════════╗"
echo "║       Trivy Security Scan — Prerequisite Check       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── Check 1: Trivy binary ─────────────────────────────────────────────────────
echo "[ 1/1 ] Checking Trivy installation..."

if command -v trivy &>/dev/null; then
  TRIVY_VERSION=$(trivy --version 2>/dev/null | head -1)
  echo "  ${PASS} Trivy is installed: ${TRIVY_VERSION}"
else
  echo "  ${FAIL} Trivy is NOT installed."
  echo ""
  echo "  Install it for your OS:"
  echo "    macOS:      brew install trivy"
  echo "    Arch Linux: sudo pacman -S trivy"
  echo "    Any Linux:  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin"
  echo ""
  echo "  Then re-run this script."
  hard_fail=true
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════════"
if [ "${hard_fail}" = false ]; then
  echo "  ${PASS} All checks passed. Ready to scan."
  echo ""
  echo "  Try: trivy fs --severity HIGH,CRITICAL /path/to/target"
  exit 0
else
  echo "  ${FAIL} One or more checks failed. See instructions above."
  exit 1
fi
