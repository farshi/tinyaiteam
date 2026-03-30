#!/bin/bash
# tat-state.sh — Machine-readable project state manager for TAT
# Usage:
#   tat-state.sh init               — Create .tat/state.json with IDLE defaults
#   tat-state.sh get <field>        — Read a field (dot notation, e.g. last_action.type)
#   tat-state.sh set <field> <val>  — Set a field value
#   tat-state.sh transition <phase> — Set phase + update timestamps
#   tat-state.sh show               — Pretty-print current state

set -euo pipefail

# --- Constants ---

VALID_PHASES="IDLE PLAN CODE REVIEW SHIP POST-MERGE"

# --- Resolve project root and state file ---

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STATE_FILE="$PROJECT_ROOT/.tat/state.json"

# --- Helpers ---

_require_jq() {
  if ! command -v jq &>/dev/null; then
    echo "[TAT] ERROR: jq is required but not installed. Install it with: brew install jq" >&2
    exit 1
  fi
}

_require_state() {
  if [ ! -f "$STATE_FILE" ]; then
    echo "[TAT] ERROR: $STATE_FILE not found. Run: tat-state.sh init" >&2
    exit 1
  fi
}

_now_iso8601() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

_read_project_name() {
  local spec="$PROJECT_ROOT/.tat/spec.md"
  if [ -f "$spec" ]; then
    grep -m1 '^# ' "$spec" | sed 's/^# //'
  else
    echo "Unknown Project"
  fi
}

# --- Subcommands ---

cmd_init() {
  _require_jq
  local project_name
  project_name=$(_read_project_name)

  if [ -f "$STATE_FILE" ]; then
    echo "[TAT] state.json already exists at $STATE_FILE"
    echo "[TAT] Delete it manually if you want to reinitialize."
    exit 0
  fi

  mkdir -p "$PROJECT_ROOT/.tat"

  jq -n \
    --arg project "$project_name" \
    '{
      version: 1,
      project: $project,
      phase: "IDLE",
      epic: null,
      task: null,
      task_id: null,
      branch: null,
      last_action: {
        type: null,
        model: null,
        timestamp: null
      },
      session: {
        model: null,
        started_at: null,
        updated_at: null
      }
    }' > "$STATE_FILE"

  echo "[TAT] Initialized $STATE_FILE"
  echo "[TAT] Project: $project_name | Phase: IDLE"
}

cmd_get() {
  _require_jq
  _require_state

  if [ $# -lt 1 ]; then
    echo "[TAT] Usage: tat-state.sh get <field>" >&2
    echo "[TAT] Example: tat-state.sh get last_action.type" >&2
    exit 1
  fi

  local field="$1"
  jq -r ".$field" "$STATE_FILE"
}

cmd_set() {
  _require_jq
  _require_state

  if [ $# -lt 2 ]; then
    echo "[TAT] Usage: tat-state.sh set <field> <value>" >&2
    echo "[TAT] Example: tat-state.sh set branch tat/8/state-json" >&2
    exit 1
  fi

  local field="$1"
  local value="$2"

  local updated
  updated=$(jq --arg val "$value" ".$field = \$val" "$STATE_FILE")
  echo "$updated" > "$STATE_FILE"
  echo "[TAT] Set $field = $value"
}

cmd_transition() {
  _require_jq
  _require_state

  if [ $# -lt 1 ]; then
    echo "[TAT] Usage: tat-state.sh transition <phase>" >&2
    echo "[TAT] Valid phases: $VALID_PHASES" >&2
    exit 1
  fi

  local phase="$1"

  # Validate phase
  local valid=0
  for p in $VALID_PHASES; do
    if [ "$phase" = "$p" ]; then
      valid=1
      break
    fi
  done

  if [ "$valid" -eq 0 ]; then
    echo "[TAT] ERROR: Invalid phase '$phase'" >&2
    echo "[TAT] Valid phases: $VALID_PHASES" >&2
    exit 1
  fi

  local now
  now=$(_now_iso8601)

  local updated
  updated=$(jq \
    --arg phase "$phase" \
    --arg ts "$now" \
    '.phase = $phase
    | .last_action.type = $phase
    | .last_action.timestamp = $ts
    | .session.updated_at = $ts' \
    "$STATE_FILE")
  echo "$updated" > "$STATE_FILE"

  echo "[TAT] Transitioned to $phase at $now"
}

cmd_show() {
  _require_jq
  _require_state
  jq '.' "$STATE_FILE"
}

usage() {
  cat >&2 <<'EOF'
[TAT] tat-state.sh — TAT project state manager

Usage:
  tat-state.sh init               Create .tat/state.json with IDLE defaults
  tat-state.sh get <field>        Read a field (dot notation: last_action.type)
  tat-state.sh set <field> <val>  Set a field value
  tat-state.sh transition <phase> Set phase + update timestamps
  tat-state.sh show               Pretty-print current state

Valid phases: IDLE PLAN CODE REVIEW SHIP POST-MERGE
EOF
  exit 1
}

# --- Dispatch ---

if [ $# -lt 1 ]; then
  usage
fi

SUBCOMMAND="$1"
shift

case "$SUBCOMMAND" in
  init)       cmd_init "$@" ;;
  get)        cmd_get "$@" ;;
  set)        cmd_set "$@" ;;
  transition) cmd_transition "$@" ;;
  show)       cmd_show "$@" ;;
  *)
    echo "[TAT] ERROR: Unknown subcommand '$SUBCOMMAND'" >&2
    usage
    ;;
esac
