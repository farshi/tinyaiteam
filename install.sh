#!/bin/bash
# TAT Installer — copies workflow rules, skills, and commands to their active locations

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAT_VERSION=$(cat "$SCRIPT_DIR/VERSION")

echo "Installing TAT v$TAT_VERSION..."

# Global workflow rules
mkdir -p ~/.tinyaiteam
cp "$SCRIPT_DIR/TAT.md" ~/.tinyaiteam/TAT.md
echo "  ✓ TAT.md → ~/.tinyaiteam/"
cp "$SCRIPT_DIR/VERSION" ~/.tinyaiteam/VERSION
echo "  ✓ VERSION → ~/.tinyaiteam/"

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

# Lessons library (global — loaded at /tat activation)
if [ -d "$SCRIPT_DIR/lessons" ]; then
  for lesson_file in "$SCRIPT_DIR/lessons/"*.md; do
    [ -f "$lesson_file" ] && cp "$lesson_file" ~/.tinyaiteam/lessons.md
  done
  echo "  ✓ lessons → ~/.tinyaiteam/lessons.md"
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

# Create reports file if it doesn't exist
touch ~/.tinyaiteam/reports.md

echo ""
echo "TAT installed. Use /tat in any project to start."
echo ""
echo "To add git hooks to a project, run from the project root:"
echo "  cp ~/.tinyaiteam/hooks/pre-commit ~/.tinyaiteam/hooks/commit-msg .git/hooks/ && chmod +x .git/hooks/pre-commit .git/hooks/commit-msg"

if [ -z "$OPENAI_API_KEY" ]; then
  echo ""
  echo "  ⚠ OPENAI_API_KEY not set. GPT reviews won't work until you export it."
fi

echo ""
echo "TAT v$TAT_VERSION installed successfully."
