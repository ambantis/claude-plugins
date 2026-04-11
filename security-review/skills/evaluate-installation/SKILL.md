---
name: evaluate-installation
description: >
  Evaluates the safety of installing an external tool or package required by a
  Claude plugin. Use when asked to "is it safe to install X", "evaluate this
  package before I install it", or when evaluate-marketplace delegates per-package
  analysis. Installs the package in an isolated uv sandbox, runs Trivy against it,
  and reports CVEs and dependency risk.
---

# Evaluate Installation

Assesses the safety of installing a package by sandboxing the install with `uv`
and scanning the result with Trivy. Nothing is installed into the user's system.

Supports Python packages (pip/uv). For other package managers, see the notes
at the end of this skill.

---

## Step 1 — Confirm the package details

You need:
- **Package name** — e.g. `mlflow`
- **Version** — e.g. `2.19.0` (use the exact version the plugin requires if pinned;
  otherwise use latest)
- **Package manager** — pip/uv, npm, or brew

If not already known, ask the user or extract from the plugin's install instructions.

---

## Step 2 — Create a sandbox and install (Python/uv)

```bash
SANDBOX=$(mktemp -d)
uv venv "${SANDBOX}/venv" --quiet
uv pip install \
  --python "${SANDBOX}/venv/bin/python" \
  --quiet \
  "<package>==<version>"
echo "Installed to: ${SANDBOX}/venv"
```

This installs the package and all its transitive dependencies into an isolated
virtualenv. Nothing touches the user's system Python or global environment.

---

## Step 3 — Run Trivy against the sandbox

```bash
trivy fs --quiet --format json --scanners vuln "${SANDBOX}/venv"
```

Note: `--scanners vuln` only — we are scanning installed packages for CVEs,
not looking for secrets inside the venv.

---

## Step 4 — Clean up

```bash
rm -rf "${SANDBOX}"
```

---

## Step 5 — Report

Apply the verdict framework from `${CLAUDE_PLUGIN_ROOT}/skills/trivy-scan/SKILL.md`
Step 4 and return this structure:

```
Package: <name>==<version>
Verdict: SAFE TO INSTALL | REVIEW RECOMMENDED | DO NOT INSTALL
CVE summary: CRITICAL: N  HIGH: N  MEDIUM: N  LOW: N
High/Critical findings:
  - <CVE-ID> in <dep>@<version> — <description> (fix: <fixed_version> | no fix)
  - ...
Recommendation: <specific upgrade command or "no action required">
```

---

## Notes on other package managers

**npm**: Replace the uv sandbox steps with:
```bash
SANDBOX=$(mktemp -d)
npm install --prefix "${SANDBOX}" --save "<package>@<version>" 2>/dev/null
trivy fs --quiet --format json --scanners vuln "${SANDBOX}"
rm -rf "${SANDBOX}"
```

**Homebrew**: Homebrew cannot be sandboxed. Instead:
- Note that the package will be installed system-wide
- Run `brew info <package>` to identify the upstream source
- Advise the user to verify the formula at `https://formulae.brew.sh/formula/<package>`
- Flag for manual review rather than automated scanning
