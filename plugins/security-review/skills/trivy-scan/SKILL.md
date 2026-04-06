---
name: trivy-scan
description: >
  Security vulnerability scanning using Trivy and the official aquasecurity/trivy-mcp
  plugin. Use this skill whenever a user wants to evaluate the security of a package,
  plugin, directory, container image, or repository before installing or deploying it.
  Triggers include: "scan this for vulnerabilities", "is this package safe to install?",
  "check security of this plugin", "run trivy", "any CVEs in", "security audit",
  "check dependencies for vulnerabilities", "before I install this". Also trigger
  proactively when a user is about to install a new tool or plugin and security has
  been mentioned as a concern in the conversation.
---

# Trivy Security Scan Skill

Uses the official [aquasecurity/trivy-mcp](https://github.com/aquasecurity/trivy-mcp)
plugin to scan for CVEs, misconfigurations, and exposed secrets. Trivy natively
understands Python (`uv.lock`, `pyproject.toml`), Node.js (`package-lock.json`,
`yarn.lock`), containers, and remote git repositories.

---

## How the MCP server works (important context)

`trivy mcp` uses **stdio transport** by default. This means Claude Desktop / Claude
Code does **not** require you to manually start the server in a terminal. Instead,
the client launches `trivy mcp` as a subprocess automatically on demand, based on
the entry in the config file. There is no daemon to start or keep running.

The three prerequisites are therefore:

1. **Trivy binary** — must be installed on the system
2. **trivy-mcp plugin** — must be installed via `trivy plugin install mcp`
3. **Client config** — Claude Desktop or Claude Code must have `trivy mcp` registered
   so it knows to launch the subprocess when needed

Run `scripts/check_prereqs.sh` to determine which of these are missing.

---

## Step 1 — Check Prerequisites

```bash
bash scripts/check_prereqs.sh
```

The script checks all three states and prints actionable instructions for anything
missing. Do not proceed to scanning until the script exits with "All checks passed."

---

## Step 2 — Remediate Missing Prerequisites

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

Re-run `scripts/check_prereqs.sh` after installing.

### State 2 — trivy-mcp plugin not installed

```bash
trivy plugin install mcp

# Verify
trivy plugin list   # "mcp" should appear in the list
```

Re-run `scripts/check_prereqs.sh` after installing.

### State 3 — MCP server not configured (Claude won't launch it automatically)

This is the most common state for users who have Trivy but haven't wired up the MCP
integration. The fix is to add the server entry to the appropriate config file and
restart the client. Claude Desktop / Claude Code will then launch `trivy mcp` as a
subprocess automatically whenever a scan is requested — no manual server start needed.

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

Then **fully quit and restart** Claude Desktop (Cmd+Q on macOS, not just close the
window). The MCP subprocess will start automatically on the next tool call.

**For Claude Code:**

```bash
claude mcp add trivy --scope user -- trivy mcp
```

No restart needed — Claude Code picks up MCP config changes immediately.

Re-run `scripts/check_prereqs.sh` after configuring to confirm.

---

## Step 3 — Determine What to Scan

Ask the user what they want to scan if not already clear:

| Target type | Example |
|---|---|
| Local directory / project | `/path/to/my-plugin` |
| Python manifest | `pyproject.toml` or `uv.lock` in a directory |
| Node.js manifest | `package-lock.json` or `yarn.lock` in a directory |
| Container image | `nginx:latest`, `python:3.12-slim` |
| Remote git repo | `https://github.com/org/repo` |

For the presentation plugin use case, the target is the plugin's root directory,
which contains both `pyproject.toml` (Python) and `package-lock.json` (Node.js /
pptxgenjs). A single filesystem scan covers both automatically.

---

## Step 4 — Run the Scan

### Via MCP (preferred — natural language, results inline in conversation)

Once configured, use natural language in the chat:

```
Scan /path/to/plugin for security vulnerabilities
Check python:3.12-slim for CVEs
Are there any HIGH or CRITICAL vulnerabilities in /path/to/plugin?
Scan https://github.com/org/repo for security issues
```

### Via CLI fallback (always available, even without MCP configured)

```bash
# Filesystem scan — auto-detects Python + Node manifests
trivy fs --scanners vuln,secret /path/to/target

# HIGH and CRITICAL only (recommended for install-or-not decisions)
trivy fs --severity HIGH,CRITICAL --scanners vuln,secret /path/to/target

# JSON output for programmatic use
trivy fs --format json --output trivy-report.json /path/to/target

# Container image
trivy image python:3.12-slim

# Remote git repo
trivy repo https://github.com/org/repo
```

---

## Step 5 — Interpret and Report Results

After the scan completes, always present results using this structure:

**1. Overall verdict**

| Condition | Verdict |
|---|---|
| No CVEs, no secrets | ✅ SAFE TO INSTALL |
| Only LOW / MEDIUM CVEs with fixes available | ⚠️ REVIEW RECOMMENDED |
| Any HIGH or CRITICAL CVE | ⛔ DO NOT INSTALL (until resolved) |
| Exposed secrets detected | ⛔ DO NOT INSTALL |
| Any HIGH / CRITICAL CVE with no available fix | ⛔ DO NOT INSTALL — flag for risk acceptance |

**2. CVE summary** — counts by severity (CRITICAL / HIGH / MEDIUM / LOW / UNKNOWN)

**3. Critical and High findings** — for each: CVE ID, affected package, installed
version, fixed version (or "no fix available"), one-line description

**4. Recommended actions** — specific upgrade commands where a fix exists; explicit
callout for unfixable CVEs, which require a deliberate risk acceptance decision rather
than just an upgrade

Always distinguish between fixable and unfixable CVEs. An unfixable HIGH/CRITICAL
(patched version does not yet exist) is a more serious situation and must be surfaced
clearly to the user.

---

## Reference

- Trivy docs: https://trivy.dev/docs/
- trivy-mcp repo: https://github.com/aquasecurity/trivy-mcp
- Claude Desktop config: https://github.com/aquasecurity/trivy-mcp/blob/main/docs/ide/claude.md
- Supported language coverage: https://trivy.dev/docs/latest/coverage/language/
