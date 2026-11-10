#!/usr/bin/env bash
#
# serve.sh — Serve a local GGUF model over an OpenAI-compatible HTTP API.
#
# Usage:
#   ./src/serve.sh [model.gguf] [port]
#
# Then POST to http://localhost:<port>/v1/chat/completions
# (drop-in replacement for the OpenAI client — no cloud, no API key).
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODEL="${1:-$ROOT/models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf}"
PORT="${2:-8080}"

if [[ ! -f "$MODEL" ]]; then
  echo "Model not found: $MODEL" >&2
  exit 1
fi

echo ">> Serving $(basename "$MODEL") on http://localhost:$PORT"
echo ">> OpenAI-compatible endpoint: http://localhost:$PORT/v1/chat/completions"
exec "$ROOT/bin/llama-server" \
  -m "$MODEL" \
  -ngl 99 \
  -c 4096 \
  --host 127.0.0.1 \
  --port "$PORT"
