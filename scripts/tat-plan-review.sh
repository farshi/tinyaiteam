#!/bin/bash
# tat-plan-review.sh — Send spec + plan to GPT for structured review
# Usage: tat-plan-review.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAT_DIR=".tat"
CONFIG="$HOME/.tinyaiteam/config.sh"

# --- Validation ---

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "[TAT] ERROR: OPENAI_API_KEY not set" >&2
  exit 1
fi

if [ ! -d "$TAT_DIR" ]; then
  echo "[TAT] ERROR: No .tat/ directory found. Run from a TAT-enabled project root." >&2
  exit 1
fi

# --- Load config + shared GPT caller ---

[ -f "$CONFIG" ] && source "$CONFIG"
source "$SCRIPT_DIR/tat-gpt.sh"

MODEL="${TAT_PLAN_REVIEW_MODEL:-gpt-5.4-pro}"

# --- Build context ---

SPEC_CONTENT=""
[ -f "$TAT_DIR/spec.md" ] && SPEC_CONTENT=$(cat "$TAT_DIR/spec.md")

PLAN_CONTENT=""
[ -f "$TAT_DIR/plan.md" ] && PLAN_CONTENT=$(cat "$TAT_DIR/plan.md")

DECISIONS=""
if [ -d "$TAT_DIR/decisions" ]; then
  for f in "$TAT_DIR/decisions/"*.md; do
    [ -f "$f" ] && DECISIONS="${DECISIONS}
--- $(basename "$f") ---
$(cat "$f")
"
  done
fi

# --- Prompts ---

ADVISOR_FORMAT="Respond in this EXACT format:

BLOCKERS: (max 3 — things that will cause real problems if not addressed)
- <issue> or \"none\"

SUGGESTIONS: (max 5 — improvements, not requirements)
- <suggestion>

NOTES: (observations, context, tradeoffs — not actionable)
- <note>

CONFIDENCE: HIGH / MEDIUM / LOW — <one line reason>

Rules:
- If everything is solid, write \"none\" under BLOCKERS and keep it short. Do NOT invent problems.
- No style nitpicks. Only structural, logical, or security issues.
- Be specific — name the file, task, or decision you are referring to.
- Never repeat feedback from a previous review round."

# --- Project context (read from spec) ---

SPEC_SUMMARY=""
[ -f "$TAT_DIR/spec.md" ] && SPEC_SUMMARY=$(cat "$TAT_DIR/spec.md")

PROJECT_CONTEXT="TOOLING CONTEXT: This project uses TAT (Tiny AI Team), a Claude Code skill that orchestrates multi-model workflows. Claude Code is Anthropic's AI coding assistant. TAT is NOT a standalone tool — it's skill files + bash scripts + config that plug into Claude Code. Opus plans, Sonnet codes (via subagents), GPT reviews.

PROJECT SPEC:
$SPEC_SUMMARY"

SYSTEM_PROMPT="You are a senior engineering advisor reviewing a project plan. You are NOT a gatekeeper — you are a second opinion. The human decides what to act on.

$PROJECT_CONTEXT

Your job:
1. Is the spec clear? Are there ambiguities that will cause problems later?
2. Is the task breakdown logical? Are epics properly scoped?
3. Are there missing tasks, wrong ordering, or risky dependencies?
4. Are the architectural decisions sound? Any blind spots?
5. Is anything over-engineered for what the spec describes?

$ADVISOR_FORMAT"

USER_PROMPT="## Spec
$SPEC_CONTENT

## Plan
$PLAN_CONTENT"

if [ -n "$DECISIONS" ]; then
  USER_PROMPT="${USER_PROMPT}

## Decisions Already Made
$DECISIONS"
fi

# --- Call GPT ---

echo "[TAT] Plan review using $MODEL..."
echo "---"

tat_gpt_call "$MODEL" "$SYSTEM_PROMPT" "$USER_PROMPT"

echo ""
echo "[GPT] Review (plan):"
echo ""
echo "$REVIEW"
echo ""
echo "---"

if echo "$REVIEW" | grep -A5 -iE '^BLOCKERS:' | grep -qi 'none'; then
  echo "[TAT] No blockers. Proceed at your discretion."
else
  echo "[TAT] Blockers found — review above and decide what to act on."
fi
