#!/bin/bash
# tat-gpt.sh — Shared GPT API caller for TAT review scripts
# Usage: source this file, then call tat_gpt_call "$MODEL" "$SYSTEM_PROMPT" "$USER_PROMPT"
# Returns: sets $REVIEW variable with the GPT response text

tat_gpt_call() {
  local MODEL="$1"
  local SYSTEM_PROMPT="$2"
  local USER_PROMPT="$3"

  # Detect endpoint: some models only work with v1/responses
  local RESPONSES_ONLY_MODELS="gpt-5.4-pro gpt-5.2-codex"
  local USE_RESPONSES=false
  for rm in $RESPONSES_ONLY_MODELS; do
    [ "$MODEL" = "$rm" ] && USE_RESPONSES=true
  done

  local SYSTEM_JSON USER_JSON RESPONSE

  SYSTEM_JSON=$(printf '%s' "$SYSTEM_PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')
  USER_JSON=$(printf '%s' "$USER_PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')

  if [ "$USE_RESPONSES" = true ]; then
    local COMBINED="$SYSTEM_PROMPT

$USER_PROMPT"
    local COMBINED_JSON
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
for item in r.get("output", []):
    if item.get("type") == "message":
        for content in item.get("content", []):
            if content.get("type") == "output_text":
                print(content["text"])
                sys.exit(0)
print("")
' 2>/dev/null)
  else
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
    return 1
  fi
}
