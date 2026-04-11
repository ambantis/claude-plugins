---
name: mlflow-traces
description: >
  This skill should be used when the user asks to "view traces", "see my Claude
  traces", "open MLflow", "show me the MLflow UI", "check my traces", or "view my
  MLflow experiments". Checks that MLflow has been set up, verifies whether the
  MLflow server is running, and directs the user to the UI or provides the command
  to start the server.
---

# View MLflow Traces

Directs the user to the MLflow UI to inspect recorded Claude traces.

Traces are written directly to the SQLite database by the Stop hook, regardless of
whether the MLflow server is running. The server is only needed for viewing.

---

## Step 1 — Check that MLflow has been set up

Verify the database exists:

```bash
test -f ~/.claude/mlflow/mlflow.db && echo "exists" || echo "missing"
```

If missing, MLflow has not been set up for this machine. Inform the user and
invoke the `mlflow-setup` skill to run the setup workflow before continuing.

---

## Step 2 — Check if the MLflow server is running

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000
```

- **`200`** — server is running, go to Step 3.
- **Anything else** — server is not running, go to Step 4.

---

## Step 3 — Server is running

Tell the user:

> MLflow is running. Open your browser to:
> http://localhost:5000/#/experiments

---

## Step 4 — Server is not running

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
