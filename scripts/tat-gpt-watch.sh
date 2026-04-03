#!/bin/bash
# tat-gpt-watch.sh — GPT third-eye reviewer for TAT v2
# Reads session.md + today.md + decisions.md + diff → sends briefing to GPT
# GPT responses written back into session.md as [GPT] entries.
#
# Usage: tat-gpt-watch.sh [project-root]

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$HOME/.tinyaiteam/config.sh"
PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TAT_DIR="$PROJECT_ROOT/.tat"
CURSOR_FILE="$TAT_DIR/gpt-cursor"
SESSION_FILE="$TAT_DIR/session.md"
TODAY_FILE="$TAT_DIR/today.md"

# --- Validation ---

if [ -z "${OPENAI_API_KEY:-}" ]; then exit 0; fi
if [ ! -d "$TAT_DIR" ]; then exit 0; fi

cd "$PROJECT_ROOT"

BRANCH=$(git branch --show-current 2>/dev/null || true)
if [ -z "$BRANCH" ] || [ "$BRANCH" = "main" ]; then exit 0; fi

# --- Load config + GPT caller ---

[ -f "$CONFIG" ] && source "$CONFIG"
source "$SCRIPT_DIR/tat-gpt.sh"

# --- Cost guard: track daily spend, downgrade model after budget ---

COST_FILE="/tmp/tat-gpt-cost-$(date +%Y%m%d)"
DAILY_BUDGET="${TAT_DAILY_BUDGET:-3.00}"
COST_PER_CODEX="${TAT_COST_PER_CODEX:-0.05}"
COST_PER_FALLBACK="${TAT_COST_PER_FALLBACK:-0.02}"
FALLBACK_MODEL="${TAT_FALLBACK_MODEL:-gpt-5.4-mini}"
QUALITY_MODEL="${TAT_CODE_REVIEW_MODEL:-gpt-5.2-codex}"

# Read today's spend
DAILY_SPEND="0.00"
[ -f "$COST_FILE" ] && DAILY_SPEND=$(cat "$COST_FILE")

# Pick model based on budget
MODEL="$QUALITY_MODEL"
COST_THIS_CALL="$COST_PER_CODEX"

OVER_BUDGET=$(python3 -c "print('yes' if float('$DAILY_SPEND') >= float('$DAILY_BUDGET') else 'no')" 2>/dev/null || echo "no")
if [ "$OVER_BUDGET" = "yes" ]; then
  MODEL="$FALLBACK_MODEL"
  COST_THIS_CALL="$COST_PER_FALLBACK"
fi

export TAT_GPT_TIMEOUT=300

# --- Read cursor ---

LAST_SEEN=0
[ -f "$CURSOR_FILE" ] && LAST_SEEN=$(cat "$CURSOR_FILE" 2>/dev/null || echo "0")

# --- Count unseen session entries ---

UNSEEN_ENTRIES=""
ENTRY_COUNT=0
TOTAL_ENTRIES=0
HAS_URGENT=false

if [ -f "$SESSION_FILE" ]; then
  # Get total line count and unseen lines (lines after cursor position)
  TOTAL_ENTRIES=$(grep -c '^\- \[' "$SESSION_FILE" 2>/dev/null || echo "0")
  ENTRY_COUNT=$(( TOTAL_ENTRIES - LAST_SEEN ))
  [ "$ENTRY_COUNT" -lt 0 ] && ENTRY_COUNT=0

  if [ "$ENTRY_COUNT" -gt 0 ]; then
    # Get last N entries (unseen ones)
    UNSEEN_ENTRIES=$(grep '^\- \[' "$SESSION_FILE" | tail -"$ENTRY_COUNT")
    # Check for urgent (!!)
    echo "$UNSEEN_ENTRIES" | grep -q '@@' && HAS_URGENT=true
  fi
fi

# --- Check if there's a reason to call GPT ---

DIFF_LINES=$(git diff main...HEAD 2>/dev/null | wc -l | tr -d ' ' || echo "0")
RISKY_FILES=$(git diff --name-only main...HEAD 2>/dev/null | grep -E '(auth|security|schema|migration|hook|deploy|\.env|config)' || true)

if [ "$ENTRY_COUNT" -eq 0 ] && [ "$DIFF_LINES" -lt 30 ] && [ -z "$RISKY_FILES" ]; then
  exit 0
fi

# --- Build GPT briefing ---

