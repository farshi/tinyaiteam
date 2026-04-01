#!/bin/bash
# tat-publish.sh — Publish a markdown article to Medium
# Usage: tat-publish.sh <markdown-file> [--draft|--public|--unlisted]
#
# Reads a markdown file, extracts title and tags from frontmatter,
# and publishes to Medium via their API.
#
# Requires: MEDIUM_TOKEN environment variable (integration token from medium.com/me/settings)

set -euo pipefail

# --- Validation ---

if [ $# -lt 1 ]; then
  echo "[TAT] Usage: tat-publish.sh <markdown-file> [--draft|--public|--unlisted]" >&2
  echo "  Publishes a markdown article to Medium." >&2
  echo "  Set MEDIUM_TOKEN env var (from medium.com/me/settings → Integration Tokens)" >&2
  exit 1
fi

ARTICLE_FILE="$1"
PUBLISH_STATUS="${2:---draft}"
PUBLISH_STATUS="${PUBLISH_STATUS#--}"  # strip leading --

if [ ! -f "$ARTICLE_FILE" ]; then
  echo "[TAT] ERROR: File not found: $ARTICLE_FILE" >&2
  exit 1
fi

if [ -z "${MEDIUM_TOKEN:-}" ]; then
  echo "[TAT] ERROR: MEDIUM_TOKEN not set." >&2
  echo "[TAT] Get one at: https://medium.com/me/settings → Integration Tokens" >&2
  exit 1
fi

# Validate publish status
case "$PUBLISH_STATUS" in
  draft|public|unlisted) ;;
  *)
    echo "[TAT] ERROR: Invalid status '$PUBLISH_STATUS'. Use --draft, --public, or --unlisted." >&2
    exit 1
    ;;
esac

# --- Parse frontmatter ---

TITLE=""
TAGS=""
CANONICAL_URL=""
CONTENT=""

# Check if file has YAML frontmatter (starts with ---)
if head -1 "$ARTICLE_FILE" | grep -q '^---$'; then
  # Extract frontmatter block (between first and second ---)
  FRONTMATTER=$(sed -n '2,/^---$/p' "$ARTICLE_FILE" | sed '$d')

  # Extract title from frontmatter
  TITLE=$(echo "$FRONTMATTER" | grep -E '^title:' | sed 's/^title:[[:space:]]*//' | sed 's/^"//;s/"$//' || true)

  # Extract tags from frontmatter (format: tags: [tag1, tag2, tag3])
  TAGS_RAW=$(echo "$FRONTMATTER" | grep -E '^tags:' | sed 's/^tags:[[:space:]]*//' || true)

  # Extract canonical URL if present
  CANONICAL_URL=$(echo "$FRONTMATTER" | grep -E '^canonical_url:' | sed 's/^canonical_url:[[:space:]]*//' | sed 's/^"//;s/"$//' || true)

  # Content is everything after the closing --- of frontmatter
  FRONTMATTER_END=$(awk '/^---$/{n++; if(n==2){print NR; exit}}' "$ARTICLE_FILE")
  if [ -n "$FRONTMATTER_END" ]; then
    CONTENT=$(tail -n +"$((FRONTMATTER_END + 1))" "$ARTICLE_FILE")
  else
    CONTENT=$(cat "$ARTICLE_FILE")
  fi
else
  CONTENT=$(cat "$ARTICLE_FILE")
fi

# Fallback: extract title from first # heading if not in frontmatter
if [ -z "$TITLE" ]; then
  TITLE=$(echo "$CONTENT" | grep -m1 '^# ' | sed 's/^# //' || true)
fi

if [ -z "$TITLE" ]; then
  echo "[TAT] ERROR: Could not extract title. Add a '# Title' heading or title: in frontmatter." >&2
  exit 1
fi

echo "[TAT] Publishing to Medium..."
echo "[TAT] Title: $TITLE"
echo "[TAT] Status: $PUBLISH_STATUS"

# --- Get author ID ---

echo "[TAT] Fetching user info..."
RESP_FILE=$(mktemp)
HTTP_STATUS=$(curl -s -o "$RESP_FILE" -w '%{http_code}' \
  -H "Authorization: Bearer $MEDIUM_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.medium.com/v1/me") || true
