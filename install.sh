#!/bin/bash
# TAT Installer — copies workflow rules, skills, and commands to their active locations

set -e

TAT_VERSION="0.1.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing TAT v$TAT_VERSION..."

# Global workflow rules
mkdir -p ~/.tinyaiteam
cp "$SCRIPT_DIR/TAT.md" ~/.tinyaiteam/TAT.md
echo "  ✓ TAT.md → ~/.tinyaiteam/"

# Config
cp "$SCRIPT_DIR/config.sh" ~/.tinyaiteam/config.sh
echo "  ✓ config.sh → ~/.tinyaiteam/"

# Scripts
if [ -d "$SCRIPT_DIR/scripts" ]; then
  mkdir -p ~/.tinyaiteam/scripts
  for script in "$SCRIPT_DIR/scripts/"*.sh; do
    [ -f "$script" ] && cp "$script" ~/.tinyaiteam/scripts/ && chmod +x ~/.tinyaiteam/scripts/"$(basename "$script")"
  done
  echo "  ✓ scripts → ~/.tinyaiteam/scripts/"
fi

# Git hooks (available for project setup via /tat init)
if [ -d "$SCRIPT_DIR/hooks" ]; then
  mkdir -p ~/.tinyaiteam/hooks
  for hook in "$SCRIPT_DIR/hooks/"*; do
    [ -f "$hook" ] && cp "$hook" ~/.tinyaiteam/hooks/ && chmod +x ~/.tinyaiteam/hooks/"$(basename "$hook")"
  done
  echo "  ✓ hooks → ~/.tinyaiteam/hooks/"
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
echo "  cp $SCRIPT_DIR/hooks/* .git/hooks/ && chmod +x .git/hooks/commit-msg .git/hooks/pre-push"

if [ -z "$OPENAI_API_KEY" ]; then
  echo ""
  echo "  ⚠ OPENAI_API_KEY not set. GPT reviews won't work until you export it."
fi

echo ""
echo "TAT v$TAT_VERSION installed successfully."
