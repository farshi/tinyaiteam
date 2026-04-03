#!/bin/bash
# tat-gpt-watch.sh — Background GPT reviewer for TAT v2
# Triggered by Claude Code PostToolUse hook after commits.
# Sends spec + plan + diff to GPT (code review model), writes to .tat/gpt.md.
#
# Usage: tat-gpt-watch.sh [project-root]
#
# No rate limit — runs on every commit. Uses the configured code review model.
# Filtered: only runs if diff > 30 lines or risky files touched.

set -u  # No -e or pipefail: background script must not die on pipe breaks or GPT failures

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$HOME/.tinyaiteam/config.sh"
PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TAT_DIR="$PROJECT_ROOT/.tat"

# --- Validation ---

if [ -z "${OPENAI_API_KEY:-}" ]; then
  exit 0
fi

if [ ! -d "$TAT_DIR" ]; then
  exit 0  # Not a TAT project
fi

# --- Check if diff is significant ---

cd "$PROJECT_ROOT"

BRANCH=$(git branch --show-current 2>/dev/null || true)
if [ -z "$BRANCH" ] || [ "$BRANCH" = "main" ]; then
  exit 0
fi

DIFF_LINES=$(git diff main...HEAD 2>/dev/null | wc -l | tr -d ' ' || echo "0")

# Check for risky files
RISKY_FILES=$(git diff --name-only main...HEAD 2>/dev/null | grep -E '(auth|security|schema|migration|hook|deploy|\.env|config)' || true)

if [ "$DIFF_LINES" -lt 30 ] && [ -z "$RISKY_FILES" ]; then
  exit 0  # Not significant enough
fi

# --- Load config + GPT caller ---

[ -f "$CONFIG" ] && source "$CONFIG"
source "$SCRIPT_DIR/tat-gpt.sh"

# Use the configured code review model (same quality as manual review)
MODEL="${TAT_CODE_REVIEW_MODEL:-gpt-5.2-codex}"
export TAT_GPT_TIMEOUT=300

# --- Gather context ---

SPEC=""
[ -f "$TAT_DIR/spec.md" ] && SPEC=$(head -20 "$TAT_DIR/spec.md")

PLAN=""
[ -f "$TAT_DIR/plan.md" ] && PLAN=$(grep -E '^\|.*\[ \]' "$TAT_DIR/plan.md" | head -5)

RECENT_COMMITS=$(git log --oneline -3 2>/dev/null || true)

FILES_CHANGED=$(git diff --name-only main...HEAD 2>/dev/null || true)

# Get first 300 lines of diff directly (no pipe break)
TRIMMED_DIFF=$(git diff main...HEAD 2>/dev/null | head -300 || true)

# --- Call GPT ---

SYSTEM_PROMPT="You are a senior code reviewer. Flag real issues — security, bugs, logic errors, scope creep. Not style.

Respond in this format:
BLOCKERS: (things that will cause real problems — or 'none')
- <issue>

SUGGESTIONS: (improvements, not requirements)
- <suggestion>

NOTES: (observations, context)
- <note>

CONFIDENCE: HIGH / MEDIUM / LOW — <one line reason>

Be specific — name the file and line. No filler."

USER_PROMPT="Project: $SPEC

Current task: $PLAN

Recent commits: $RECENT_COMMITS

Files changed: $FILES_CHANGED

Diff ($DIFF_LINES lines, showing first 300):
$TRIMMED_DIFF"

tat_gpt_call "$MODEL" "$SYSTEM_PROMPT" "$USER_PROMPT" 2>/dev/null

# --- Save output ---

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat > "$TAT_DIR/gpt.md" <<GPTEOF
# GPT Review

**Date:** $TIMESTAMP
**Branch:** $BRANCH
**Model:** $MODEL
**Diff:** $DIFF_LINES lines

$REVIEW
GPTEOF