USER_RESPONSE=$(cat "$RESP_FILE")
rm -f "$RESP_FILE"

if [ "$HTTP_STATUS" -lt 200 ] || [ "$HTTP_STATUS" -ge 300 ] 2>/dev/null; then
  echo "[TAT] ERROR: Medium API returned HTTP $HTTP_STATUS" >&2
  echo "[TAT] Response: $USER_RESPONSE" >&2
  exit 1
fi

# Check for errors
if echo "$USER_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'data' in d else 1)" 2>/dev/null; then
  AUTHOR_ID=$(echo "$USER_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")
  USERNAME=$(echo "$USER_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['username'])")
  echo "[TAT] Authenticated as: @$USERNAME"
else
  ERROR_MSG=$(echo "$USER_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('errors',[{}])[0].get('message','Unknown error'))" 2>/dev/null || echo "Unknown error")
  echo "[TAT] ERROR: Medium API authentication failed: $ERROR_MSG" >&2
  echo "[TAT] Check your MEDIUM_TOKEN at https://medium.com/me/settings" >&2
  exit 1
fi

# --- Build payload using Python (GL-06: no shell interpolation for JSON) ---

PAYLOAD_FILE=$(mktemp)
CONTENT_FILE=$(mktemp)
trap "rm -f '$PAYLOAD_FILE' '$CONTENT_FILE'" EXIT

printf '%s' "$CONTENT" > "$CONTENT_FILE"

python3 -c '
import json, sys

with open(sys.argv[1]) as f:
    content = f.read()

title = sys.argv[2]
status = sys.argv[3]
tags_raw = sys.argv[4]
canonical = sys.argv[5]

# Parse tags: "[tag1, tag2, tag3]" or "tag1, tag2, tag3"
tags = []
if tags_raw:
    cleaned = tags_raw.strip("[] ")
    tags = [t.strip().strip("\"'\''") for t in cleaned.split(",") if t.strip()]
    tags = tags[:3]  # Medium only uses first 3

payload = {
    "title": title,
    "contentFormat": "markdown",
    "content": content,
    "publishStatus": status,
}

if tags:
    payload["tags"] = tags
if canonical:
    payload["canonicalUrl"] = canonical

with open(sys.argv[6], "w") as f:
    json.dump(payload, f)
' "$CONTENT_FILE" "$TITLE" "$PUBLISH_STATUS" "$TAGS_RAW" "$CANONICAL_URL" "$PAYLOAD_FILE"

# --- Publish ---

echo "[TAT] Creating post..."
RESP_FILE=$(mktemp)
HTTP_STATUS=$(curl -s -o "$RESP_FILE" -w '%{http_code}' -X POST \
  -H "Authorization: Bearer $MEDIUM_TOKEN" \
  -H "Content-Type: application/json" \
  -d @"$PAYLOAD_FILE" \
  "https://api.medium.com/v1/users/$AUTHOR_ID/posts") || true
RESPONSE=$(cat "$RESP_FILE")
rm -f "$RESP_FILE"

if [ "$HTTP_STATUS" -lt 200 ] || [ "$HTTP_STATUS" -ge 300 ] 2>/dev/null; then
  echo "[TAT] ERROR: Medium API returned HTTP $HTTP_STATUS" >&2
  echo "[TAT] Response: $RESPONSE" >&2
  exit 1
fi

# --- Handle response ---

if echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'data' in d else 1)" 2>/dev/null; then
  POST_URL=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['url'])")
  POST_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")
  POST_STATUS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['publishStatus'])")

  echo "---"
  echo "[TAT] ✓ Published to Medium!"
  echo "[TAT] URL: $POST_URL"
  echo "[TAT] ID: $POST_ID"
  echo "[TAT] Status: $POST_STATUS"

  # If draft, remind user to review
  if [ "$POST_STATUS" = "draft" ]; then
    echo "[TAT] Note: Published as draft. Review and publish at: $POST_URL"
  fi
else
  ERROR_MSG=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('errors',[{}])[0].get('message','Unknown error'))" 2>/dev/null || echo "Unknown error")
  echo "[TAT] ERROR: Failed to publish: $ERROR_MSG" >&2
  echo "[TAT] Response: $RESPONSE" >&2
  exit 1
fi
