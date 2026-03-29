#!/bin/bash
# tat-review.sh — Send current branch changes to GPT for review
# Usage: tat-review.sh [base-branch]
# Defaults base branch to "main"

set -euo pipefail

BASE_BRANCH="${1:-main}"
TAT_DIR=".tat"
CONFIG="$HOME/.tinyaiteam/config.sh"

# --- Validation ---

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "ERROR: OPENAI_API_KEY not set" >&2
  exit 1
fi

if [ ! -d "$TAT_DIR" ]; then
  echo "ERROR: No .tat/ directory found. Run from a TAT-enabled project root." >&2
  exit 1
fi

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
if [ -z "$CURRENT_BRANCH" ]; then
  echo "ERROR: Not in a git repository" >&2
  exit 1
fi

if [ "$CURRENT_BRANCH" = "$BASE_BRANCH" ]; then
  echo "ERROR: You're on $BASE_BRANCH. Switch to a task branch first." >&2
  exit 1
fi

# --- Load config ---

# Defaults — config.sh and env vars can override
[ -f "$CONFIG" ] && source "$CONFIG"
TAT_GPT_MODEL="${TAT_GPT_MODEL:-gpt-4o-mini}"
TAT_GPT_SYNOPSIS_MODEL="${TAT_GPT_SYNOPSIS_MODEL:-gpt-4o-mini}"

# --- Capture diff ---

DIFF=$(git diff "$BASE_BRANCH"...HEAD 2>/dev/null || git diff HEAD)
UNSTAGED=$(git diff 2>/dev/null)
UNTRACKED_FILES=$(git ls-files --others --exclude-standard)
UNTRACKED_CONTENT=""

if [ -n "$UNTRACKED_FILES" ]; then
  while IFS= read -r f; do
    # Only include text files, skip binaries
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

# --- Read current task ---

CURRENT_TASK=""
CURRENT_EPIC=""
if [ -f "$TAT_DIR/plan.md" ]; then
  # Priority: find in-progress [~] first, then first todo [ ]
  CURRENT_TASK=$(grep -m1 -E '^\s*- \[~\]' "$TAT_DIR/plan.md" || true)
  if [ -z "$CURRENT_TASK" ]; then
    CURRENT_TASK=$(grep -m1 -E '^\s*- \[ \]' "$TAT_DIR/plan.md" || echo "No active task found")
  fi
  # Find which epic the current task belongs to (nearest ## heading above it)
  if [ -n "$CURRENT_TASK" ]; then
    TASK_LINE=$(grep -n -m1 -F "$CURRENT_TASK" "$TAT_DIR/plan.md" | cut -d: -f1)
    if [ -n "$TASK_LINE" ]; then
      CURRENT_EPIC=$(head -n "$TASK_LINE" "$TAT_DIR/plan.md" | grep -E '^## ' | tail -1 || true)
    fi
  fi
fi

# --- Read spec excerpt ---

SPEC_EXCERPT=""
if [ -f "$TAT_DIR/spec.md" ]; then
  SPEC_EXCERPT=$(head -20 "$TAT_DIR/spec.md")
fi

# --- Detect scope (files changed) ---

FILES_CHANGED=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || git diff --name-only HEAD)
if [ -n "$UNSTAGED" ]; then
  UNSTAGED_FILES=$(git diff --name-only)
  FILES_CHANGED=$(printf '%s\n%s' "$FILES_CHANGED" "$UNSTAGED_FILES" | sort -u)
fi
if [ -n "$UNTRACKED_FILES" ]; then
  FILES_CHANGED=$(printf '%s\n%s' "$FILES_CHANGED" "$UNTRACKED_FILES" | sort -u)
fi

# --- Decide tier ---

if [ "$DIFF_LINES" -lt 50 ]; then
  TIER="synopsis"
  MODEL="$TAT_GPT_SYNOPSIS_MODEL"
  echo "Review tier: SYNOPSIS ($DIFF_LINES lines, using $MODEL)"
else
  TIER="full"
  MODEL="$TAT_GPT_MODEL"
  echo "Review tier: FULL BUNDLE ($DIFF_LINES lines, using $MODEL)"
fi

# --- Build prompt ---

SYSTEM_PROMPT="You are a senior code reviewer on a small engineering team. You review diffs against a stated task scope.

Your job:
1. Does the code actually accomplish the stated task?
2. Are there bugs, edge cases, or security issues?
3. Does the diff touch files or concerns OUTSIDE the stated scope? Flag scope creep.
4. Is anything missing that the task requires?
5. Is the code unnecessarily complex?

Be specific. Cite file names and line numbers. No flattery. If it looks good, say so briefly and move on.

End your review with:
VERDICT: APPROVED or VERDICT: CHANGES_NEEDED"

if [ "$TIER" = "synopsis" ]; then
  USER_PROMPT="## Epic
${CURRENT_EPIC:-Unknown}

## Task
$CURRENT_TASK

## Branch
$CURRENT_BRANCH (based on $BASE_BRANCH)

## Files Changed
$FILES_CHANGED

## Summary
Small change ($DIFF_LINES lines). Quick sanity check requested.

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

echo ""
echo "Sending to $MODEL..."
echo "---"

# Escape the prompts for JSON
SYSTEM_JSON=$(printf '%s' "$SYSTEM_PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')
USER_JSON=$(printf '%s' "$USER_PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"messages\": [
      {\"role\": \"system\", \"content\": $SYSTEM_JSON},
      {\"role\": \"user\", \"content\": $USER_JSON}
    ],
    \"temperature\": 0.3
  }")

# Extract the response content
REVIEW=$(echo "$RESPONSE" | python3 -c 'import sys,json; r=json.load(sys.stdin); print(r["choices"][0]["message"]["content"])' 2>/dev/null)

if [ -z "$REVIEW" ]; then
  echo "ERROR: Failed to get response from GPT" >&2
  echo "Raw response: $RESPONSE" >&2
  exit 1
fi

echo "$REVIEW"
echo ""
echo "---"

# Extract verdict
if echo "$REVIEW" | grep -q "VERDICT: APPROVED"; then
  echo "RESULT: APPROVED"
elif echo "$REVIEW" | grep -q "VERDICT: CHANGES_NEEDED"; then
  echo "RESULT: CHANGES_NEEDED"
else
  echo "RESULT: NO CLEAR VERDICT"
fi
