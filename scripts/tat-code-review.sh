#!/bin/bash
# tat-code-review.sh — Send code diff to GPT for structured review
# Usage: tat-code-review.sh [base-branch] [--task TAT-XXX]
#   base-branch  Branch to diff against (default: main)
#   --task       Explicit task ID to review against (most reliable)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAT_DIR=".tat"
CONFIG="$HOME/.tinyaiteam/config.sh"
BASE_BRANCH="main"
EXPLICIT_TASK=""

# Parse args: positional base-branch and --task flag
while [ $# -gt 0 ]; do
  case "$1" in
    --task) EXPLICIT_TASK="$2"; shift 2 ;;
    *) BASE_BRANCH="$1"; shift ;;
  esac
done

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
# Priority: --task arg → state.json → branch name match → first [ ] in plan

CURRENT_TASK=""
CURRENT_EPIC=""
TASK_SOURCE=""

if [ -f "$TAT_DIR/plan.md" ]; then
  # 1. Explicit --task arg (most reliable)
  if [ -n "$EXPLICIT_TASK" ]; then
    CURRENT_TASK=$(grep -m1 "| *$EXPLICIT_TASK *|" "$TAT_DIR/plan.md" || true)
    [ -n "$CURRENT_TASK" ] && TASK_SOURCE="--task arg"
  fi

  # 2. state.json task_id
  if [ -z "$CURRENT_TASK" ] && [ -f "$TAT_DIR/state.json" ]; then
    STATE_TASK_ID=$(python3 -c "import json; d=json.load(open('$TAT_DIR/state.json')); print(d.get('task_id',''))" 2>/dev/null || true)
    if [ -n "$STATE_TASK_ID" ]; then
      CURRENT_TASK=$(grep -m1 "| *$STATE_TASK_ID *|" "$TAT_DIR/plan.md" || true)
      [ -n "$CURRENT_TASK" ] && TASK_SOURCE="state.json"
    fi
  fi

  # 3. Branch name match (e.g., tat/19/wrapup → search plan for matching task)
  if [ -z "$CURRENT_TASK" ]; then
    BRANCH_NAME=$(git branch --show-current 2>/dev/null || true)
    if [ -n "$BRANCH_NAME" ] && [ "$BRANCH_NAME" != "$BASE_BRANCH" ]; then
      # Extract last segment of branch name as keyword
      BRANCH_KEYWORD=$(echo "$BRANCH_NAME" | sed 's|.*/||' | tr '-' ' ')
      if [ -n "$BRANCH_KEYWORD" ]; then
        BRANCH_MATCH=$(grep -i -m1 "|.*$BRANCH_KEYWORD" "$TAT_DIR/plan.md" || true)
        [ -n "$BRANCH_MATCH" ] && CURRENT_TASK="$BRANCH_MATCH" && TASK_SOURCE="branch name"
      fi
    fi
  fi

  # 4. Fallback: first in-progress or unchecked task (skip Backlog)
  if [ -z "$CURRENT_TASK" ]; then
    CURRENT_TASK=$(grep -m1 '|.*\[~\]' "$TAT_DIR/plan.md" || true)
    [ -n "$CURRENT_TASK" ] && TASK_SOURCE="first [~]"
  fi
  if [ -z "$CURRENT_TASK" ]; then
    EPIC_SECTION=$(sed '/^## Backlog/,$d' "$TAT_DIR/plan.md")
    CURRENT_TASK=$(echo "$EPIC_SECTION" | grep -m1 '|.*\[ \]' || true)
    [ -n "$CURRENT_TASK" ] && TASK_SOURCE="first [ ]"
  fi
  # Checkbox fallback (pre-Sprint 5)
  if [ -z "$CURRENT_TASK" ]; then
    CURRENT_TASK=$(grep -m1 '\- \[~\]' "$TAT_DIR/plan.md" || true)
    [ -n "$CURRENT_TASK" ] && TASK_SOURCE="checkbox [~]"
  fi
  if [ -z "$CURRENT_TASK" ]; then
    EPIC_SECTION=$(sed '/^## Backlog/,$d' "$TAT_DIR/plan.md")
    CURRENT_TASK=$(echo "$EPIC_SECTION" | grep -m1 '\- \[ \]' || echo "No active task found")
    TASK_SOURCE="checkbox [ ]"
  fi

  # Find the enclosing sprint/epic heading
  if [ -n "$CURRENT_TASK" ]; then
    TASK_LINE=$(grep -n -m1 -F -- "$CURRENT_TASK" "$TAT_DIR/plan.md" | cut -d: -f1 || true)
    if [ -n "$TASK_LINE" ]; then
      CURRENT_EPIC=$(head -n "$TASK_LINE" "$TAT_DIR/plan.md" | grep -E '^##+ ' | tail -1 || true)
    fi
  fi
