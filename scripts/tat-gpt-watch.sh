#!/bin/bash
# tat-gpt-watch.sh — Background GPT reviewer for TAT v2
# Triggered by Claude Code PostToolUse hook after significant changes.
# Sends spec + plan + diff to GPT (fast model), writes to .tat/gpt.md.
#
# Usage: tat-gpt-watch.sh [project-root]
#
# Rate-limited: max once per 10 minutes.
# Filtered: only runs if diff > 30 lines or risky files touched.

set -u  # No -e or pipefail: background script must not die on pipe breaks or GPT failures

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$HOME/.tinyaiteam/config.sh"
PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TAT_DIR="$PROJECT_ROOT/.tat"
RATE_FILE="/tmp/tat-gpt-watch-last"

# --- Validation ---

if [ -z "${OPENAI_API_KEY:-}" ]; then
  exit 0  # Silent — background script shouldn't spam errors
fi

if [ ! -d "$TAT_DIR" ]; then
  exit 0  # Not a TAT project
fi

# --- Rate limit: once per 10 minutes ---

if [ -f "$RATE_FILE" ]; then
  LAST=$(cat "$RATE_FILE")
  NOW=$(date +%s)
  ELAPSED=$(( NOW - LAST ))
  if [ "$ELAPSED" -lt 600 ]; then
    exit 0
  fi
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

# Use fast model for background reviews + longer timeout
MODEL="${TAT_CODE_REVIEW_SYNOPSIS_MODEL:-gpt-4o-mini}"
export TAT_GPT_TIMEOUT=120

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

SYSTEM_PROMPT="You are a background code reviewer. Quick scan only — flag real issues, not style.

Respond briefly:
- ISSUES: (security, bugs, logic errors — or 'none')
- NOTES: (1-2 observations)

Be terse. This runs automatically — don't waste tokens."

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
# GPT Background Review

**Date:** $TIMESTAMP
**Branch:** $BRANCH
**Model:** $MODEL
**Diff:** $DIFF_LINES lines

$REVIEW
GPTEOF

# Update rate limit
date +%s > "$RATE_FILE"
