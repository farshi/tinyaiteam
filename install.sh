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

# Claude Code skills
for skill_dir in "$SCRIPT_DIR/skills/"*/; do
  skill_name=$(basename "$skill_dir")
  if [ -f "$skill_dir/SKILL.md" ]; then
    mkdir -p ~/.claude/skills/"$skill_name"
    cp "$skill_dir/SKILL.md" ~/.claude/skills/"$skill_name"/SKILL.md
    echo "  ✓ SKILL.md → ~/.claude/skills/$skill_name/"
  fi
done

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
echo ""
echo "To add git hooks to a project, run from the project root:"
echo "  cp ~/dev/tinyaiteam/hooks/* .git/hooks/ && chmod +x .git/hooks/commit-msg .git/hooks/pre-push"