# Mode detection (from today.md or default)
MODE="Coding"
[ -f "$TODAY_FILE" ] && MODE=$(grep -m1 '^MODE:' "$TODAY_FILE" | sed 's/^MODE: *//' || echo "Coding")

# Today's goals
TODAY=""
[ -f "$TODAY_FILE" ] && TODAY=$(cat "$TODAY_FILE")

# Last 3 decisions
DECISIONS=""
[ -f "$TAT_DIR/decisions.md" ] && DECISIONS=$(tail -20 "$TAT_DIR/decisions.md")

# Spec summary
SPEC=""
[ -f "$TAT_DIR/spec.md" ] && SPEC=$(head -15 "$TAT_DIR/spec.md")

# Last 10 session entries for context (even seen ones)
SESSION_CONTEXT=""
[ -f "$SESSION_FILE" ] && SESSION_CONTEXT=$(grep '^\- \[' "$SESSION_FILE" | tail -10)

# Diff (only in Coding/Review mode)
TRIMMED_DIFF=""
FILES_CHANGED=""
if [ "$MODE" = "Coding" ] || [ "$MODE" = "Review" ]; then
  FILES_CHANGED=$(git diff --name-only main...HEAD 2>/dev/null || true)
  TRIMMED_DIFF=$(git diff main...HEAD 2>/dev/null | head -300 || true)
fi

# --- Call GPT ---

SYSTEM_PROMPT="You are a senior engineer on a 3-person team. You are the ADVISOR.
- User = Product Owner (intent, priorities, corrections)
- You (GPT) = Senior Advisor (critique, alternatives, risk flags)
- Opus = Orchestrator (decides, executes, writes code)

You are reviewing the latest session activity. Start with ACK:
ACK: Task=<current task> | Mode=<mode> | Constraints=<key constraints>

Then respond based on mode:
- Design: challenge ideas, suggest alternatives, ask clarifying questions
- Planning: challenge estimates, flag risks, suggest priority changes
- Coding: review diff for bugs, security, scope creep
- Review: deep analysis of changes

If you see @@ entries, address those FIRST — they are urgent flags from the user.
If current work contradicts a decision in DECISIONS, flag it.
If you see user corrections, note the pattern.

Keep responses concise. One bullet per observation. Tag each: BLOCKER / SUGGESTION / NOTE."

USER_PROMPT="MODE: $MODE

PROJECT:
$SPEC

TODAY:
$TODAY

LAST DECISIONS:
$DECISIONS

SESSION (last 10 entries):
$SESSION_CONTEXT

NEW ENTRIES (unseen by you):
$UNSEEN_ENTRIES

CODE CHANGES:
Files: $FILES_CHANGED
Diff ($DIFF_LINES lines, first 300):
$TRIMMED_DIFF"

tat_gpt_call "$MODEL" "$SYSTEM_PROMPT" "$USER_PROMPT" 2>/dev/null || exit 0

# --- Update daily cost ---
NEW_SPEND=$(python3 -c "print(f'{float(\"$DAILY_SPEND\") + float(\"$COST_THIS_CALL\"):.2f}')" 2>/dev/null || echo "$DAILY_SPEND")
echo "$NEW_SPEND" > "$COST_FILE"

# --- Write GPT response into session.md ---

if [ -n "$REVIEW" ] && [ -f "$SESSION_FILE" ]; then
  TIMESTAMP=$(date +"%H:%M")
  # Append GPT's response as session entries
  echo "$REVIEW" | while IFS= read -r line; do
    [ -z "$line" ] && continue
    # Skip the ACK line from being logged (it's metadata)
    echo "$line" | grep -qi '^ACK:' && continue
    echo "- [$TIMESTAMP][$MODE][GPT] $line" >> "$SESSION_FILE"
  done
fi

# Update cursor
echo "$TOTAL_ENTRIES" > "$CURSOR_FILE"

# --- Also write gpt.md as quick-reference ---

TIMESTAMP_FULL=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat > "$TAT_DIR/gpt.md" <<GPTEOF
# GPT Review

**Date:** $TIMESTAMP_FULL
**Branch:** $BRANCH
**Model:** $MODEL
**Mode:** $MODE
**Unseen entries:** $ENTRY_COUNT
**Diff:** $DIFF_LINES lines
**Daily spend:** \$$NEW_SPEND / \$$DAILY_BUDGET

$REVIEW
GPTEOF
