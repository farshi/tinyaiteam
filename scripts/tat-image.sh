#!/bin/bash
# tat-image.sh — Generate a cover image for an article via DALL-E API
# Usage: tat-image.sh <prompt> [output-path]
#   prompt       The DALL-E prompt describing the image
#   output-path  Where to save the image (default: ./cover.png)

set -euo pipefail

# --- Parse args ---

if [ $# -lt 1 ]; then
  echo "[TAT] Usage: tat-image.sh <prompt> [output-path]" >&2
  exit 1
fi

PROMPT="$1"
OUTPUT="${2:-./cover.png}"

CONFIG="$HOME/.tinyaiteam/config.sh"

# --- Validation ---

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "[TAT] ERROR: OPENAI_API_KEY not set" >&2
  exit 1
fi

# --- Load config ---

[ -f "$CONFIG" ] && source "$CONFIG"
TAT_IMAGE_MODEL="${TAT_IMAGE_MODEL:-dall-e-3}"
TAT_IMAGE_SIZE="${TAT_IMAGE_SIZE:-1792x1024}"
TAT_IMAGE_QUALITY="${TAT_IMAGE_QUALITY:-standard}"

# --- Call DALL-E API ---

echo "[TAT] Generating image with $TAT_IMAGE_MODEL..."
echo "[TAT] Size: $TAT_IMAGE_SIZE | Quality: $TAT_IMAGE_QUALITY"
echo "[TAT] Prompt: ${PROMPT:0:100}..."

PROMPT_JSON=$(printf '%s' "$PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')

RESPONSE=$(curl -s https://api.openai.com/v1/images/generations \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$TAT_IMAGE_MODEL\",
    \"prompt\": $PROMPT_JSON,
    \"size\": \"$TAT_IMAGE_SIZE\",
    \"quality\": \"$TAT_IMAGE_QUALITY\",
    \"n\": 1
  }")

# --- Extract URL ---

IMAGE_URL=$(echo "$RESPONSE" | python3 -c 'import sys,json; r=json.load(sys.stdin); print(r["data"][0]["url"])' 2>/dev/null)

if [ -z "$IMAGE_URL" ]; then
  ERROR=$(echo "$RESPONSE" | python3 -c 'import sys,json; r=json.load(sys.stdin); print(r.get("error",{}).get("message","Unknown error"))' 2>/dev/null || echo "Unknown error")
  echo "[TAT] ERROR: DALL-E API failed — $ERROR" >&2
  echo "[TAT] Raw response: $RESPONSE" >&2
  exit 1
fi

# --- Download image ---

echo "[TAT] Downloading image..."
curl -s "$IMAGE_URL" -o "$OUTPUT"

if [ -f "$OUTPUT" ]; then
  SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')
  echo "[TAT] Image saved: $OUTPUT ($SIZE bytes)"
else
  echo "[TAT] ERROR: Failed to download image" >&2
  exit 1
fi
