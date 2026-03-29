#!/bin/bash
# tat-review.sh — Send current work to GPT for structured review
# Usage: tat-review.sh [--plan] [base-branch]
#   --plan    Review the plan (spec + plan.md), not code
#   base      Base branch to diff against (default: main)

set -euo pipefail

# --- Parse args ---

REVIEW_MODE="code"
BASE_BRANCH="main"

for arg in "$@"; do
  case "$arg" in
    --plan) REVIEW_MODE="plan" ;;
    *) BASE_BRANCH="$arg" ;;
  esac
done

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

# --- Load config ---

[ -f "$CONFIG" ] && source "$CONFIG"
TAT_GPT_MODEL="${TAT_GPT_MODEL:-gpt-4o-mini}"
TAT_GPT_SYNOPSIS_MODEL="${TAT_GPT_SYNOPSIS_MODEL:-gpt-4o-mini}"

# --- Shared: read current task + epic ---

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

# --- Shared: advisor response format ---

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

# ============================================================
# PLAN REVIEW MODE
# ============================================================

if [ "$REVIEW_MODE" = "plan" ]; then
  echo "[TAT] Review mode: PLAN"
  MODEL="$TAT_GPT_MODEL"

  SPEC_CONTENT=""
  [ -f "$TAT_DIR/spec.md" ] && SPEC_CONTENT=$(cat "$TAT_DIR/spec.md")

  PLAN_CONTENT=""
  [ -f "$TAT_DIR/plan.md" ] && PLAN_CONTENT=$(cat "$TAT_DIR/plan.md")

  # Collect decision records
  DECISIONS=""
  if [ -d "$TAT_DIR/decisions" ]; then
    for f in "$TAT_DIR/decisions/"*.md; do
      [ -f "$f" ] && DECISIONS="${DECISIONS}
--- $(basename "$f") ---
$(cat "$f")
"
    done
  fi

  SYSTEM_PROMPT="You are a senior engineering advisor reviewing a project plan. You are NOT a gatekeeper — you are a second opinion. The human decides what to act on.

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

  echo "[TAT] Sending spec + plan + decisions to $MODEL..."
  echo "---"

# ============================================================
# CODE REVIEW MODE
# ============================================================

else
  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
  if [ -z "$CURRENT_BRANCH" ]; then
    echo "[TAT] ERROR: Not in a git repository" >&2
    exit 1
  fi

  if [ "$CURRENT_BRANCH" = "$BASE_BRANCH" ]; then
    echo "[TAT] ERROR: You're on $BASE_BRANCH. Switch to a task branch first." >&2
    exit 1
  fi

  # Capture diff
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

  # Detect scope
  FILES_CHANGED=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || git diff --name-only HEAD)
  if [ -n "$UNSTAGED" ]; then
    UNSTAGED_FILES=$(git diff --name-only)
    FILES_CHANGED=$(printf '%s\n%s' "$FILES_CHANGED" "$UNSTAGED_FILES" | sort -u)
  fi
  if [ -n "$UNTRACKED_FILES" ]; then
    FILES_CHANGED=$(printf '%s\n%s' "$FILES_CHANGED" "$UNTRACKED_FILES" | sort -u)
  fi

  # Read spec excerpt
  SPEC_EXCERPT=""
  [ -f "$TAT_DIR/spec.md" ] && SPEC_EXCERPT=$(head -20 "$TAT_DIR/spec.md")

  # Decide tier
  if [ "$DIFF_LINES" -lt 50 ]; then
    TIER="synopsis"
    MODEL="$TAT_GPT_SYNOPSIS_MODEL"
    echo "[TAT] Review tier: SYNOPSIS ($DIFF_LINES lines, using $MODEL)"
  else
    TIER="full"
    MODEL="$TAT_GPT_MODEL"
    echo "[TAT] Review tier: FULL BUNDLE ($DIFF_LINES lines, using $MODEL)"
  fi

  SYSTEM_PROMPT="You are a senior code reviewer. You are NOT a gatekeeper — you are a second opinion. The human decides what to act on.

Your job:
1. Does the code accomplish the stated task?
2. Are there bugs, edge cases, or security issues?
3. Does the diff touch files OUTSIDE the stated scope? Flag scope creep.
4. Is anything missing that the task requires?
5. Is the code unnecessarily complex?

$ADVISOR_FORMAT"

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

  echo "[TAT] Sending to $MODEL..."
  echo "---"
fi

# ============================================================
# CALL GPT
# ============================================================

# Detect endpoint: some models only work with v1/responses, not v1/chat/completions
RESPONSES_ONLY_MODELS="gpt-5.4-pro gpt-5.2-codex"
USE_RESPONSES=false
for rm in $RESPONSES_ONLY_MODELS; do
  [ "$MODEL" = "$rm" ] && USE_RESPONSES=true
done

SYSTEM_JSON=$(printf '%s' "$SYSTEM_PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')
USER_JSON=$(printf '%s' "$USER_PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')

if [ "$USE_RESPONSES" = true ]; then
  # Responses API — for models that don't support chat completions
  COMBINED="$SYSTEM_PROMPT

$USER_PROMPT"
  COMBINED_JSON=$(printf '%s' "$COMBINED" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')

  RESPONSE=$(curl -s https://api.openai.com/v1/responses \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"$MODEL\",
      \"input\": $COMBINED_JSON
    }")

  REVIEW=$(echo "$RESPONSE" | python3 -c '
import sys, json
r = json.load(sys.stdin)
# Extract text from responses API output
for item in r.get("output", []):
    if item.get("type") == "message":
        for content in item.get("content", []):
            if content.get("type") == "output_text":
                print(content["text"])
                sys.exit(0)
print("")
' 2>/dev/null)
else
  # Chat completions API
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

  REVIEW=$(echo "$RESPONSE" | python3 -c 'import sys,json; r=json.load(sys.stdin); print(r["choices"][0]["message"]["content"])' 2>/dev/null)
fi

if [ -z "$REVIEW" ]; then
  echo "[TAT] ERROR: Failed to get response from GPT" >&2
  echo "Raw response: $RESPONSE" >&2
  exit 1
fi

echo ""
echo "[GPT] Review ($REVIEW_MODE):"
echo ""
echo "$REVIEW"
echo ""
echo "---"

# Check blockers
if echo "$REVIEW" | grep -A5 -iE '^BLOCKERS:' | grep -qi 'none'; then
  echo "[TAT] No blockers. Proceed at your discretion."
else
  echo "[TAT] Blockers found — review above and decide what to act on."
fi
