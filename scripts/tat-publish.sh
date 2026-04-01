#!/bin/bash
# tat-publish.sh — Publish a markdown article to Dev.to (or Medium if token available)
# Usage: tat-publish.sh <markdown-file> [--draft|--public] [--platform devto|medium]
#
# Reads a markdown file, extracts title and tags from frontmatter,
# and publishes via the platform's API.
#
# Dev.to:  Set DEVTO_API_KEY env var (from dev.to/settings/extensions)
# Medium:  Set MEDIUM_TOKEN env var (from medium.com/me/settings — legacy, no new tokens)

set -euo pipefail

# --- Validation ---

if [ $# -lt 1 ]; then
  echo "[TAT] Usage: tat-publish.sh <markdown-file> [--draft|--public] [--platform devto|medium]" >&2
  echo "  Publishes a markdown article." >&2
  echo "  Dev.to:  set DEVTO_API_KEY (from dev.to/settings/extensions)" >&2
  echo "  Medium:  set MEDIUM_TOKEN (legacy — no new tokens issued)" >&2
  exit 1
fi

ARTICLE_FILE="$1"
shift

PUBLISH_STATUS="draft"
PLATFORM="devto"

while [ $# -gt 0 ]; do
  case "$1" in
    --draft) PUBLISH_STATUS="draft" ;;
    --public) PUBLISH_STATUS="public" ;;
    --unlisted) PUBLISH_STATUS="unlisted" ;;
    --platform) shift; PLATFORM="$1" ;;
    *) echo "[TAT] Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

if [ ! -f "$ARTICLE_FILE" ]; then
  echo "[TAT] ERROR: File not found: $ARTICLE_FILE" >&2
  exit 1
fi

# --- Parse frontmatter ---

TITLE=""
TAGS_RAW=""
CANONICAL_URL=""
DESCRIPTION=""
CONTENT=""

if head -1 "$ARTICLE_FILE" | grep -q '^---$'; then
  FRONTMATTER=$(sed -n '2,/^---$/p' "$ARTICLE_FILE" | sed '$d')

  TITLE=$(echo "$FRONTMATTER" | grep -E '^title:' | sed 's/^title:[[:space:]]*//' | sed 's/^"//;s/"$//' || true)
  TAGS_RAW=$(echo "$FRONTMATTER" | grep -E '^tags:' | sed 's/^tags:[[:space:]]*//' || true)
  CANONICAL_URL=$(echo "$FRONTMATTER" | grep -E '^canonical_url:' | sed 's/^canonical_url:[[:space:]]*//' | sed 's/^"//;s/"$//' || true)
  DESCRIPTION=$(echo "$FRONTMATTER" | grep -E '^description:' | sed 's/^description:[[:space:]]*//' | sed 's/^"//;s/"$//' || true)

  FRONTMATTER_END=$(awk '/^---$/{n++; if(n==2){print NR; exit}}' "$ARTICLE_FILE")
  if [ -n "$FRONTMATTER_END" ]; then
    CONTENT=$(tail -n +"$((FRONTMATTER_END + 1))" "$ARTICLE_FILE")
  else
    CONTENT=$(cat "$ARTICLE_FILE")
  fi
else
  CONTENT=$(cat "$ARTICLE_FILE")
fi

if [ -z "$TITLE" ]; then
  TITLE=$(echo "$CONTENT" | grep -m1 '^# ' | sed 's/^# //' || true)
fi

if [ -z "$TITLE" ]; then
  echo "[TAT] ERROR: Could not extract title. Add a '# Title' heading or title: in frontmatter." >&2
  exit 1
fi

echo "[TAT] Publishing to $PLATFORM..."
echo "[TAT] Title: $TITLE"
echo "[TAT] Status: $PUBLISH_STATUS"

# ============================================================
# Dev.to
# ============================================================

