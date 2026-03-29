#!/bin/bash
# ask-gpt.sh — Ask GPT a quick question with project context
# Usage: ask-gpt.sh <question>
#   Sends the question + project spec to GPT for a quick second opinion.
#   No auto-changes — just prints GPT's response.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAT_DIR=".tat"
CONFIG="$HOME/.tinyaiteam/config.sh"

# --- Validation ---

if [ $# -lt 1 ]; then
  echo "[TAT] Usage: ask-gpt.sh <question>" >&2
  exit 1
fi

QUESTION="$1"

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "[TAT] ERROR: OPENAI_API_KEY not set" >&2
  exit 1
fi

# --- Load config + shared GPT caller ---

[ -f "$CONFIG" ] && source "$CONFIG"
if [ -f "$SCRIPT_DIR/tat-gpt.sh" ]; then
  source "$SCRIPT_DIR/tat-gpt.sh"
elif [ -f "$HOME/.tinyaiteam/scripts/tat-gpt.sh" ]; then
  source "$HOME/.tinyaiteam/scripts/tat-gpt.sh"
else
  echo "[TAT] ERROR: tat-gpt.sh not found" >&2
  exit 1
fi

MODEL="${TAT_CODE_REVIEW_MODEL:-gpt-5.4-mini}"

# --- Build context ---

SPEC_CONTENT=""
[ -f "$TAT_DIR/spec.md" ] && SPEC_CONTENT=$(cat "$TAT_DIR/spec.md")

PLAN_EXCERPT=""
if [ -f "$TAT_DIR/plan.md" ]; then
  # Current epic + active tasks only (skip completed and backlog)
  PLAN_EXCERPT=$(sed '/^## Backlog/,$d' "$TAT_DIR/plan.md" | grep -E '(^## |^\- \[ \]|^\- \[~\])' || true)
fi

# --- Prompts ---

SYSTEM_PROMPT="You are a senior engineering advisor. Give a concise, opinionated answer. No fluff.

PROJECT SPEC:
$SPEC_CONTENT

ACTIVE TASKS:
$PLAN_EXCERPT"

echo "[TAT] Asking $MODEL..."
echo "---"

tat_gpt_call "$MODEL" "$SYSTEM_PROMPT" "$QUESTION"

echo ""
echo "[GPT]:"
echo ""
echo "$REVIEW"
echo ""
echo "---"
echo "[TAT] GPT opinion above. No changes made — your call."
