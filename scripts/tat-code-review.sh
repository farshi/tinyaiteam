#!/bin/bash
# tat-code-review.sh — Send code diff to GPT for structured review
# Usage: tat-code-review.sh [base-branch]
#   base-branch  Branch to diff against (default: main)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAT_DIR=".tat"
CONFIG="$HOME/.tinyaiteam/config.sh"
BASE_BRANCH="${1:-main}"

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

CODE_REVIEW_MODEL="${TAT_CODE_REVIEW_MODEL:-gpt-5.4-mini}"
SYNOPSIS_MODEL="${TAT_CODE_REVIEW_SYNOPSIS_MODEL:-gpt-4o-mini}"

# --- Read current task + epic ---

CURRENT_TASK=""
CURRENT_EPIC=""
if [ -f "$TAT_DIR/plan.md" ]; then
  CURRENT_TASK=$(grep -m1 '\- \[~\]' "$TAT_DIR/plan.md" || true)
  if [ -z "$CURRENT_TASK" ]; then
    CURRENT_TASK=$(grep -m1 '\- \[ \]' "$TAT_DIR/plan.md" || echo "No active task found")
  fi
  if [ -n "$CURRENT_TASK" ]; then
    TASK_LINE=$(grep -n -m1 -F -- "$CURRENT_TASK" "$TAT_DIR/plan.md" | cut -d: -f1)
    if [ -n "$TASK_LINE" ]; then
      CURRENT_EPIC=$(head -n "$TASK_LINE" "$TAT_DIR/plan.md" | grep -E '^## ' | tail -1 || true)
    fi
  fi
fi

# --- Gather diff ---

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
if [ -z "$CURRENT_BRANCH" ]; then
  echo "[TAT] ERROR: Not in a git repository" >&2
  exit 1
fi

if [ "$CURRENT_BRANCH" = "$BASE_BRANCH" ]; then
  echo "[TAT] ERROR: You're on $BASE_BRANCH. Switch to a task branch first." >&2
  exit 1
fi

DIFF=$(git diff "$BASE_BRANCH"...HEAD 2>/dev/null || git diff HEAD)
UNSTAGED=$(git diff 2>/dev/null)
UNTRACKED_FILES=$(git ls-files --others --exclude-standard)
UNTRACKED_CONTENT=""

if [ -n "$UNTRACKED_FILES" ]; then
  while IFS= read -r f; do
    if file "$f" | grep -q text; then
      UNTRACKED_CONTENT="${UNTRACKED_CONTENT}
--- $f ---
$(cat "$f")
"
    fi
  done <<< "$UNTRACKED_FILES"
fi

FULL_DIFF="${DIFF}${UNSTAGED:+
--- Unstaged changes ---
$UNSTAGED}"

DIFF_LINES=$(echo "$FULL_DIFF" | wc -l | tr -d ' ')

FILES_CHANGED=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || git diff --name-only HEAD)
if [ -n "$UNSTAGED" ]; then
  UNSTAGED_FILES=$(git diff --name-only)
  FILES_CHANGED=$(printf '%s\n%s' "$FILES_CHANGED" "$UNSTAGED_FILES" | sort -u)
fi
if [ -n "$UNTRACKED_FILES" ]; then
  FILES_CHANGED=$(printf '%s\n%s' "$FILES_CHANGED" "$UNTRACKED_FILES" | sort -u)
fi

SPEC_EXCERPT=""
[ -f "$TAT_DIR/spec.md" ] && SPEC_EXCERPT=$(head -20 "$TAT_DIR/spec.md")

# --- Decide tier ---

if [ "$DIFF_LINES" -lt 50 ]; then
  MODEL="$SYNOPSIS_MODEL"
  echo "[TAT] Code review: SYNOPSIS ($DIFF_LINES lines, using $MODEL)"
else
  MODEL="$CODE_REVIEW_MODEL"
  echo "[TAT] Code review: FULL ($DIFF_LINES lines, using $MODEL)"
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

SYSTEM_PROMPT="You are a senior code reviewer. You are NOT a gatekeeper — you are a second opinion. The human decides what to act on.

Your job:
1. Does the code accomplish the stated task?
2. Are there bugs, edge cases, or security issues?
3. Does the diff touch files OUTSIDE the stated scope? Flag scope creep.
4. Is anything missing that the task requires?
5. Is the code unnecessarily complex?

$ADVISOR_FORMAT"

if [ "$DIFF_LINES" -lt 50 ]; then
  USER_PROMPT="## Epic
${CURRENT_EPIC:-Unknown}

## Task
$CURRENT_TASK

## Branch
$CURRENT_BRANCH (based on $BASE_BRANCH)

## Files Changed
$FILES_CHANGED

## Summary
Small change ($DIFF_LINES lines). Quick sanity check.

## Diff
$FULL_DIFF"
else
  USER_PROMPT="## Epic
${CURRENT_EPIC:-Unknown}

## Task
$CURRENT_TASK

## Branch
$CURRENT_BRANCH (based on $BASE_BRANCH)

## Files Changed
$FILES_CHANGED

## Spec Context
$SPEC_EXCERPT

## Diff ($DIFF_LINES lines)
$FULL_DIFF"

  if [ -n "$UNTRACKED_CONTENT" ]; then
    USER_PROMPT="${USER_PROMPT}

## New Files (untracked)
$UNTRACKED_CONTENT"
  fi
fi

# --- Call GPT ---

echo "[TAT] Sending to $MODEL..."
echo "---"

tat_gpt_call "$MODEL" "$SYSTEM_PROMPT" "$USER_PROMPT"

echo ""
echo "[GPT] Review (code):"
echo ""
echo "$REVIEW"
echo ""
echo "---"

if echo "$REVIEW" | grep -A5 -iE '^BLOCKERS:' | grep -qi 'none'; then
  echo "[TAT] No blockers. Proceed at your discretion."
else
  echo "[TAT] Blockers found — review above and decide what to act on."
fi
