#!/bin/bash
# tat-pr-description.sh — Generate a PR description from TAT checkpoint artifacts
# Usage: tat-pr-description.sh [base-branch] [--task TAT-XXX]
#   base-branch  Branch to diff against (default: main)
#   --task       Explicit task ID for PR context
# Output: prints PR body to stdout
#   gh pr create --title "feat(...): ..." --body "$(scripts/tat-pr-description.sh)"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAT_DIR=".tat"
CONFIG="$HOME/.tinyaiteam/config.sh"
BASE_BRANCH="main"
EXPLICIT_TASK=""

while [ $# -gt 0 ]; do
  case "$1" in
    --task) EXPLICIT_TASK="$2"; shift 2 ;;
    *) BASE_BRANCH="$1"; shift ;;
  esac
done

# --- Validation ---

if [ ! -d "$TAT_DIR" ]; then
  echo "[TAT] ERROR: No .tat/ directory found. Run from a TAT-enabled project root." >&2
  exit 1
fi

# --- Load config ---

[ -f "$CONFIG" ] && source "$CONFIG"

# --- Read current task + epic ---
# Priority: --task arg → state.json → branch name match → first [ ] in plan

CURRENT_TASK=""
CURRENT_EPIC=""

if [ -f "$TAT_DIR/plan.md" ]; then
  # 1. Explicit --task arg
  if [ -n "$EXPLICIT_TASK" ]; then
    CURRENT_TASK=$(grep -m1 "| *$EXPLICIT_TASK *|" "$TAT_DIR/plan.md" || true)
  fi
  # 2. state.json task_id
  if [ -z "$CURRENT_TASK" ] && [ -f "$TAT_DIR/state.json" ]; then
    STATE_TASK_ID=$(python3 -c "import json; d=json.load(open('$TAT_DIR/state.json')); print(d.get('task_id',''))" 2>/dev/null || true)
    if [ -n "$STATE_TASK_ID" ]; then
      CURRENT_TASK=$(grep -m1 "| *$STATE_TASK_ID *|" "$TAT_DIR/plan.md" || true)
    fi
  fi
  # 3. Branch name match
  if [ -z "$CURRENT_TASK" ]; then
    BRANCH_NAME=$(git branch --show-current 2>/dev/null || true)
    if [ -n "$BRANCH_NAME" ] && [ "$BRANCH_NAME" != "$BASE_BRANCH" ]; then
      BRANCH_KEYWORD=$(echo "$BRANCH_NAME" | sed 's|.*/||' | tr '-' ' ')
      [ -n "$BRANCH_KEYWORD" ] && CURRENT_TASK=$(grep -i -m1 "|.*$BRANCH_KEYWORD" "$TAT_DIR/plan.md" || true)
    fi
  fi
  # 4. Fallback: first [~] or [ ] task
  if [ -z "$CURRENT_TASK" ]; then
    CURRENT_TASK=$(grep -m1 '|.*\[~\]' "$TAT_DIR/plan.md" || true)
  fi
  if [ -z "$CURRENT_TASK" ]; then
    EPIC_SECTION=$(sed '/^## Backlog/,$d' "$TAT_DIR/plan.md")
    CURRENT_TASK=$(echo "$EPIC_SECTION" | grep -m1 '|.*\[ \]' || echo "No active task found")
  fi
  # Find enclosing heading
  if [ -n "$CURRENT_TASK" ]; then
    TASK_LINE=$(grep -n -m1 -F -- "$CURRENT_TASK" "$TAT_DIR/plan.md" | cut -d: -f1 || true)
    if [ -n "$TASK_LINE" ]; then
      CURRENT_EPIC=$(head -n "$TASK_LINE" "$TAT_DIR/plan.md" | grep -E '^##+ ' | tail -1 || true)
    fi
  fi
fi

# --- Read spec context ---

SPEC_SUMMARY=""
if [ -f "$TAT_DIR/spec.md" ]; then
  SPEC_SUMMARY=$(head -5 "$TAT_DIR/spec.md" | grep -E '^\#|^-|^[A-Z]' | head -2 || true)
fi

# --- Gather git info ---

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
if [ -z "$CURRENT_BRANCH" ]; then
  echo "[TAT] ERROR: Not in a git repository" >&2
  exit 1
fi

FILES_CHANGED=$(git diff "origin/$BASE_BRANCH" --name-only 2>/dev/null || git diff --name-only HEAD)
COMMITS=$(git log "origin/$BASE_BRANCH..HEAD" --oneline 2>/dev/null || git log --oneline -10)

# --- Build summary bullets from commits ---

SUMMARY_BULLETS=""
if [ -n "$COMMITS" ]; then
  while IFS= read -r line; do
    # Strip the short SHA prefix (first word)
    MSG="${line#* }"
    SUMMARY_BULLETS="${SUMMARY_BULLETS}- ${MSG}
"
  done <<< "$COMMITS"
else
  SUMMARY_BULLETS="- (no commits found ahead of origin/$BASE_BRANCH)"
fi

# --- Format files changed list ---

FILES_LIST=""
if [ -n "$FILES_CHANGED" ]; then
  while IFS= read -r f; do
    FILES_LIST="${FILES_LIST}- ${f}
"
  done <<< "$FILES_CHANGED"
else
  FILES_LIST="- (no files changed)"
fi

# --- Output PR description ---

cat <<EOF
## Summary
${SUMMARY_BULLETS}
## Task
${CURRENT_EPIC:-Unknown Epic}
${CURRENT_TASK:-No active task found}

## Files Changed
${FILES_LIST}
## GPT Review Response
- (add after running tat-code-review.sh)

## Test plan
- [ ]
EOF
