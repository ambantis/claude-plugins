# MLflow Installation Options

## Check installed version

```bash
mlflow --version
```

Requires MLflow >= 2.19.0 for the `autolog claude` subcommand.

## Installation methods

### pip (system or active virtualenv)

```bash
pip install mlflow
```

### uv (recommended if uv is already in use)

Install as a standalone tool (available system-wide):

```bash
uv tool install mlflow
```

Or add to the current project:

```bash
uv add mlflow
```

### pipx (isolated, globally available)

```bash
pipx install mlflow
```

### conda / mamba

```bash
conda install -c conda-forge mlflow
```

## Verify the autolog subcommand is available

```bash
mlflow autolog --help
```

The `claude` subcommand should appear in the output. If it doesn't, upgrade MLflow:

```bash
pip install --upgrade mlflow
# or
uv tool upgrade mlflow
# or
pipx upgrade mlflow
```
