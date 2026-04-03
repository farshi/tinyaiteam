#!/bin/bash
# tat-gpt-watch.sh — Background GPT reviewer for TAT v2
# Triggered by Claude Code PostToolUse hook after commits.
# Reads unseen conversation entries + diff, writes GPT responses back.
#
# Usage: tat-gpt-watch.sh [project-root]

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$HOME/.tinyaiteam/config.sh"
PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TAT_DIR="$PROJECT_ROOT/.tat"
CURSOR_FILE="$TAT_DIR/gpt-cursor"
CONVO_FILE="$TAT_DIR/conversation.md"

# --- Validation ---

if [ -z "${OPENAI_API_KEY:-}" ]; then
  exit 0
fi

if [ ! -d "$TAT_DIR" ]; then
  exit 0
fi

cd "$PROJECT_ROOT"

BRANCH=$(git branch --show-current 2>/dev/null || true)
if [ -z "$BRANCH" ] || [ "$BRANCH" = "main" ]; then
  exit 0
fi

# --- Load config + GPT caller ---

[ -f "$CONFIG" ] && source "$CONFIG"
source "$SCRIPT_DIR/tat-gpt.sh"

MODEL="${TAT_CODE_REVIEW_MODEL:-gpt-5.2-codex}"
export TAT_GPT_TIMEOUT=300

# --- Read unseen conversation entries ---

LAST_SEEN=0
[ -f "$CURSOR_FILE" ] && LAST_SEEN=$(cat "$CURSOR_FILE" 2>/dev/null || echo "0")

UNSEEN_ENTRIES=""
if [ -f "$CONVO_FILE" ]; then
  # Extract entries with ID > LAST_SEEN that don't have a **GPT:** line yet
  UNSEEN_ENTRIES=$(python3 -c "
import re, sys
last_seen = int(sys.argv[1])
with open(sys.argv[2]) as f:
    content = f.read()
entries = re.split(r'(?=^### #)', content, flags=re.MULTILINE)
unseen = []
max_id = last_seen
for entry in entries:
    m = re.match(r'### #(\d+)', entry)
    if m:
        eid = int(m.group(1))
        if eid > last_seen and '**GPT:**' not in entry:
            unseen.append(entry.strip())
            max_id = max(max_id, eid)
if unseen:
    print('\n\n'.join(unseen))
    print(f'\n__MAX_ID__:{max_id}')
" "$LAST_SEEN" "$CONVO_FILE" 2>/dev/null || true)
fi

# --- Check if there's anything to review ---

DIFF_LINES=$(git diff main...HEAD 2>/dev/null | wc -l | tr -d ' ' || echo "0")
RISKY_FILES=$(git diff --name-only main...HEAD 2>/dev/null | grep -E '(auth|security|schema|migration|hook|deploy|\.env|config)' || true)
HAS_ALERT=$(echo "$UNSEEN_ENTRIES" | grep -c '⚠️' || true)

# Need at least one reason to call GPT
if [ -z "$UNSEEN_ENTRIES" ] && [ "$DIFF_LINES" -lt 30 ] && [ -z "$RISKY_FILES" ]; then
  exit 0
fi

# --- Gather context ---

SPEC=""
[ -f "$TAT_DIR/spec.md" ] && SPEC=$(head -20 "$TAT_DIR/spec.md")

DECISIONS=""
[ -f "$TAT_DIR/decisions.md" ] && DECISIONS=$(cat "$TAT_DIR/decisions.md")

PLAN=""
[ -f "$TAT_DIR/plan.md" ] && PLAN=$(grep -E '^\|.*\[ \]' "$TAT_DIR/plan.md" | head -5)

FILES_CHANGED=$(git diff --name-only main...HEAD 2>/dev/null || true)
TRIMMED_DIFF=$(git diff main...HEAD 2>/dev/null | head -300 || true)

# --- Call GPT ---

SYSTEM_PROMPT="You are a senior engineer watching a Claude Code session. You see both the conversation (what was discussed/decided) and the code (diffs).

Your job:
1. Review each conversation entry — is the approach sound? Did Claude miss anything?
2. If there's a code diff, check for bugs, security issues, scope creep.
3. Check if current work contradicts any project decisions.
4. If you see user corrections, note the pattern.
5. ⚠️ entries are urgent — address these first.

Respond with one **GPT:** line per conversation entry (short, specific).
Then a brief overall section if there's a code diff.

Format:
ENTRY #<id>: <your comment>
ENTRY #<id>: <your comment>

DIFF REVIEW: (if applicable)
- <observation>

CONFIDENCE: HIGH / MEDIUM / LOW"

USER_PROMPT="Project: $SPEC

Decisions: $DECISIONS

Current tasks: $PLAN

--- UNSEEN CONVERSATION ---
$UNSEEN_ENTRIES

--- CODE CHANGES ---
Files: $FILES_CHANGED
Diff ($DIFF_LINES lines, first 300):
$TRIMMED_DIFF"

tat_gpt_call "$MODEL" "$SYSTEM_PROMPT" "$USER_PROMPT" 2>/dev/null || exit 0

# --- Write GPT responses back into conversation.md ---

if [ -n "$REVIEW" ] && [ -f "$CONVO_FILE" ]; then
  # Extract per-entry responses and append to conversation.md
  python3 -c "
import re, sys

review = sys.argv[1]
convo_path = sys.argv[2]

with open(convo_path) as f:
    content = f.read()

# Parse GPT responses per entry
for match in re.finditer(r'ENTRY #(\d+):\s*(.+)', review):
    eid = match.group(1)
    comment = match.group(2).strip()
    # Find the entry and append GPT line if not already there
    pattern = rf'(### #{eid}\b[^\n]*\n(?:(?!### #).)*)'
    def add_gpt(m):
        block = m.group(1)
        if '**GPT:**' not in block:
            return block.rstrip() + f'\n**GPT:** {comment}\n'
        return block
    content = re.sub(pattern, add_gpt, content, flags=re.DOTALL)

with open(convo_path, 'w') as f:
    f.write(content)
" "$REVIEW" "$CONVO_FILE" 2>/dev/null

  # Update cursor to max seen ID
  MAX_ID=$(echo "$UNSEEN_ENTRIES" | grep -o '__MAX_ID__:[0-9]*' | cut -d: -f2 || true)
  if [ -n "$MAX_ID" ]; then
    echo "$MAX_ID" > "$CURSOR_FILE"
  fi
fi

# --- Also write a summary to gpt.md for quick reference ---

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat > "$TAT_DIR/gpt.md" <<GPTEOF
# GPT Review

**Date:** $TIMESTAMP
**Branch:** $BRANCH
**Model:** $MODEL
**Entries reviewed:** $(echo "$UNSEEN_ENTRIES" | grep -c '### #' || echo "0")
**Diff:** $DIFF_LINES lines

$REVIEW
GPTEOF
