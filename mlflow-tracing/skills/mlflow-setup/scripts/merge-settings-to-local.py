#!/usr/bin/env python3
"""
Merge MLflow autolog settings from .claude/settings.json into
.claude/settings.local.json, then revert settings.json.

The `mlflow autolog claude` command writes env vars and a Stop hook to
settings.json. Since each developer has their own MLflow setup, these
settings belong in settings.local.json (which is gitignored).

Usage:
    python merge-settings-to-local.py [project-root]

    project-root defaults to the current working directory.
"""

import json
import sys
from copy import deepcopy
from pathlib import Path


def load_json(path: Path) -> dict:
    if path.exists():
        with open(path) as f:
            return json.load(f)
    return {}


def save_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def split_env(env: dict) -> tuple[dict, dict]:
    """Return (mlflow_env, remaining_env)."""
    mlflow = {k: v for k, v in env.items() if k.startswith("MLFLOW_")}
    remaining = {k: v for k, v in env.items() if not k.startswith("MLFLOW_")}
    return mlflow, remaining


def split_stop_hooks(hooks: dict) -> tuple[list, list]:
    """
    Partition Stop hook matchers into those containing mlflow commands and
    those that don't. Returns (mlflow_matchers, remaining_matchers).
    """
    stop_matchers = hooks.get("Stop", [])
    mlflow_matchers: list = []
    remaining_matchers: list = []

    for matcher in stop_matchers:
        hook_list = matcher.get("hooks", [])
        mlflow_hooks = [h for h in hook_list if "mlflow" in h.get("command", "").lower()]
        other_hooks = [h for h in hook_list if "mlflow" not in h.get("command", "").lower()]

        if mlflow_hooks:
            mlflow_matchers.append({**matcher, "hooks": mlflow_hooks})
        if other_hooks:
            remaining_matchers.append({**matcher, "hooks": other_hooks})

    return mlflow_matchers, remaining_matchers


def merge_into_local(local: dict, mlflow_env: dict, mlflow_stop_matchers: list) -> dict:
    result = deepcopy(local)

    if mlflow_env:
        result.setdefault("env", {}).update(mlflow_env)

    if mlflow_stop_matchers:
        existing_stop = result.setdefault("hooks", {}).setdefault("Stop", [])
        existing_commands = {
            h.get("command", "")
            for matcher in existing_stop
            for h in matcher.get("hooks", [])
        }
        for matcher in mlflow_stop_matchers:
            new_hooks = [
                h for h in matcher.get("hooks", [])
                if h.get("command", "") not in existing_commands
            ]
            if new_hooks:
                existing_stop.append({**matcher, "hooks": new_hooks})

    return result


def revert_settings(settings: dict, remaining_env: dict, remaining_stop_matchers: list) -> dict:
    reverted = deepcopy(settings)

    if remaining_env:
        reverted["env"] = remaining_env
    else:
        reverted.pop("env", None)

    remaining_hooks = deepcopy(settings.get("hooks", {}))
    if remaining_stop_matchers:
        remaining_hooks["Stop"] = remaining_stop_matchers
    else:
        remaining_hooks.pop("Stop", None)

    if remaining_hooks:
        reverted["hooks"] = remaining_hooks
    else:
        reverted.pop("hooks", None)

    return reverted


def main() -> None:
    project_root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    claude_dir = project_root / ".claude"
    settings_path = claude_dir / "settings.json"
    local_path = claude_dir / "settings.local.json"

    settings = load_json(settings_path)
    local = load_json(local_path)

    mlflow_env, remaining_env = split_env(settings.get("env", {}))
    mlflow_stop_matchers, remaining_stop_matchers = split_stop_hooks(settings.get("hooks", {}))

    if not mlflow_env and not mlflow_stop_matchers:
        print("No MLflow settings found in settings.json. Nothing to merge.")
        sys.exit(0)

    updated_local = merge_into_local(local, mlflow_env, mlflow_stop_matchers)
    save_json(local_path, updated_local)
    print(f"Wrote MLflow settings to {local_path}")

    reverted = revert_settings(settings, remaining_env, remaining_stop_matchers)
    save_json(settings_path, reverted)
    print(f"Reverted {settings_path}")


if __name__ == "__main__":
    main()
