#!/bin/bash
# TAT Installer — symlinks repo files to their active locations
# After this, git pull = instant update everywhere. No re-install needed.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAT_VERSION=$(cat "$SCRIPT_DIR/VERSION")

echo "Installing TAT v$TAT_VERSION (symlink mode)..."

# --- Helper ---
link_file() {
  local src="$1" dst="$2"
  rm -f "$dst"
  ln -sf "$src" "$dst"
}

link_dir() {
  local src="$1" dst="$2"
  rm -rf "$dst"
  ln -sf "$src" "$dst"
}

# --- Global workflow rules ---
mkdir -p ~/.tinyaiteam
link_file "$SCRIPT_DIR/TAT.md" ~/.tinyaiteam/TAT.md
echo "  ✓ TAT.md → ~/.tinyaiteam/"
link_file "$SCRIPT_DIR/VERSION" ~/.tinyaiteam/VERSION
echo "  ✓ VERSION → ~/.tinyaiteam/"

# Config (copy, not symlink — user may customize)
if [ ! -f ~/.tinyaiteam/config.sh ]; then
  cp "$SCRIPT_DIR/config.sh" ~/.tinyaiteam/config.sh
  echo "  ✓ config.sh → ~/.tinyaiteam/ (copied — customize freely)"
else
  echo "  ✓ config.sh already exists (not overwritten)"
fi

# Scripts
link_dir "$SCRIPT_DIR/scripts" ~/.tinyaiteam/scripts
echo "  ✓ scripts → ~/.tinyaiteam/scripts/"

# Lessons
link_file "$SCRIPT_DIR/lessons/library.md" ~/.tinyaiteam/lessons.md
echo "  ✓ lessons → ~/.tinyaiteam/lessons.md"

# Git hooks (copy, not symlink — installed per-project, not global)
mkdir -p ~/.tinyaiteam/hooks
for hook in "$SCRIPT_DIR/hooks/"*; do
  [ -f "$hook" ] && cp "$hook" ~/.tinyaiteam/hooks/ && chmod +x ~/.tinyaiteam/hooks/"$(basename "$hook")"
done
echo "  ✓ hooks → ~/.tinyaiteam/hooks/"

# Claude Code skills (symlink each SKILL.md)
for skill_dir in "$SCRIPT_DIR/skills/"*/; do
  skill_name=$(basename "$skill_dir")
  if [ -f "$skill_dir/SKILL.md" ]; then
    mkdir -p ~/.claude/skills/"$skill_name"
    link_file "$skill_dir/SKILL.md" ~/.claude/skills/"$skill_name"/SKILL.md
    echo "  ✓ SKILL.md → ~/.claude/skills/$skill_name/"
  fi
done

# Claude Code commands
if [ -d "$SCRIPT_DIR/commands" ]; then
  mkdir -p ~/.claude/commands
  for cmd in "$SCRIPT_DIR/commands/"*.md; do
    [ -f "$cmd" ] && link_file "$cmd" ~/.claude/commands/"$(basename "$cmd")"
  done
  echo "  ✓ commands → ~/.claude/commands/"
fi

# Reports file (create if missing)
touch ~/.tinyaiteam/reports.md

echo ""
echo "TAT v$TAT_VERSION installed (symlink mode)."
echo "Future updates: just git pull. No re-install needed."
echo ""
echo "To add git hooks to a project:"
echo "  cp ~/.tinyaiteam/hooks/pre-commit ~/.tinyaiteam/hooks/commit-msg .git/hooks/ && chmod +x .git/hooks/pre-commit .git/hooks/commit-msg"

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo ""
  echo "  ⚠ OPENAI_API_KEY not set. GPT reviews won't work until you export it."
fi
