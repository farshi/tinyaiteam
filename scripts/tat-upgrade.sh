#!/bin/bash
# tat-upgrade.sh — Auto-sync hooks and version marker on /tat activation
# Called from SKILL.md Step 1. Idempotent — safe to run every time.
#
# Usage: tat-upgrade.sh [project-root]

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TAT_DIR="$PROJECT_ROOT/.tat"
GLOBAL_DIR="$HOME/.tinyaiteam"
VERSION_FILE="$TAT_DIR/version"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# --- Read versions ---

INSTALLED=$(cat "$GLOBAL_DIR/VERSION" 2>/dev/null || echo "unknown")
PROJECT=$(cat "$VERSION_FILE" 2>/dev/null || echo "0.0.0")

if [ "$INSTALLED" = "$PROJECT" ]; then
  exit 0
fi

echo "[TAT] Upgrading: v$PROJECT → v$INSTALLED"

# --- Auto-sync hooks ---

if [ -d "$GLOBAL_DIR/hooks" ] && [ -d "$PROJECT_ROOT/.git" ]; then
  mkdir -p "$HOOKS_DIR"
  for hook in pre-commit commit-msg pre-push; do
    if [ -f "$GLOBAL_DIR/hooks/$hook" ]; then
      cp "$GLOBAL_DIR/hooks/$hook" "$HOOKS_DIR/$hook"
      chmod +x "$HOOKS_DIR/$hook"
    fi
  done
  echo "  ✓ Hooks synced"
fi

# --- Update version marker ---

echo "$INSTALLED" > "$VERSION_FILE"
echo "  ✓ Version marker: $INSTALLED"
