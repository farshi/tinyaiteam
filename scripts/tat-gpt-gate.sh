#!/bin/bash
# tat-gpt-gate.sh — Enforce GPT review after 3+ user turns without GPT input
# Called from PostToolUse hook. Checks session.md, triggers GPT if needed.
#
# Usage: tat-gpt-gate.sh [project-root]

set -u

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
SESSION_FILE="$PROJECT_ROOT/.tat/session.md"
THRESHOLD="${TAT_GPT_GATE_TURNS:-3}"

# --- Validation ---
[ ! -f "$SESSION_FILE" ] && exit 0

# --- Count [User] entries since last [GPT] entry ---

TURNS_SINCE_GPT=$(python3 -c "
import sys

with open(sys.argv[1]) as f:
    lines = f.readlines()

count = 0
for line in reversed(lines):
    line = line.strip()
    if '[GPT]' in line:
        break
    if '[User]' in line:
        count += 1

print(count)
" "$SESSION_FILE" 2>/dev/null || echo "0")

# --- Trigger GPT if threshold met (with lock to prevent concurrent runs) ---

LOCK_FILE="/tmp/tat-gpt-gate.lock"

if [ "$TURNS_SINCE_GPT" -ge "$THRESHOLD" ]; then
  # Prevent concurrent GPT calls from rapid hook fires
  if [ -f "$LOCK_FILE" ]; then
    LOCK_AGE=$(( $(date +%s) - $(cat "$LOCK_FILE") ))
    [ "$LOCK_AGE" -lt 60 ] && exit 0  # Another call running within last minute
  fi
  date +%s > "$LOCK_FILE"
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  "$SCRIPT_DIR/tat-gpt-watch.sh" "$PROJECT_ROOT" &
fi
