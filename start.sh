#!/bin/bash
set -e

cleanup() {
    echo ""
    echo "Shutting down all services..."
    kill 0
    exit 0
}
trap cleanup SIGINT SIGTERM

# ── Model check ────────────────────────────────────────────────────────────────
# config.json is always the first file written by save_pretrained — use it as
# the sentinel. If it exists the full model is already on disk.
TROCR_LOCAL_PATH="model/saved_models/trocr"

if [ ! -f "$TROCR_LOCAL_PATH/config.json" ]; then
    echo "TrOCR model not found at '$TROCR_LOCAL_PATH'."
    echo "Downloading — one-time ~2.2 GB download, please wait..."
    echo ""
    uv run python scripts/save_model_locally.py
    echo ""
    echo "Model saved. Continuing startup..."
else
    echo "TrOCR model found at '$TROCR_LOCAL_PATH'. Skipping download."
fi

# ── Services ───────────────────────────────────────────────────────────────────
# Frontend does not need the model, so it can start in parallel.
echo ""
echo "Starting frontend..."
(cd frontend && npm run dev) &

echo "Starting backend..."
(cd backend && uv run uvicorn app.main:app --reload --port 8000) &

echo ""
echo "All services started."
echo "  Frontend : http://localhost:5173"
echo "  Backend  : http://localhost:8000"
echo "  API Docs : http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop all services."

wait