#!/bin/bash
# TAT Installer — copies workflow rules, skills, and commands to their active locations

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing TAT..."

# Global workflow rules
mkdir -p ~/.tinyaiteam
cp "$SCRIPT_DIR/TAT.md" ~/.tinyaiteam/TAT.md
echo "  ✓ TAT.md → ~/.tinyaiteam/"

# Config (don't overwrite if exists — user may have customized)
if [ ! -f ~/.tinyaiteam/config.sh ]; then
  cp "$SCRIPT_DIR/config.sh" ~/.tinyaiteam/config.sh 2>/dev/null || true
  echo "  ✓ config.sh → ~/.tinyaiteam/"
else
  echo "  ⏭ config.sh already exists, skipping (won't overwrite)"
fi

# Claude Code skill
if [ -d "$SCRIPT_DIR/skills/tat" ]; then
  mkdir -p ~/.claude/skills/tat
  cp "$SCRIPT_DIR/skills/tat/SKILL.md" ~/.claude/skills/tat/SKILL.md
  echo "  ✓ SKILL.md → ~/.claude/skills/tat/"
fi

# Claude Code commands
if [ -d "$SCRIPT_DIR/commands" ]; then
  mkdir -p ~/.claude/commands
  for cmd in "$SCRIPT_DIR/commands/"*.md; do
    [ -f "$cmd" ] && cp "$cmd" ~/.claude/commands/
  done
  echo "  ✓ commands → ~/.claude/commands/"
fi

echo ""
echo "TAT installed. Use /tat in any project to start."
