#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Entrypoint: starts all 5 services inside a single container
# Only port 6080 (policy-preprocessor) is exposed externally.
# ─────────────────────────────────────────────────────────────

set -e

PIDS=()

cleanup() {
    echo ""
    echo "[entrypoint] Stopping all services..."
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
        fi
    done
    wait 2>/dev/null
    echo "[entrypoint] All services stopped."
    exit 0
}

trap cleanup SIGINT SIGTERM

echo "========================================"
echo " Starting FHIR Questionnaire Pipeline"
echo "========================================"

# ── 0. Ensure storage directories exist ──
echo "[0/5] Initializing storage directories at ${LOCAL_STORAGE_PATH:-/app/data}..."
mkdir -p "${LOCAL_STORAGE_PATH:-/app/data}/pdf" \
         "${LOCAL_STORAGE_PATH:-/app/data}/md" \
         "${LOCAL_STORAGE_PATH:-/app/data}/chunks" 2>/dev/null || true

# ── 1. PDF to Markdown Service (Python / FastAPI) ──
echo "[1/4] Starting PDF to MD Service on port 8000..."
cd /app/services/pdf-to-md
python main.py &
PIDS+=($!)

# ── 2. Policy Preprocessor (Ballerina JAR) ──
echo "[2/4] Starting Policy Preprocessor on port 6080..."
cd /app/services/policy-preprocessor
SERVICE_PORT=6080 java -jar app.jar &
PIDS+=($!)

# ── 3. CQL Enrichment API (Node.js) ──
echo "[3/4] Starting CQL Enrichment API on port 3000..."
cd /app/services/cql-enrichment-api
PORT=3000 node server.js &
PIDS+=($!)

# ── 4. Questionnaire Orchestration (Ballerina JAR) ──
echo "[4/4] Starting Questionnaire Orchestration on port 6060..."
cd /app/services/orchestration
SERVICE_PORT=6060 java -jar app.jar &
PIDS+=($!)

echo ""
echo "========================================"
echo " All 4 services started."
echo " Exposed port: 6080 (Policy Preprocessor)"
echo "========================================"

# Wait for any child to exit; if one dies the container stops
wait -n
EXIT_CODE=$?
echo "[entrypoint] A service exited with code $EXIT_CODE — shutting down."
cleanup
