---
name: mlflow-traces
description: >
  This skill should be used when the user asks to "view traces", "see my Claude
  traces", "open MLflow", "show me the MLflow UI", "check my traces", or "view my
  MLflow experiments". Checks that MLflow has been set up and directs the user to
  the UI.
---

# View MLflow Traces

Directs the user to the MLflow UI to inspect recorded Claude traces.

---

## Step 1 — Check that MLflow has been set up

Read `~/.claude/mlflow/mlflow.db`.

If the file does not exist, tell the user:

> MLflow has not been set up on this machine. Please invoke the `mlflow-setup`
> skill to get started.

---

## Step 2 — Direct the user to the UI

Tell the user:

> Open your browser to:
> http://localhost:5000/#/experiments
>
> If the MLflow server is not already running, start it with:
> ```bash
> mlflow server --backend-store-uri sqlite:////${HOME}/.claude/mlflow/mlflow.db
> ```