fi

[ -n "$TASK_SOURCE" ] && echo "[TAT] Task detected via: $TASK_SOURCE"

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

# --- Project context (trimmed — send summary, not full spec) ---

SPEC_SUMMARY=""
if [ -f "$TAT_DIR/spec.md" ]; then
  # Extract project name (first heading) + first paragraph (what it does)
  SPEC_SUMMARY=$(awk '
    /^#/ && !found_title { found_title=1; print; next }
    found_title && /^##/ && !found_section { found_section=1; print; next }
    found_section && /^$/ && got_content { exit }
    found_section { got_content=1; print }
  ' "$TAT_DIR/spec.md" | head -10)
fi

# Also extract the current task's full description from plan.md
TASK_DESCRIPTION=""
if [ -n "$CURRENT_TASK" ] && [ -f "$TAT_DIR/plan.md" ]; then
  # Get everything from the task heading to the next heading
  # Extract task name from table row or checkbox line
  if echo "$CURRENT_TASK" | grep -q '|'; then
    # Table format: | TAT-XXX | Task name | Epic | Status |
    TASK_HEADING=$(echo "$CURRENT_TASK" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
  else
    # Checkbox format: - [x] Task name
    TASK_HEADING=$(echo "$CURRENT_TASK" | sed 's/^- \[.\] //')
  fi
  TASK_DESCRIPTION=$(awk -v task="$TASK_HEADING" '
    index($0, task) { found=1; print; next }
    found && /^###/ { exit }
    found && /^## / { exit }
    found { print }
  ' "$TAT_DIR/plan.md")
fi

PROJECT_CONTEXT="PROJECT: $SPEC_SUMMARY

CURRENT TASK DETAILS:
$TASK_DESCRIPTION"

SYSTEM_PROMPT="You are a senior code reviewer. You are NOT a gatekeeper — you are a second opinion. The human decides what to act on.

$PROJECT_CONTEXT

Your job:
1. Does the code accomplish the STATED TASK (shown in the Epic and Task fields below)?
2. Are there bugs, edge cases, or security issues?
3. Does the diff touch files OUTSIDE the stated scope? Flag scope creep.
4. Is anything missing that the task requires?
5. Is the code unnecessarily complex?

IMPORTANT:
- Judge the diff ONLY against the Epic and Task shown below. Nothing else.
- The task description may have been updated since it was first written. Trust the current wording.
- Do NOT compare against backlog items, other epics, or earlier task descriptions.

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

# Auto-save GPT review to .tat/gpt.md
GPT_FILE="$TAT_DIR/gpt.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat > "$GPT_FILE" <<GPTEOF
# GPT Review

**Date:** $TIMESTAMP
**Branch:** $CURRENT_BRANCH
**Model:** $MODEL
**Task:** ${CURRENT_TASK:-unknown}
**Diff:** $DIFF_LINES lines

$REVIEW
GPTEOF
echo "[TAT] GPT review saved to $GPT_FILE"

if echo "$REVIEW" | grep -A5 -iE '^BLOCKERS:' | grep -qi 'none'; then
  echo "[TAT] No blockers. Proceed at your discretion."
else
  echo "[TAT] Blockers found — review above and decide what to act on."
fi
