#!/usr/bin/env bash
#
# bench.sh — Benchmark a single GGUF model with llama-bench (Metal/GPU).
#
# Measures:
#   pp (prompt processing)  — tokens/sec ingesting the prompt   (prefill)
#   tg (token generation)   — tokens/sec generating new tokens  (decode)
#
# Usage:
#   ./benchmarks/bench.sh <model.gguf> [label]
#
# Output:
#   results/<label>.md  and  results/<label>.csv
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODEL="${1:?Usage: bench.sh <model.gguf> [label]}"
LABEL="${2:-$(basename "$MODEL" .gguf)}"

# --- Tunables (override via env) -------------------------------------------
# Defaults are the LIGHT profile: one benchmark pass, 3 reps.
# For a heavier, higher-fidelity run:  REPS=5 PROMPT_TOKENS=512 ./bench.sh ...
PROMPT_TOKENS="${PROMPT_TOKENS:-256}"   # prompt length timed for prefill
GEN_TOKENS="${GEN_TOKENS:-64}"          # tokens timed for decode
NGL="${NGL:-99}"                        # offload all layers to the Metal GPU
REPS="${REPS:-3}"                       # repetitions (mean ± stddev)
# ---------------------------------------------------------------------------
#
# Thermal note: llama-bench deliberately runs the model flat-out, so it is the
# single most intensive workload here. We therefore run it ONCE and emit CSV
# (the machine-readable source of truth); the script derives the markdown table
# from that CSV instead of running a second, redundant benchmark pass.

mkdir -p "$ROOT/results"
MD="$ROOT/results/${LABEL}.md"
CSV="$ROOT/results/${LABEL}.csv"

echo ">> Benchmarking: $MODEL"
echo ">> label=$LABEL  pp=$PROMPT_TOKENS  tg=$GEN_TOKENS  ngl=$NGL  reps=$REPS (single pass)"
echo ">> model size on disk: $(du -h "$MODEL" | awk '{print $1}')"
echo

# One pass only.
"$ROOT/bin/llama-bench" \
  -m "$MODEL" \
  -p "$PROMPT_TOKENS" \
  -n "$GEN_TOKENS" \
  -ngl "$NGL" \
  -r "$REPS" \
  -o csv | tee "$CSV"

# Derive a readable markdown table from the CSV (no extra inference).
awk -F, 'NR==1{for(i=1;i<=NF;i++){gsub(/"/,"",$i); h[$i]=i}
             print "| model | size | test | t/s (avg) |"; print "|---|---|---|---|"; next}
         {gsub(/"/,"",$0); n=split($0,f,",");
          printf "| %s | %s | %s | %s |\n", f[h["model_type"]], f[h["model_size"]], f[h["n_gen"]>0?"n_gen":"test"], f[h["avg_ts"]]}' \
  "$CSV" > "$MD" 2>/dev/null || cp "$CSV" "$MD"

echo
echo ">> Saved csv      -> $CSV   (source of truth)"
echo ">> Saved markdown -> $MD"
