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

## Step 1 — Check Prerequisites

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check_prereqs.sh
```

The script checks three prerequisites (Trivy binary, trivy-mcp plugin, Claude
client config) and prints actionable instructions for anything missing. Do not
proceed to scanning until the script exits with "All checks passed."

If prerequisites are missing, consult `references/setup.md` for detailed
installation and configuration instructions per OS and client.

---

## Step 2 — Determine What to Scan

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

## Step 3 — Run the Scan

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

## Step 4 — Interpret and Report Results

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
