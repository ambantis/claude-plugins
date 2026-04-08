#!/usr/bin/env bash
# check_prereqs.sh — Verify all three prerequisites for trivy-scan skill:
#   1. Trivy binary installed
#   2. trivy-mcp plugin installed
#   3. Claude client configured to launch trivy mcp as a subprocess
#
# Exit codes:
#   0 = all hard requirements met (scan can proceed)
#   1 = one or more hard requirements missing

set -euo pipefail

PASS="✅"
FAIL="❌"
WARN="⚠️ "
hard_fail=false

echo "╔══════════════════════════════════════════════════════╗"
echo "║       Trivy Security Scan — Prerequisite Check       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── Check 1: Trivy binary ─────────────────────────────────────────────────────
echo "[ 1/3 ] Checking Trivy installation..."

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

# ── Check 2: trivy-mcp plugin ─────────────────────────────────────────────────
echo "[ 2/3 ] Checking trivy-mcp plugin..."

if ! command -v trivy &>/dev/null; then
  echo "  ${WARN} Skipping — Trivy not installed (fix Check 1 first)."
elif trivy plugin list 2>/dev/null | grep -q "^mcp"; then
  echo "  ${PASS} trivy-mcp plugin is installed."
else
  echo "  ${FAIL} trivy-mcp plugin is NOT installed."
  echo ""
  echo "  Install it with:"
  echo "    trivy plugin install mcp"
  echo ""
  echo "  Verify with:"
  echo "    trivy plugin list"
  echo ""
  echo "  Then re-run this script."
  hard_fail=true
fi

echo ""

# ── Check 3: Claude client config ─────────────────────────────────────────────
# The trivy-mcp server uses stdio transport — Claude Desktop / Claude Code
# launches it as a subprocess automatically. There is no daemon to start.
# We check that the config entry exists so Claude knows to launch it.
echo "[ 3/3 ] Checking Claude client configuration..."

MCP_CONFIGURED=false
CONFIG_FOUND_AT=""

# Claude Code: ~/.claude.json
CLAUDE_CODE_CONFIG="${HOME}/.claude.json"
if [ -f "${CLAUDE_CODE_CONFIG}" ] && grep -q '"trivy"' "${CLAUDE_CODE_CONFIG}" 2>/dev/null; then
  MCP_CONFIGURED=true
  CONFIG_FOUND_AT="Claude Code (~/.claude.json)"
fi

# Claude Desktop: macOS
CLAUDE_DESKTOP_MAC="${HOME}/Library/Application Support/Claude/claude_desktop_config.json"
if [ -f "${CLAUDE_DESKTOP_MAC}" ] && grep -q '"trivy"' "${CLAUDE_DESKTOP_MAC}" 2>/dev/null; then
  MCP_CONFIGURED=true
  CONFIG_FOUND_AT="Claude Desktop macOS (${CLAUDE_DESKTOP_MAC})"
fi

# Claude Desktop: Linux
CLAUDE_DESKTOP_LINUX="${HOME}/.config/Claude/claude_desktop_config.json"
if [ -f "${CLAUDE_DESKTOP_LINUX}" ] && grep -q '"trivy"' "${CLAUDE_DESKTOP_LINUX}" 2>/dev/null; then
  MCP_CONFIGURED=true
  CONFIG_FOUND_AT="Claude Desktop Linux (${CLAUDE_DESKTOP_LINUX})"
fi

# Claude Desktop: Windows (via WSL or Git Bash)
if [ -n "${APPDATA:-}" ]; then
  CLAUDE_DESKTOP_WIN="${APPDATA}/Claude/claude_desktop_config.json"
  if [ -f "${CLAUDE_DESKTOP_WIN}" ] && grep -q '"trivy"' "${CLAUDE_DESKTOP_WIN}" 2>/dev/null; then
    MCP_CONFIGURED=true
    CONFIG_FOUND_AT="Claude Desktop Windows (${CLAUDE_DESKTOP_WIN})"
  fi
fi

if [ "${MCP_CONFIGURED}" = true ]; then
  echo "  ${PASS} trivy MCP server configured in: ${CONFIG_FOUND_AT}"
  echo "       Claude will launch 'trivy mcp' automatically as a subprocess."
  echo "       No manual server start is required."
else
  echo "  ${FAIL} trivy MCP server is NOT configured in any Claude client."
  echo ""
  echo "  Without this, Claude cannot invoke Trivy via MCP."
  echo "  The CLI fallback (trivy fs ...) still works, but you won't get"
  echo "  natural-language scanning in the chat."
  echo ""
  echo "  HOW TO FIX:"
  echo ""
  echo "  Option A — Claude Code (recommended, takes effect immediately):"
  echo "    claude mcp add trivy --scope user -- trivy mcp"
  echo ""
  echo "  Option B — Claude Desktop:"
  echo "    Edit the config file for your OS:"
  echo "      macOS:   ~/Library/Application Support/Claude/claude_desktop_config.json"
  echo "      Linux:   ~/.config/Claude/claude_desktop_config.json"
  echo "      Windows: %APPDATA%\\Claude\\claude_desktop_config.json"
  echo ""
  echo "    Add or merge this block:"
  echo '    {'
  echo '      "mcpServers": {'
  echo '        "trivy": {'
  echo '          "command": "trivy",'
  echo '          "args": ["mcp"]'
  echo '        }'
  echo '      }'
  echo '    }'
  echo ""
  echo "    Then FULLY QUIT and restart Claude Desktop (Cmd+Q on macOS)."
  echo "    The subprocess starts automatically — no manual 'trivy mcp' needed."
  echo ""
  echo "  After configuring, re-run this script to confirm."
  hard_fail=true
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════════"
if [ "${hard_fail}" = false ]; then
  echo "  ${PASS} All checks passed. Ready to scan."
  echo ""
  echo "  Try: trivy fs --severity HIGH,CRITICAL /path/to/target"
  echo "  Or ask Claude: 'Scan /path/to/plugin for vulnerabilities'"
  exit 0
else
  echo "  ${FAIL} One or more checks failed. See instructions above."
  exit 1
fi
