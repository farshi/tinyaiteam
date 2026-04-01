#!/bin/bash
# tat-gpt.sh — Shared GPT API caller for TAT review scripts
# Usage: source this file, then call tat_gpt_call "$MODEL" "$SYSTEM_PROMPT" "$USER_PROMPT"
# Returns: sets $REVIEW variable with the GPT response text

TAT_GPT_MAX_RETRIES="${TAT_GPT_MAX_RETRIES:-3}"
TAT_GPT_TIMEOUT="${TAT_GPT_TIMEOUT:-60}"

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
  local RESPONSES_ONLY_MODELS="gpt-5.4-pro gpt-5.2-codex gpt-5.3-codex"
  local USE_RESPONSES=false
  for rm in $RESPONSES_ONLY_MODELS; do
    [ "$MODEL" = "$rm" ] && USE_RESPONSES=true
  done

  # Write prompts to temp files to avoid shell escaping issues.
  # Python reads from files — no shell interpolation can mangle the content.
  printf '%s' "$SYSTEM_PROMPT" > "$SYSTEM_FILE"
  printf '%s' "$USER_PROMPT" > "$USER_FILE"

  local ENDPOINT URL
  if [ "$USE_RESPONSES" = true ]; then
    ENDPOINT="responses"
    URL="https://api.openai.com/v1/responses"

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
  else
    ENDPOINT="chat"
    URL="https://api.openai.com/v1/chat/completions"

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
  fi

  # Retry loop with exponential backoff
  local ATTEMPT=0
  local BACKOFF=2
  REVIEW=""

  while [ "$ATTEMPT" -lt "$TAT_GPT_MAX_RETRIES" ]; do
    ATTEMPT=$((ATTEMPT + 1))

    # Call API with timeout and capture HTTP status
    local HTTP_STATUS
    HTTP_STATUS=$(curl -s -o "$TMPFILE" -w "%{http_code}" \
      --max-time "$TAT_GPT_TIMEOUT" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -H "Content-Type: application/json" \
      -d "@$PAYLOAD_FILE" \
      "$URL" 2>/dev/null) || HTTP_STATUS="000"

    # Parse response based on endpoint
    if [ "$HTTP_STATUS" = "200" ]; then
      if [ "$ENDPOINT" = "responses" ]; then
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
        REVIEW=$(python3 -c '
import sys, json
with open(sys.argv[1]) as f:
    r = json.load(f)
print(r["choices"][0]["message"]["content"])
' "$TMPFILE" 2>/dev/null)
      fi

      if [ -n "$REVIEW" ]; then
        return 0
      fi
    fi

    # Decide whether to retry based on status
    case "$HTTP_STATUS" in
      429|500|502|503|504|000)
        # Retryable: rate limit, server error, timeout, network failure
        if [ "$ATTEMPT" -lt "$TAT_GPT_MAX_RETRIES" ]; then
          echo "[TAT] GPT API error (HTTP $HTTP_STATUS), retrying in ${BACKOFF}s... (attempt $ATTEMPT/$TAT_GPT_MAX_RETRIES)" >&2
          sleep "$BACKOFF"
          BACKOFF=$((BACKOFF * 2))
        fi
        ;;
      *)
        # Non-retryable: auth error, bad request, etc.
        echo "[TAT] ERROR: GPT API returned HTTP $HTTP_STATUS (non-retryable)" >&2
        cat "$TMPFILE" >&2
        return 1
        ;;
    esac
  done

  # All retries exhausted
  echo "[TAT] ERROR: GPT API failed after $TAT_GPT_MAX_RETRIES attempts (last HTTP $HTTP_STATUS)" >&2
  echo "Last response:" >&2
  cat "$TMPFILE" >&2
  return 1
}
