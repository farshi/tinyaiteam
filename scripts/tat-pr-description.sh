#!/bin/bash
# tat-pr-description.sh — Generate a PR description from TAT checkpoint artifacts
# Usage: tat-pr-description.sh [base-branch]
#   base-branch  Branch to diff against (default: main)
# Output: prints PR body to stdout
#   gh pr create --title "feat(...): ..." --body "$(scripts/tat-pr-description.sh)"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAT_DIR=".tat"
CONFIG="$HOME/.tinyaiteam/config.sh"
BASE_BRANCH="${1:-main}"

# --- Validation ---

if [ ! -d "$TAT_DIR" ]; then
  echo "[TAT] ERROR: No .tat/ directory found. Run from a TAT-enabled project root." >&2
  exit 1
fi

# --- Load config ---

[ -f "$CONFIG" ] && source "$CONFIG"

# --- Read current task + epic (skip Backlog section) ---

CURRENT_TASK=""
CURRENT_EPIC=""
if [ -f "$TAT_DIR/plan.md" ]; then
  # Try table format first (Sprint 5+): | TAT-XXX | desc | epic | [~] |
  CURRENT_TASK=$(grep -m1 '|.*\[~\]' "$TAT_DIR/plan.md" || true)
  if [ -z "$CURRENT_TASK" ]; then
    # Next unchecked table task (skip Backlog section)
    EPIC_SECTION=$(sed '/^## Backlog/,$d' "$TAT_DIR/plan.md")
    CURRENT_TASK=$(echo "$EPIC_SECTION" | grep -m1 '|.*\[ \]' || true)
  fi
  # Fallback: old checkbox format (pre-Sprint 5)
  if [ -z "$CURRENT_TASK" ]; then
    CURRENT_TASK=$(grep -m1 '\- \[~\]' "$TAT_DIR/plan.md" || true)
  fi
  if [ -z "$CURRENT_TASK" ]; then
    EPIC_SECTION=$(sed '/^## Backlog/,$d' "$TAT_DIR/plan.md")
    CURRENT_TASK=$(echo "$EPIC_SECTION" | grep -m1 '\- \[ \]' || echo "No active task found")
  fi
  # Find the enclosing sprint/epic heading
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
