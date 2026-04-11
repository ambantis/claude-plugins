---
name: evaluate-marketplace
description: >
  Pre-install security evaluation of a Claude plugin from the marketplace. Use
  when asked to "evaluate this plugin before installing", "is this plugin safe to
  install", "security check this marketplace plugin", "review this plugin", or
  given a GitHub URL or local path to a Claude plugin. Runs discovery, presents
  a security analysis plan to the user, then executes the plan using parallel
  subagents: Trivy scan, per-script static analysis, and sandboxed evaluation of
  any external tools the plugin requires to be installed.
---

# Evaluate Marketplace Plugin

Full pre-install security evaluation of a Claude plugin. Discovers all scripts,
hooks, and installation requirements; presents a plan; then dispatches parallel
subagents to analyze each independently.

---

## Step 1 — Resolve the target

If given a GitHub URL or `org/repo`:

```bash
TMPDIR=$(mktemp -d)
gh repo clone <org/repo> "${TMPDIR}/repo" -- --depth=1 2>/dev/null
TARGET="${TMPDIR}/repo"
```

If given a local path, use it directly as `TARGET`.

---

## Step 2 — Discovery

Run all discovery commands to understand the scope of the review before
presenting the plan. Do not begin analysis yet.

### 2a. Find scripts

```bash
# Shell scripts
find "${TARGET}" -name "*.sh" -type f | sort

# Python scripts
find "${TARGET}" -name "*.py" -type f | sort
```

### 2b. Find inline hook commands

```bash
python3 - "${TARGET}" <<'EOF'
import json, pathlib, sys
target = pathlib.Path(sys.argv[1])
for plugin_json in target.rglob(".claude-plugin/plugin.json"):
    data = json.loads(plugin_json.read_text())
    for event, entries in data.get("hooks", {}).items():
        entries = entries if isinstance(entries, list) else [entries]
        for entry in entries:
            cmd = entry.get("command", "")
            if cmd:
                print(f"HOOK [{event}]: {cmd}")
EOF
```

### 2c. Find installation requirements

```bash
# Package manager install commands in any text file
grep -rn --include="*.md" --include="*.sh" --include="*.txt" \
  -E '(pip install|pip3 install|uv pip install|uv tool install|uv add|npm install|npm i|brew install|cargo install)\s+[a-zA-Z0-9_.=-]+' \
  "${TARGET}" 2>/dev/null

# curl|bash / wget|bash patterns
grep -rn --include="*.md" --include="*.sh" \
  -E 'curl.+\|\s*(ba)?sh|wget.+\|\s*(ba)?sh' \
  "${TARGET}" 2>/dev/null
```

---

## Step 3 — Present the plan

Summarize what was found and present the analysis plan to the user before
proceeding. Use this format:

```
## Security Analysis Plan: <plugin name>

I found the following to analyze:

**Scripts** (N)
  - scripts/init.sh
  - hooks/stop-hook.sh
  - ...

**Inline hook commands** (N)
  - HOOK [Stop]: mlflow autolog claude stop-hook
  - ...

**Installation requirements** (N)
  - mlflow==2.19.0  (pip)
  - markitdown       (pip, unpinned)
  - ...

**Analysis steps:**
1. Trivy scan — CVEs and secrets across the entire repo
2. evaluate-script — static analysis of each script and inline hook
3. evaluate-installation — sandboxed install + Trivy scan for each install requirement

Shall I proceed?
```

Wait for user confirmation before continuing.

---

## Step 4 — Execute in parallel

Once the user approves, dispatch independent subagents concurrently:

- **One subagent** for the Trivy scan (follow `${CLAUDE_PLUGIN_ROOT}/skills/trivy-scan/SKILL.md`)
- **One subagent per script** for static analysis (follow `${CLAUDE_PLUGIN_ROOT}/skills/evaluate-script/SKILL.md`)
- **One subagent per inline hook command** for static analysis (follow `${CLAUDE_PLUGIN_ROOT}/skills/evaluate-script/SKILL.md`, inline command mode)
- **One subagent per installation requirement** for sandboxed scanning (follow `${CLAUDE_PLUGIN_ROOT}/skills/evaluate-installation/SKILL.md`)

Collect all results before proceeding to Step 5.

---

## Step 5 — Aggregate verdict

Combine all subagent results into a single report:

```markdown
## Security Evaluation: <plugin name>

### Overall Verdict
SAFE TO INSTALL | REVIEW RECOMMENDED | DO NOT INSTALL

### Dependency Scan (Trivy)
<CVE summary or "No vulnerabilities found">
<Secrets found or "No secrets detected">

### Script Analysis
| Script | Risk | Summary |
|---|---|---|
| scripts/init.sh | LOW | Initializes local database directory |
| hooks/stop-hook.sh | MEDIUM | Makes outbound network call to localhost |

### Inline Hooks
| Command | Risk | Summary |
|---|---|---|
| mlflow autolog claude stop-hook | LOW | Records session trace to local SQLite DB |

### Installation Requirements
| Package | Verdict | Critical/High CVEs |
|---|---|---|
| mlflow==2.19.0 | SAFE TO INSTALL | 0 |
| markitdown (latest) | REVIEW RECOMMENDED | 1 HIGH |

### Findings Requiring Attention
- <specific finding with recommendation>
- ...
```

**Overall verdict rules:**
- `SAFE TO INSTALL` — Trivy clean, all scripts LOW risk, all packages safe
- `REVIEW RECOMMENDED` — any MEDIUM-risk script, LOW/MEDIUM CVEs, or unpinned packages
- `DO NOT INSTALL` — any HIGH-risk script, any HIGH/CRITICAL CVE, any secret detected, or any `curl | bash` install pattern
