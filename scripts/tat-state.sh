#!/bin/bash
# tat-state.sh — TAT task ID counter (v2)
# Usage:
#   tat-state.sh init           — Create .tat/state.json with counter
#   tat-state.sh get <field>    — Read a field
#   tat-state.sh new-task-id    — Generate next TAT-XXX ID and increment counter
#
# v2: Phase tracking removed. Git is the source of truth for state.
# Only the task ID counter is managed here.

set -euo pipefail

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STATE_FILE="$PROJECT_ROOT/.tat/state.json"

_require_jq() {
  if ! command -v jq &>/dev/null; then
    echo "[TAT] ERROR: jq is required. Install: brew install jq" >&2
    exit 1
  fi
}

_require_state() {
  if [ ! -f "$STATE_FILE" ]; then
    echo "[TAT] state.json not found — skipping (run tat-state.sh init)" >&2
    return 1
  fi
}

_read_project_name() {
  local spec="$PROJECT_ROOT/.tat/spec.md"
  if [ -f "$spec" ]; then
    grep -m1 '^# ' "$spec" | sed 's/^# //'
  else
    echo "Unknown Project"
  fi
}

cmd_init() {
  _require_jq
  local project_name
  project_name=$(_read_project_name)

  if [ -f "$STATE_FILE" ]; then
    echo "[TAT] state.json already exists at $STATE_FILE"
    exit 0
  fi

  mkdir -p "$PROJECT_ROOT/.tat"

  jq -n \
    --arg project "$project_name" \
    '{
      version: 2,
      project: $project,
      next_task_id: 1
    }' > "$STATE_FILE"

  echo "[TAT] Initialized $STATE_FILE"
  echo "[TAT] Project: $project_name"
}

cmd_get() {
  _require_jq
  _require_state || return 0

  if [ $# -lt 1 ]; then
    echo "[TAT] Usage: tat-state.sh get <field>" >&2
    exit 1
  fi

  jq -r ".$1" "$STATE_FILE"
}

cmd_new_task_id() {
  _require_jq
  _require_state || return 0

  local next_id
  next_id=$(jq -r '.next_task_id // 1' "$STATE_FILE")

  local formatted
  formatted=$(printf "TAT-%03d" "$next_id")

  local updated
  updated=$(jq ".next_task_id = $(( next_id + 1 ))" "$STATE_FILE")
  echo "$updated" > "$STATE_FILE"

  echo "$formatted"
}

# --- Dispatch ---

if [ $# -lt 1 ]; then
  cat >&2 <<'EOF'
[TAT] tat-state.sh — TAT task ID counter (v2)

Usage:
  tat-state.sh init           Create .tat/state.json
  tat-state.sh get <field>    Read a field
  tat-state.sh new-task-id    Generate next TAT-XXX ID

Phase tracking removed in v2. Git is the source of truth.
EOF
  exit 1
fi

SUBCOMMAND="$1"
shift

case "$SUBCOMMAND" in
  init)        cmd_init "$@" ;;
  get)         cmd_get "$@" ;;
  new-task-id) cmd_new_task_id "$@" ;;
  # Deprecated v1 commands — graceful message
  transition|set|show)
    echo "[TAT] '$SUBCOMMAND' removed in v2. Phase tracking is gone — git is the source of truth." >&2
    ;;
  *)
    echo "[TAT] ERROR: Unknown subcommand '$SUBCOMMAND'" >&2
    exit 1
    ;;
esac
