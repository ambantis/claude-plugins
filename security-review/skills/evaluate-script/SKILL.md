---
name: evaluate-script
description: >
  Static analysis of a single script file or inline shell command. Use when asked
  to "evaluate this script", "what does this script do", "is this script safe",
  "analyze this hook", or when evaluate-marketplace delegates per-script analysis.
  Reads the script, checks for high-risk patterns, summarizes what it does in plain
  language, and returns a structured risk verdict.
---

# Evaluate Script

Analyzes a single script for security risk. Combines pattern matching with
LLM reasoning about intent.

Input is either:
- A **file path** — read and analyze the file directly
- An **inline command string** — analyze the command as written (no source to read)

---

## Step 1 — Read the script

For a file path, read the full contents.

For an inline command, skip to Step 3 — there is no source to grep.

---

## Step 2 — Check for high-risk patterns

```bash
# Network calls
grep -nE 'curl|wget|nc |ncat|fetch|http\.|urllib|requests\.' "${SCRIPT}"

# Sensitive path or variable access
grep -nE '~/\.ssh|~/\.claude|~/\.config|ANTHROPIC_API_KEY|_API_KEY|_TOKEN|_SECRET|\.env' "${SCRIPT}"

# Code download and execution
grep -nE 'curl.+\|.+(ba)?sh|wget.+\|.+(ba)?sh|eval\s*\$\(|eval\s*"\$\(' "${SCRIPT}"

# Shell startup file or persistence modification
grep -nE '\.bashrc|\.zshrc|\.profile|\.bash_profile|crontab|systemd' "${SCRIPT}"

# Privilege escalation
grep -nE '\bsudo\b|chmod\s+[+]s|chown\s+root' "${SCRIPT}"
```

Note which patterns matched and on which lines.

---

## Step 3 — Summarize what the script does

Write a plain-language description:
- What is the script's stated purpose (name, comments, context)?
- What does it actually do, step by step?
- Are there any discrepancies between the stated purpose and the actual behavior?

For an inline command, describe what the command does based on its name and arguments.

---

## Step 4 — Assign risk level

| Level | Criteria |
|---|---|
| **HIGH** | Sensitive data access + network call in same script; code download/execution (`curl \| bash`); modifies shell startup files or cron; privilege escalation (`sudo`, `chmod +s`) |
| **MEDIUM** | Network calls without apparent data exfiltration; reads sensitive paths but no outbound network; `eval` with controlled input |
| **LOW** | No network calls, no sensitive path access, no privilege escalation; standard file/process operations |

---

## Step 5 — Report

Return this structure (used by evaluate-marketplace to aggregate results):

```
Script: <path or "inline: <command>">
Risk:   HIGH | MEDIUM | LOW
What it does: <1-2 sentence plain-language summary>
Findings:
  - Line <N>: <matched pattern> — <why this is notable>
  - ...
Recommendation: SAFE TO RUN | REVIEW BEFORE RUNNING | DO NOT RUN
```
