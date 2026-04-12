#!/usr/bin/env python3
"""
Configures MLflow autologging for a Claude Code project.

Runs `mlflow autolog claude` in a temporary directory, then merges the
generated settings into .claude/settings.local.json without touching
the project's .claude/settings.json.

Usage:
    setup-mlflow.py -u <tracking-uri> -n <experiment-name> [-d <project-dir>]
"""

import argparse
import json
import subprocess
import tempfile
from pathlib import Path


def deep_merge(base: dict, overlay: dict) -> dict:
    """Merge overlay into base, deduplicating list entries by value."""
    result = base.copy()
    for key, value in overlay.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        elif key in result and isinstance(result[key], list) and isinstance(value, list):
            seen = {json.dumps(item, sort_keys=True) for item in result[key]}
            for item in value:
                if json.dumps(item, sort_keys=True) not in seen:
                    result[key].append(item)
        else:
            result[key] = value
    return result


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Configure MLflow autologging for a Claude Code project"
    )
    parser.add_argument("-u", "--uri", required=True, help="MLflow tracking URI")
    parser.add_argument("-n", "--name", required=True, help="Experiment name (e.g. org/project)")
    parser.add_argument("-d", "--dir", default=".", help="Project root directory (default: .)")
    args = parser.parse_args()

    project_dir = Path(args.dir).resolve()
    settings_local = project_dir / ".claude" / "settings.local.json"

    with tempfile.TemporaryDirectory() as tmpdir:
        subprocess.run(
            ["mlflow", "autolog", "claude", "-d", tmpdir, "-u", args.uri, "-n", args.name],
            check=True,
        )
        tmp_settings = Path(tmpdir) / ".claude" / "settings.json"
        if not tmp_settings.exists():
            raise RuntimeError("mlflow autolog did not generate .claude/settings.json")
        generated = json.loads(tmp_settings.read_text())

    existing = json.loads(settings_local.read_text()) if settings_local.exists() else {}
    merged = deep_merge(existing, generated)

    settings_local.parent.mkdir(parents=True, exist_ok=True)
    settings_local.write_text(json.dumps(merged, indent=2) + "\n")
    print(f"✓ MLflow settings written to {settings_local}")


if __name__ == "__main__":
    main()
