#!/bin/bash
# tat-save-review.sh — Save review artifacts for TAT review gates
# Usage:
#   tat-save-review.sh <task-id> <self-review-summary> [gpt-review-file]
#
# Creates .tat/reviews/<task-id>-review.md with self-review and GPT feedback.
# The SHIP checkpoint gate checks for this file before allowing PR creation.

set -euo pipefail

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
REVIEWS_DIR="$PROJECT_ROOT/.tat/reviews"

if [ $# -lt 2 ]; then
  echo "[TAT] Usage: tat-save-review.sh <task-id> <self-review-summary> [gpt-review-file]" >&2
  echo "[TAT] Example: tat-save-review.sh TAT-056 'Clean diff, 2 files, no issues'" >&2
  exit 1
fi

TASK_ID="$1"
SELF_REVIEW="$2"
GPT_REVIEW_FILE="${3:-}"

mkdir -p "$REVIEWS_DIR"

REVIEW_FILE="$REVIEWS_DIR/${TASK_ID}-review.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

cat > "$REVIEW_FILE" <<EOF
# Review: ${TASK_ID}

**Date:** ${TIMESTAMP}
**Branch:** ${BRANCH}
**Diff scope:** $(git diff origin/main --name-only 2>/dev/null | wc -l | tr -d ' ') files

## Self-Review

${SELF_REVIEW}

## GPT Review

EOF

if [ -n "$GPT_REVIEW_FILE" ] && [ -f "$GPT_REVIEW_FILE" ]; then
  cat "$GPT_REVIEW_FILE" >> "$REVIEW_FILE"
elif [ -n "$GPT_REVIEW_FILE" ]; then
  echo "$GPT_REVIEW_FILE" >> "$REVIEW_FILE"
else
  echo "_GPT review not captured._" >> "$REVIEW_FILE"
fi

echo "[TAT] Review artifact saved: $REVIEW_FILE"
