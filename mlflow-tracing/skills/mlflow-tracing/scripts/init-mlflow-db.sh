#!/usr/bin/env bash
# Initialize the MLflow database by starting the server, waiting for startup,
# then shutting it down. The mlflow.db file is created on first startup.
#
# Usage: bash init-mlflow-db.sh [mlflow-dir]
#   mlflow-dir defaults to ~/.claude/mlflow

set -euo pipefail

MLFLOW_DIR="${1:-${HOME}/.claude/mlflow}"
LOG_FILE="${MLFLOW_DIR}/init.log"
TIMEOUT=30

mkdir -p "${MLFLOW_DIR}"

echo "Initializing MLflow database in ${MLFLOW_DIR}..."

# Start the server in the background
cd "${MLFLOW_DIR}"
mlflow server > "${LOG_FILE}" 2>&1 &
MLFLOW_PID=$!

# Wait for "Application startup complete." in the log
elapsed=0
while [ "${elapsed}" -lt "${TIMEOUT}" ]; do
    if grep -q "Application startup complete" "${LOG_FILE}" 2>/dev/null; then
        echo "MLflow server started (PID ${MLFLOW_PID}). Database initialized."
        break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

if [ "${elapsed}" -ge "${TIMEOUT}" ]; then
    echo "ERROR: MLflow server did not start within ${TIMEOUT}s. Check ${LOG_FILE}." >&2
    kill "${MLFLOW_PID}" 2>/dev/null || true
    exit 1
fi

# Shut down the server
kill "${MLFLOW_PID}" 2>/dev/null || true
wait "${MLFLOW_PID}" 2>/dev/null || true
echo "Server stopped. Database ready at ${MLFLOW_DIR}/mlflow.db"
