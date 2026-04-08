---
name: security-review
description: >
  General-purpose security review agent. Use this skill whenever security analysis
  is needed on a codebase, package, directory, or pull request. Covers three modes:
  (1) pre-install review of a project on disk or GitHub before installing a plugin
  or dependency; (2) automated security sub-agent step within a coding plan, called
  by an orchestrator before merging or deploying; (3) PR review augmentation, adding
  a Trivy-backed security pass alongside a normal code review. Triggers include:
  "security review", "review this PR for security", "is this safe to install",
  "scan before installing", "check this repo for vulnerabilities", "security audit",
  "review PR #N", "run trivy on this", "check for CVEs", "any secrets in this diff".
  Also triggers automatically when an orchestrator agent includes a security-review
  step in a coding plan.
---

# Security Review Skill

A general-purpose security agent with three invocation modes. All modes use Trivy
for dependency/CVE scanning. PR review mode additionally analyzes the diff for
secrets, risky patterns, and dependency changes.

**Prerequisites:** Trivy + trivy-mcp must be installed and configured.
See `${CLAUDE_PLUGIN_ROOT}/skills/trivy-scan/SKILL.md` for setup. Run
`${CLAUDE_PLUGIN_ROOT}/scripts/check_prereqs.sh` if unsure.

---

## Determine the Mode

Read the request and identify which mode applies:

| Mode | Trigger examples |
|---|---|
| **Mode 1 — Pre-install review** | "review this before I install it", "is this plugin safe?", given a path or GitHub URL |
| **Mode 2 — Orchestrator sub-agent** | called programmatically as a step in a coding plan; target is a local directory |
| **Mode 3 — PR security review** | "review PR #N", "I'm doing a PR review", current branch has an open PR |

---

## Mode 1 — Pre-Install Review

Use when evaluating a project before installing it as a plugin or dependency.

### 1a. Identify the target

The target is one of:
- A **local directory** — already on disk
- A **GitHub URL** — `https://github.com/org/repo` or `org/repo`
- A **GitHub PR URL** — scan the repo at the PR's head commit

### 1b. Clone if remote

```bash
# Clone to a temp directory (do not install yet)
TMPDIR=$(mktemp -d)
gh repo clone <org/repo> "${TMPDIR}/repo" -- --depth=1
TARGET="${TMPDIR}/repo"
```

### 1c. Run Trivy filesystem scan

```bash
# Full scan — vulnerabilities + exposed secrets
trivy fs --scanners vuln,secret "${TARGET}"

# For a quick install decision, filter to HIGH/CRITICAL only
trivy fs --severity HIGH,CRITICAL --scanners vuln,secret "${TARGET}"

# Save JSON report for detailed analysis
trivy fs --format json --output trivy-report.json "${TARGET}"
```

### 1d. Check for dependency manifest changes (if reviewing a PR)

```bash
# List files changed in the PR that are dependency manifests
gh pr diff <PR_NUMBER> --name-only | grep -E \
  "package\.json|package-lock\.json|yarn\.lock|pyproject\.toml|uv\.lock|requirements.*\.txt|go\.mod|go\.sum|Gemfile|Gemfile\.lock|Cargo\.toml|Cargo\.lock"
```

Flag any dependency manifest changes for manual review — new packages being added
warrant extra scrutiny even if they have no known CVEs yet.

### 1e. Report

Use the verdict framework from `~/.claude/skills/trivy-scan/SKILL.md` Step 5.

---

## Mode 2 — Orchestrator Sub-Agent

Use when called as a step within a larger coding plan. The orchestrator provides
the target directory. Return a structured result the orchestrator can act on.

### 2a. Run the scan

```bash
trivy fs --format json --scanners vuln,secret "${TARGET}" \
  --output "${TARGET}/.security-review.json"
```

### 2b. Parse and return structured result

Extract from the JSON report and return this structure to the orchestrator:

```
SECURITY_REVIEW_RESULT:
  target: <path>
  verdict: PASS | WARN | FAIL
  critical_count: <n>
  high_count: <n>
  secrets_found: true | false
  blocking_findings:
    - <CVE-ID> in <package>@<version> (no fix available)
    - ...
  recommended_actions:
    - upgrade <package> to <fixed_version>
    - ...
```

