---
name: mlflow-setup
description: >
  This skill should be used when the user asks to "set up mlflow trace logging",
  "enable MLflow tracing", "log Claude traces to MLflow", "autolog Claude to MLflow",
  "set up autologging for debugging", or "configure MLflow for this repo". Initializes
  a local MLflow instance at ~/.claude/mlflow, runs mlflow autolog claude, and wires
  the generated settings into .claude/settings.local.json so each developer's config
  stays out of version control.
---

# MLflow Setup

Sets up per-repository MLflow trace logging for Claude sessions. Traces land in a
shared local MLflow instance (`~/.claude/mlflow/mlflow.db`) and are organized by
experiment name (one per repository).

Settings are written to `.claude/settings.local.json` — not `settings.json` — so
each developer maintains their own config and nothing is committed to the repo.

---

## Prerequisites

Check that MLflow is installed and up to date.

**Check installed version:**

```bash
which mlflow && mlflow --version
```

If missing, guide the user through installation using
`${CLAUDE_PLUGIN_ROOT}/skills/mlflow-setup/references/mlflow-installation.md`.

**Check latest release from GitHub:**

```bash
curl -s https://api.github.com/repos/mlflow/mlflow/releases/latest \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])"
```

Compare the installed version against the latest release tag (e.g., `v2.21.0`).
If the installed version is behind, inform the user:

> MLflow `<installed>` is installed, but `<latest>` is available. Would you like
> to update?

If the user agrees, offer the appropriate upgrade command based on how MLflow was
installed (check `which mlflow` path for hints — uv tool installs land in
`~/.local/share/uv/tools/`, pipx in `~/.local/pipx/`):

```bash
# pip
pip install --upgrade mlflow

# uv tool
uv tool upgrade mlflow

# pipx
pipx upgrade mlflow

# conda
conda update -c conda-forge mlflow
```

---

## Step 1 — Initialize the local MLflow instance

Skip this step if `~/.claude/mlflow/mlflow.db` already exists.

Create the shared MLflow directory and initialize the database:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mlflow-setup/scripts/init-mlflow-db.sh
```

The script creates `~/.claude/mlflow/`, starts `mlflow server`, waits for
`Application startup complete.` in stdout, then shuts the server down. This
creates `~/.claude/mlflow/mlflow.db`.

---

## Step 2 — Get the experiment name

Ask the user:

> What should the experiment name be for this repository? Use the format
> `org/project` (e.g., `adRise/hyades`, `ambantis/pyleet`).

Store the answer as `<EXPERIMENT_NAME>`.

---

## Step 3 — Run mlflow autolog

From the project root, run:

```bash
mlflow autolog claude \
  -u "sqlite:////${HOME}/.claude/mlflow/mlflow.db" \
  -n "<EXPERIMENT_NAME>"
```

This writes env vars and a Stop hook into `.claude/settings.json`.

Use `-d` to target a different directory if not in the project root:

```bash
mlflow autolog claude \
  -u "sqlite:////${HOME}/.claude/mlflow/mlflow.db" \
  -n "<EXPERIMENT_NAME>" \
  -d /path/to/project
```

---

## Step 4 — Migrate settings to settings.local.json

The autolog command writes to `.claude/settings.json`, but these settings are
developer-specific and must not be committed. Run the merge script to move them:

```bash
python ${CLAUDE_PLUGIN_ROOT}/skills/mlflow-setup/scripts/merge-settings-to-local.py
```

The script:
1. Reads `.claude/settings.json` and extracts all `MLFLOW_*` env vars and the
   `mlflow autolog claude stop-hook` Stop hook entry
2. Merges those into `.claude/settings.local.json` (creates it if absent, skips
   duplicate entries if already present)
3. Removes the MLflow-specific keys from `settings.json`

---

## Step 5 — Verify

```bash
cat .claude/settings.local.json
```

Expected shape:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "mlflow autolog claude stop-hook"
          }
        ]
      }
    ]
  },
  "env": {
    "MLFLOW_CLAUDE_TRACING_ENABLED": "true",
    "MLFLOW_TRACKING_URI": "sqlite:////home/<user>/.claude/mlflow/mlflow.db",
    "MLFLOW_EXPERIMENT_NAME": "<EXPERIMENT_NAME>"
  }
}
```

Also confirm `settings.json` no longer contains any `MLFLOW_*` keys.

---

## Step 6 — Ensure settings.local.json is gitignored

```bash
git check-ignore -v .claude/settings.local.json
```

If not ignored:

```bash
echo '.claude/settings.local.json' >> .gitignore
```

---

## Additional Resources

### Reference Files

- **`references/mlflow-docs.md`** — Pointer to `https://mlflow.org/llms.txt`, the
  canonical LLM-readable MLflow reference; fetch it for up-to-date API, CLI, and
  configuration details
- **`references/mlflow-installation.md`** — Installation options (pip, uv, pipx, conda)
  and how to verify the `autolog claude` subcommand is available

### Scripts

- **`scripts/init-mlflow-db.sh`** — Starts and stops the MLflow server to initialize
  the SQLite database
- **`scripts/merge-settings-to-local.py`** — Extracts MLflow settings from
  `settings.json` and merges them into `settings.local.json`
