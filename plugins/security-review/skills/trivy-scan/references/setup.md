# Trivy Setup Guide

## How the MCP server works

`trivy mcp` uses **stdio transport** by default. Claude Desktop / Claude Code
does **not** require manually starting the server in a terminal. The client
launches `trivy mcp` as a subprocess automatically on demand, based on the
entry in the config file. There is no daemon to start or keep running.

The three prerequisites are:

1. **Trivy binary** — must be installed on the system
2. **trivy-mcp plugin** — must be installed via `trivy plugin install mcp`
3. **Client config** — Claude Desktop or Claude Code must have `trivy mcp`
   registered so it knows to launch the subprocess when needed

Run `${CLAUDE_PLUGIN_ROOT}/scripts/check_prereqs.sh` to determine which are missing.

## Remediate Missing Prerequisites

### State 1 — Trivy not installed

Offer to install it. Ask which OS if not already known:

```bash
# macOS
brew install trivy

# Arch Linux
sudo pacman -S trivy

# Any Linux (official install script)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
  | sudo sh -s -- -b /usr/local/bin

# Verify
trivy --version
```

Re-run `${CLAUDE_PLUGIN_ROOT}/scripts/check_prereqs.sh` after installing.

### State 2 — trivy-mcp plugin not installed

```bash
trivy plugin install mcp

# Verify
trivy plugin list   # "mcp" should appear in the list
```

Re-run `${CLAUDE_PLUGIN_ROOT}/scripts/check_prereqs.sh` after installing.

### State 3 — MCP server not configured

This is the most common state for users who have Trivy but haven't wired up the
MCP integration. The fix is to add the server entry to the appropriate config
file and restart the client.

**For Claude Desktop:**

Add to the config file (create it if it doesn't exist):
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "trivy": {
      "command": "trivy",
      "args": ["mcp"]
    }
  }
}
```

Then **fully quit and restart** Claude Desktop (Cmd+Q on macOS, not just close
the window). The MCP subprocess will start automatically on the next tool call.

**For Claude Code:**

```bash
claude mcp add trivy --scope user -- trivy mcp
```

No restart needed — Claude Code picks up MCP config changes immediately.

Re-run `${CLAUDE_PLUGIN_ROOT}/scripts/check_prereqs.sh` after configuring to confirm.
