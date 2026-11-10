#!/usr/bin/env bash
#
# chat.sh — Interactive chat with a local GGUF model (Metal/GPU).
#
# Usage:
#   ./src/chat.sh [model.gguf]
#
# Defaults to the Q4_K_M model if none is given.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODEL="${1:-$ROOT/models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf}"

if [[ ! -f "$MODEL" ]]; then
  echo "Model not found: $MODEL" >&2
  echo "Download it first (see README)." >&2
  exit 1
fi

# Conversation mode is the default in current llama.cpp builds; -sys sets the system prompt.
exec "$ROOT/bin/llama-cli" \
  -m "$MODEL" \
  -ngl 99 \
  -c 4096 \
  --color \
  -sys "You are a helpful, concise assistant."