publish_devto() {
  if [ -z "${DEVTO_API_KEY:-}" ]; then
    echo "[TAT] ERROR: DEVTO_API_KEY not set." >&2
    echo "[TAT] Get one at: https://dev.to/settings/extensions" >&2
    exit 1
  fi

  local PUBLISHED="false"
  [ "$PUBLISH_STATUS" = "public" ] && PUBLISHED="true"

  # Build payload with Python (GL-06: safe JSON construction)
  local PAYLOAD_FILE CONTENT_FILE
  PAYLOAD_FILE=$(mktemp)
  CONTENT_FILE=$(mktemp)
  trap "rm -f '$PAYLOAD_FILE' '$CONTENT_FILE'" EXIT

  printf '%s' "$CONTENT" > "$CONTENT_FILE"

  python3 -c '
import json, sys

with open(sys.argv[1]) as f:
    content = f.read()

title = sys.argv[2]
published = sys.argv[3] == "true"
tags_raw = sys.argv[4]
canonical = sys.argv[5]
description = sys.argv[6]

# Parse tags: "[tag1, tag2, tag3]" or "tag1, tag2, tag3"
tags = []
if tags_raw:
    cleaned = tags_raw.strip("[] ")
    tags = [t.strip().strip("\"'\''").lower().replace(" ", "") for t in cleaned.split(",") if t.strip()]
    tags = tags[:4]  # Dev.to allows up to 4

article = {
    "title": title,
    "body_markdown": content,
    "published": published,
}

if tags:
    article["tags"] = tags
if canonical:
    article["canonical_url"] = canonical
if description:
    article["description"] = description

payload = {"article": article}

with open(sys.argv[7], "w") as f:
    json.dump(payload, f)
' "$CONTENT_FILE" "$TITLE" "$PUBLISHED" "$TAGS_RAW" "$CANONICAL_URL" "$DESCRIPTION" "$PAYLOAD_FILE"

  echo "[TAT] Creating post on Dev.to..."
  local RESP_FILE HTTP_STATUS RESPONSE
  RESP_FILE=$(mktemp)
  HTTP_STATUS=$(curl -s -o "$RESP_FILE" -w '%{http_code}' -X POST \
    -H "api-key: $DEVTO_API_KEY" \
    -H "Content-Type: application/json" \
    -d @"$PAYLOAD_FILE" \
    "https://dev.to/api/articles") || true
  RESPONSE=$(cat "$RESP_FILE")
  rm -f "$RESP_FILE"

  if [ "$HTTP_STATUS" -lt 200 ] || [ "$HTTP_STATUS" -ge 300 ] 2>/dev/null; then
    echo "[TAT] ERROR: Dev.to API returned HTTP $HTTP_STATUS" >&2
    echo "[TAT] Response: $RESPONSE" >&2
    exit 1
  fi

  local POST_URL POST_STATUS
  POST_URL=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('url',''))" 2>/dev/null || true)
  POST_STATUS=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print('public' if d.get('published') else 'draft')" 2>/dev/null || true)

  echo "---"
  echo "[TAT] ✓ Published to Dev.to!"
  echo "[TAT] URL: $POST_URL"
  echo "[TAT] Status: $POST_STATUS"

  if [ "$POST_STATUS" = "draft" ]; then
    echo "[TAT] Note: Published as draft. Review at: https://dev.to/dashboard"
  fi
}

# ============================================================
# Medium (legacy — requires existing integration token)
# ============================================================

publish_medium() {
  if [ -z "${MEDIUM_TOKEN:-}" ]; then
    echo "[TAT] ERROR: MEDIUM_TOKEN not set." >&2
    echo "[TAT] Note: Medium no longer issues new tokens. Use --platform devto instead." >&2
    exit 1
  fi

  echo "[TAT] Fetching Medium user info..."
  local RESP_FILE HTTP_STATUS USER_RESPONSE AUTHOR_ID USERNAME
  RESP_FILE=$(mktemp)
  HTTP_STATUS=$(curl -s -o "$RESP_FILE" -w '%{http_code}' \
    -H "Authorization: Bearer $MEDIUM_TOKEN" \
    -H "Content-Type: application/json" \
    "https://api.medium.com/v1/me") || true
  USER_RESPONSE=$(cat "$RESP_FILE")
  rm -f "$RESP_FILE"

  if [ "$HTTP_STATUS" -lt 200 ] || [ "$HTTP_STATUS" -ge 300 ] 2>/dev/null; then
    echo "[TAT] ERROR: Medium API returned HTTP $HTTP_STATUS" >&2
    exit 1
  fi

  if echo "$USER_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'data' in d else 1)" 2>/dev/null; then
    AUTHOR_ID=$(echo "$USER_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")
    USERNAME=$(echo "$USER_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['username'])")
    echo "[TAT] Authenticated as: @$USERNAME"
  else
    echo "[TAT] ERROR: Medium authentication failed." >&2
    exit 1
  fi

  local PAYLOAD_FILE CONTENT_FILE
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

tags = []
if tags_raw:
    cleaned = tags_raw.strip("[] ")
    tags = [t.strip().strip("\"'\''") for t in cleaned.split(",") if t.strip()]
    tags = tags[:3]

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

  echo "[TAT] Creating post on Medium..."
  RESP_FILE=$(mktemp)
  HTTP_STATUS=$(curl -s -o "$RESP_FILE" -w '%{http_code}' -X POST \
    -H "Authorization: Bearer $MEDIUM_TOKEN" \
    -H "Content-Type: application/json" \
    -d @"$PAYLOAD_FILE" \
    "https://api.medium.com/v1/users/$AUTHOR_ID/posts") || true
  local RESPONSE
  RESPONSE=$(cat "$RESP_FILE")
  rm -f "$RESP_FILE"

  if [ "$HTTP_STATUS" -lt 200 ] || [ "$HTTP_STATUS" -ge 300 ] 2>/dev/null; then
    echo "[TAT] ERROR: Medium API returned HTTP $HTTP_STATUS" >&2
    exit 1
  fi

  if echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'data' in d else 1)" 2>/dev/null; then
    local POST_URL POST_STATUS
    POST_URL=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['url'])")
    POST_STATUS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['publishStatus'])")
    echo "---"
    echo "[TAT] ✓ Published to Medium!"
    echo "[TAT] URL: $POST_URL"
    echo "[TAT] Status: $POST_STATUS"
  else
    echo "[TAT] ERROR: Failed to publish to Medium." >&2
    echo "[TAT] Response: $RESPONSE" >&2
    exit 1
  fi
}

# --- Dispatch ---

case "$PLATFORM" in
  devto|dev.to) publish_devto ;;
  medium) publish_medium ;;
  *)
    echo "[TAT] ERROR: Unknown platform '$PLATFORM'. Use --platform devto or --platform medium." >&2
    exit 1
    ;;
esac
