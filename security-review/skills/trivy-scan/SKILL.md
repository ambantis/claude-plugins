---
name: trivy-scan
description: >
  Security vulnerability scanning using Trivy CLI. Use this skill whenever a
  user wants to evaluate the security of a package, plugin, directory, container
  image, or repository before installing or deploying it. Triggers include:
  "scan this for vulnerabilities", "is this package safe to install?", "check
  security of this plugin", "run trivy", "any CVEs in", "security audit", "check
  dependencies for vulnerabilities", "before I install this". Also trigger
  proactively when a user is about to install a new tool or plugin and security
  has been mentioned as a concern in the conversation.
---

# Trivy Security Scan Skill

Uses the Trivy CLI to scan for CVEs, misconfigurations, and exposed secrets.
Trivy natively understands Python (`uv.lock`, `pyproject.toml`), Node.js
(`package-lock.json`, `yarn.lock`), containers, and remote git repositories.

---

## Step 1 — Check Prerequisites

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check_prereqs.sh
```

The script checks that the Trivy binary is installed and prints actionable
instructions if it is missing. Do not proceed to scanning until the script
exits with "All checks passed."

If Trivy is missing, consult `references/setup.md` for installation instructions.

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

Use `--quiet` to suppress INFO logs and `--format json` for structured output.
For `trivy repo`, redirect stderr to suppress git clone progress bars.

```bash
# Filesystem scan — auto-detects Python + Node manifests
trivy fs --quiet --format json --scanners vuln,secret /path/to/target

# HIGH and CRITICAL only (recommended for install-or-not decisions)
trivy fs --quiet --format json --severity HIGH,CRITICAL --scanners vuln,secret /path/to/target

# Container image
trivy image --quiet --format json python:3.12-slim

# Remote git repo (2>/dev/null suppresses git clone progress)
trivy repo --quiet --format json --scanners vuln,secret https://github.com/org/repo 2>/dev/null
```

---

## Step 4 — Interpret and Report Results

After the scan completes, parse the JSON output and present results using this
structure:

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
- Supported language coverage: https://trivy.dev/docs/latest/coverage/language/
