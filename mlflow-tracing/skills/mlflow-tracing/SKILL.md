---
name: mlflow-tracing
description: >
  This skill should be used when the user asks to "set up mlflow trace logging",
  "enable MLflow tracing", "log Claude traces to MLflow", "autolog Claude to MLflow",
  "set up autologging for debugging", or "configure MLflow for this repo". Also
  triggers when the user asks to "view traces", "see my Claude traces", "open MLflow",
  "show me the MLflow UI", or "check my traces". Two modes: (1) setup — initializes a
  local MLflow instance and wires settings into .claude/settings.local.json; (2) view
  — checks whether the MLflow server is running and directs the user to the UI.
---

# MLflow Tracing

Two modes: **setup** (first-time configuration per repo) and **view** (open the UI
to inspect recorded traces).

Traces are written directly to the SQLite database by the Stop hook, regardless of
whether the MLflow server is running. The server is only needed for viewing.

---

## Mode 1 — Setup

Triggered by: "set up mlflow tracing", "enable MLflow tracing", "autolog Claude to
MLflow", "configure MLflow for this repo".

### Prerequisites

Check that MLflow is installed and up to date.

**Check installed version:**

```bash
which mlflow && mlflow --version
```

If missing, guide the user through installation using
`${CLAUDE_PLUGIN_ROOT}/skills/mlflow-tracing/references/mlflow-installation.md`.

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

### Step 1 — Initialize the local MLflow instance

Create the shared MLflow directory and initialize the database:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mlflow-tracing/scripts/init-mlflow-db.sh
```

The script creates `~/.claude/mlflow/`, starts `mlflow server`, waits for
`Application startup complete.` in stdout, then shuts the server down. This
creates `~/.claude/mlflow/mlflow.db`.

Skip this step if `~/.claude/mlflow/mlflow.db` already exists.

### Step 2 — Get the experiment name

Ask the user:

> What should the experiment name be for this repository? Use the format
> `org/project` (e.g., `adRise/hyades`, `ambantis/pyleet`).

Store the answer as `<EXPERIMENT_NAME>`.

### Step 3 — Run mlflow autolog

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

### Step 4 — Migrate settings to settings.local.json

The autolog command writes to `.claude/settings.json`, but these settings are
developer-specific and must not be committed. Run the merge script to move them:

```bash
python ${CLAUDE_PLUGIN_ROOT}/skills/mlflow-tracing/scripts/merge-settings-to-local.py
```

The script:
1. Reads `.claude/settings.json` and extracts all `MLFLOW_*` env vars and the
   `mlflow autolog claude stop-hook` Stop hook entry
2. Merges those into `.claude/settings.local.json` (creates it if absent, skips
   duplicate entries if already present)
3. Removes the MLflow-specific keys from `settings.json`

### Step 5 — Verify

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

### Step 6 — Ensure settings.local.json is gitignored

```bash
git check-ignore -v .claude/settings.local.json
```

If not ignored:

```bash
echo '.claude/settings.local.json' >> .gitignore
```

---

## Mode 2 — View Traces

Triggered by: "view traces", "see my Claude traces", "open MLflow", "show me the
MLflow UI", "check my traces".

### Step 1 — Check if the MLflow server is running

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000
```

- If the response is `200`: the server is already running — go to Step 2.
- If the connection is refused or returns anything other than `200`: go to Step 3.

### Step 2 — Server is running

Tell the user:

> MLflow is running. Open your browser to:
> http://localhost:5000/#/experiments

### Step 3 — Server is not running

Read `MLFLOW_TRACKING_URI` from `.claude/settings.local.json`:

```bash
python3 -c "
import json, pathlib
s = json.loads(pathlib.Path('.claude/settings.local.json').read_text())
print(s.get('env', {}).get('MLFLOW_TRACKING_URI', ''))
"
```

Tell the user to start the server in a terminal using that URI, for example:

```bash
mlflow server --backend-store-uri sqlite:////home/<user>/.claude/mlflow/mlflow.db
```

Then open the browser to:

> http://localhost:5000/#/experiments

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
