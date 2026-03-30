#!/bin/bash
# tat-gpt.sh — Shared GPT API caller for TAT review scripts
# Usage: source this file, then call tat_gpt_call "$MODEL" "$SYSTEM_PROMPT" "$USER_PROMPT"
# Returns: sets $REVIEW variable with the GPT response text

tat_gpt_call() {
  local MODEL="$1"
  local SYSTEM_PROMPT="$2"
  local USER_PROMPT="$3"

  local TMPFILE PAYLOAD_FILE SYSTEM_FILE USER_FILE
  TMPFILE=$(mktemp)
  PAYLOAD_FILE=$(mktemp)
  SYSTEM_FILE=$(mktemp)
  USER_FILE=$(mktemp)
  trap "rm -f '$TMPFILE' '$PAYLOAD_FILE' '$SYSTEM_FILE' '$USER_FILE'" EXIT

  # Detect endpoint: some models only work with v1/responses
  local RESPONSES_ONLY_MODELS="gpt-5.4-pro gpt-5.2-codex"
  local USE_RESPONSES=false
  for rm in $RESPONSES_ONLY_MODELS; do
    [ "$MODEL" = "$rm" ] && USE_RESPONSES=true
  done

  # Write prompts to temp files to avoid shell escaping issues.
  # Python reads from files — no shell interpolation can mangle the content.
  printf '%s' "$SYSTEM_PROMPT" > "$SYSTEM_FILE"
  printf '%s' "$USER_PROMPT" > "$USER_FILE"

  if [ "$USE_RESPONSES" = true ]; then
    # Build the full JSON payload in Python — safe from shell escaping
    python3 -c '
import json, sys
with open(sys.argv[1]) as f:
    system = f.read()
with open(sys.argv[2]) as f:
    user = f.read()
combined = system + "\n\n" + user
payload = json.dumps({"model": sys.argv[3], "input": combined})
with open(sys.argv[4], "w") as f:
    f.write(payload)
' "$SYSTEM_FILE" "$USER_FILE" "$MODEL" "$PAYLOAD_FILE"

    curl -s https://api.openai.com/v1/responses \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -H "Content-Type: application/json" \
      -d "@$PAYLOAD_FILE" > "$TMPFILE"

    REVIEW=$(python3 -c '
import sys, json
with open(sys.argv[1]) as f:
    r = json.load(f)
for item in r.get("output", []):
    if item.get("type") == "message":
        for content in item.get("content", []):
            if content.get("type") == "output_text":
                print(content["text"])
                sys.exit(0)
print("")
' "$TMPFILE" 2>/dev/null)
  else
    # Build the full JSON payload in Python — safe from shell escaping
    python3 -c '
import json, sys
with open(sys.argv[1]) as f:
    system = f.read()
with open(sys.argv[2]) as f:
    user = f.read()
payload = json.dumps({
    "model": sys.argv[3],
    "messages": [
        {"role": "system", "content": system},
        {"role": "user", "content": user}
    ],
    "temperature": 0.3
})
with open(sys.argv[4], "w") as f:
    f.write(payload)
' "$SYSTEM_FILE" "$USER_FILE" "$MODEL" "$PAYLOAD_FILE"

    curl -s https://api.openai.com/v1/chat/completions \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -H "Content-Type: application/json" \
      -d "@$PAYLOAD_FILE" > "$TMPFILE"

    REVIEW=$(python3 -c '
import sys, json
with open(sys.argv[1]) as f:
    r = json.load(f)
print(r["choices"][0]["message"]["content"])
' "$TMPFILE" 2>/dev/null)
  fi

  if [ -z "$REVIEW" ]; then
    echo "[TAT] ERROR: Failed to get response from GPT" >&2
    echo "Raw response:" >&2
    cat "$TMPFILE" >&2
    return 1
  fi
}
