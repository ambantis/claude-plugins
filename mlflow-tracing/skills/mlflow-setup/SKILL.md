---
name: mlflow-setup
description: >
  This skill should be used when the user asks to "set up mlflow trace logging",
  "enable MLflow tracing", "log Claude traces to MLflow", "autolog Claude to MLflow",
  "set up autologging for debugging", or "configure MLflow for this repo". Initializes
  a local MLflow instance at ~/.claude/mlflow, runs mlflow autolog claude, and wires
  the generated settings into .claude/settings.local.json so each developer's config
  stays out of version control.
allowed-tools: Bash(mlflow *) Bash(curl -s https://api.github.com/repos/mlflow*) Bash(mkdir -p ~/.claude/mlflow) Bash(*setup-mlflow.py*)
---

# MLflow Setup

Sets up per-repository MLflow trace logging for Claude sessions. Traces land in a
shared local MLflow instance (`~/.claude/mlflow/mlflow.db`) and are organized by
experiment name (one per repository).

Settings are written to `.claude/settings.local.json` — not `settings.json` — so
each developer maintains their own config and nothing is committed to the repo.

---

## Prerequisites

Check whether MLflow is installed and what version is current.

```bash
mlflow --version
```

```bash
curl -s https://api.github.com/repos/mlflow/mlflow/releases/latest \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])"
```

**If MLflow is not found**, inform the user and ask how they would like to
install it. Consult `${CLAUDE_PLUGIN_ROOT}/skills/mlflow-setup/references/mlflow-installation.md`
for available options. Do not run any install command without explicit user
permission.

**If MLflow is installed but behind the latest release**, inform the user:

> MLflow `<installed>` is installed, but `<latest>` is available. Would you
> like to update? If so, how did you install it (pip, uv, pipx, conda)?

Wait for their answer before proceeding. Do not run an upgrade command without
explicit user permission.

**If MLflow is installed and current**, continue to Step 1.

---

## Step 1 — Create the MLflow directory

Create the directory if it doesn't already exist:

```bash
mkdir -p ~/.claude/mlflow
```

The SQLite database is created automatically the first time the Stop hook runs — no server startup needed during setup.

---

## Step 2 — Get the experiment name

Ask the user:

> What should the experiment name be for this repository? Use the format
> `org/project` (e.g., `adRise/hyades`, `ambantis/pyleet`).

Store the answer as `<EXPERIMENT_NAME>`.

---

## Step 3 — Configure autologging

```bash
${CLAUDE_PLUGIN_ROOT}/skills/mlflow-setup/scripts/setup-mlflow.py \
  -u "sqlite:////${HOME}/.claude/mlflow/mlflow.db" \
  -n "<EXPERIMENT_NAME>"
```

If not running from the project root, add `-d /path/to/project`.

---

## Step 4 — Verify

Read `.claude/settings.local.json` and confirm it contains the expected shape:

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

---

## Step 5 — Setup mlflow.db

Ask the user to run the following command, which will start an MLflow server and create the database:

```bash
mlflow server --backend-store-uri sqlite:////${HOME}/.claude/mlflow/mlflow.db
```

---

## Setup complete

Setup is done. Traces will be recorded automatically at the end of each Claude
session via the Stop hook.

To view traces, tell the user to run this command from any location:

```bash
mlflow server --backend-store-uri sqlite:////${HOME}/.claude/mlflow/mlflow.db
```

Then open `http://localhost:5000/#/experiments` in a browser.

---

## Additional Resources

### Reference Files

- **`references/mlflow-docs.md`** — Pointer to `https://mlflow.org/llms.txt`, the
  canonical LLM-readable MLflow reference; fetch it for up-to-date API, CLI, and
  configuration details
- **`references/mlflow-installation.md`** — Installation options (pip, uv, pipx, conda)
  and how to verify the `autolog claude` subcommand is available

### Scripts

- **`scripts/setup-mlflow.py`** — Runs `mlflow autolog claude` in a temp
  directory and deep-merges the result into `.claude/settings.local.json`