**Verdict rules for orchestrator:**
- `PASS` — no CVEs or only LOW/MEDIUM with fixes available, no secrets
- `WARN` — LOW/MEDIUM CVEs present; orchestrator may proceed with caution
- `FAIL` — any HIGH/CRITICAL CVE, any secret, or any unfixable HIGH/CRITICAL

**If verdict is FAIL**, the orchestrator must halt the plan and surface the
findings to the user before proceeding.

---

## Mode 3 — PR Security Review

Use when conducting or augmenting a pull request review. This runs alongside
a normal code review (`/review`), not instead of it.

### 3a. Identify the PR

```bash
# If PR number is known
PR_NUMBER=<N>

# If on the feature branch, auto-detect
PR_NUMBER=$(gh pr view --json number --jq '.number')

# Get PR metadata
gh pr view "${PR_NUMBER}" --json title,baseRefName,headRefName,changedFiles,additions,deletions
```

### 3b. Get the diff

```bash
# Full diff
gh pr diff "${PR_NUMBER}" > /tmp/pr-${PR_NUMBER}.diff

# Changed file list only
gh pr diff "${PR_NUMBER}" --name-only > /tmp/pr-${PR_NUMBER}-files.txt
```

### 3c. Run Trivy on the PR's head

```bash
# Check out the PR branch
gh pr checkout "${PR_NUMBER}"

# Run Trivy on the checked-out repo
trivy fs --scanners vuln,secret .

# Return to original branch when done
git checkout -
```

### 3d. Analyze the diff for security signals

Read `/tmp/pr-${PR_NUMBER}.diff` and flag:

**Dependency changes** — any additions to:
`package.json`, `package-lock.json`, `yarn.lock`, `pyproject.toml`, `uv.lock`,
`requirements*.txt`, `go.mod`, `Cargo.toml`, `Gemfile`

For each new dependency added, note: name, version, whether Trivy flagged it.

**Hardcoded secrets** — patterns in the diff to flag:
- API keys, tokens, passwords assigned to variables
- Private keys or certificates in code
- Connection strings with credentials embedded
- `.env` files being committed
- Any line matching common secret patterns (even if Trivy's secret scanner
  didn't catch it — defense in depth)

**Risky code patterns** — flag for human review (not auto-reject):
- `eval()`, `exec()`, `subprocess.call(shell=True)`
- Unvalidated user input passed to file paths, SQL, shell commands
- Disabled security controls (e.g. `verify=False`, `check=False`)
- New use of `pickle`, `yaml.load()` (without `Loader=`)
- Infrastructure changes: Dockerfiles, Terraform, k8s manifests — flag for
  a dedicated infrastructure security review

### 3e. Post findings back to GitHub

```bash
# Post security review as a PR comment
gh pr review "${PR_NUMBER}" \
  --comment \
  --body "$(cat /tmp/security-review-${PR_NUMBER}.md)"

# If findings require changes before merging
gh pr review "${PR_NUMBER}" \
  --request-changes \
  --body "$(cat /tmp/security-review-${PR_NUMBER}.md)"

# If clean
gh pr review "${PR_NUMBER}" \
  --comment \
  --body "**Security Review: ✅ PASS** — Trivy scan found no HIGH/CRITICAL CVEs and no secrets in this diff."
```

### 3f. Security review comment format

Structure the comment as:

```markdown
## 🔒 Security Review

**Verdict:** ✅ PASS | ⚠️ REVIEW RECOMMENDED | ⛔ CHANGES REQUIRED

### Dependency Scan (Trivy)
<CVE table or "No vulnerabilities found">

### New Dependencies Added
<list of new packages, or "None">

### Secrets / Credentials
<findings or "None detected">

### Code Patterns Flagged
<list with file:line references, or "None">

### Recommended Actions
<specific upgrade commands or "None required">

---
*Security review conducted by trivy-scan skill. This supplements but does not
replace a full code review.*
```

---

## Shared Reference

- Trivy prereq check: `${CLAUDE_PLUGIN_ROOT}/scripts/check_prereqs.sh`
- Verdict thresholds: `${CLAUDE_PLUGIN_ROOT}/skills/trivy-scan/SKILL.md` Step 5
- gh CLI docs: https://cli.github.com/manual
- trivy-mcp: https://github.com/aquasecurity/trivy-mcp
