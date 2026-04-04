#!/bin/bash
# tat-migrate-plan.sh — Convert flat plan.md to version-based format
# Run from a TAT-enabled project root.
#
# What it does:
#   1. Detects current version from git tags (or "unversioned")
#   2. Suggests next version (semver bump)
#   3. Replaces "## Tasks" with "## Next: vX.Y.Z"
#   4. Adds "## Backlog" section if not present
#   5. Optionally adds project prefix to bare task IDs (e.g. 35 → DSA-035)
#
# Safe: creates backup before modifying.

set -euo pipefail

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TAT_DIR="$PROJECT_ROOT/.tat"
PLAN="$TAT_DIR/plan.md"
PROJECT_NAME=$(basename "$PROJECT_ROOT")

if [ ! -f "$PLAN" ]; then
  echo "[TAT] No plan.md found at $PLAN"
  exit 1
fi

# --- Detect current version from git tags ---

CURRENT_VERSION=$(git tag --sort=-v:refname 2>/dev/null | grep -E '^v[0-9]' | head -1 || true)
if [ -z "$CURRENT_VERSION" ]; then
  CURRENT_VERSION="unversioned"
  NEXT_VERSION="v0.1.0"
else
  # Suggest minor bump: v0.3.0 → v0.4.0, v2.1.0 → v2.2.0
  NEXT_VERSION=$(echo "$CURRENT_VERSION" | awk -F. '{printf "%s.%d.0", $1, $2+1}')
fi

echo "[TAT] Project: $PROJECT_NAME"
echo "[TAT] Current version: $CURRENT_VERSION"
echo "[TAT] Suggested next: $NEXT_VERSION"

# --- Check if already migrated ---

if grep -q '^## Next:' "$PLAN" 2>/dev/null; then
  echo "[TAT] Plan already has version headers. Nothing to do."
  exit 0
fi

# --- Detect task ID prefix ---

# Check if tasks use bare numbers (e.g. | 35 |) vs prefixed (e.g. | OM-080 |)
BARE_IDS=$(grep -E '^\| *[0-9]+ *\|' "$PLAN" | head -1 || true)
PREFIX=""
if [ -n "$BARE_IDS" ]; then
  # Suggest a prefix based on project name
  SUGGESTED_PREFIX=$(echo "$PROJECT_NAME" | tr '[:lower:]' '[:upper:]' | sed 's/[^A-Z]//g' | head -c 3)
  echo "[TAT] Detected bare task IDs (no prefix)."
  echo "[TAT] Suggested prefix: $SUGGESTED_PREFIX"
  echo "[TAT] To add prefix, run: $0 --prefix $SUGGESTED_PREFIX"

  # Check for --prefix arg
  for arg in "$@"; do
    case "$arg" in
      --prefix) PREFIX="$2"; shift 2 || true ;;
    esac
  done
fi

# --- Backup ---

cp "$PLAN" "$PLAN.bak"
echo "[TAT] Backup: $PLAN.bak"

# --- Transform ---

# Replace "## Tasks" with "## Next: vX.Y.Z"
sed -i '' "s/^## Tasks$/## Next: $NEXT_VERSION/" "$PLAN"

# Add Backlog section if missing (before ## Done)
if ! grep -q '^## Backlog' "$PLAN"; then
  sed -i '' "/^## Done/i\\
## Backlog\\
\\
| ID | Task | Status |\\
|----|------|--------|\\
" "$PLAN"
fi

# Add prefix to bare task IDs if requested
if [ -n "$PREFIX" ]; then
  # Convert | 35 | to | DSA-035 |
  python3 -c "
import re, sys
with open(sys.argv[1]) as f:
    content = f.read()
prefix = sys.argv[2]
def add_prefix(m):
    num = int(m.group(1))
    return f'| {prefix}-{num:03d} |'
content = re.sub(r'\| *(\d+) *\|', add_prefix, content)
with open(sys.argv[1], 'w') as f:
    f.write(content)
" "$PLAN" "$PREFIX"
  echo "[TAT] Added prefix $PREFIX- to bare task IDs."
fi

echo ""
echo "[TAT] Migration complete:"
echo "  ✓ ## Tasks → ## Next: $NEXT_VERSION"
echo "  ✓ ## Backlog section added"
[ -n "$PREFIX" ] && echo "  ✓ Task IDs prefixed with $PREFIX-"
echo ""
echo "[TAT] Review $PLAN, then commit the change."
