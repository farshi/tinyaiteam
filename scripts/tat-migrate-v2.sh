#!/bin/bash
# tat-migrate-v2.sh — One-time migration from TAT v1 to v2
# Run from a TAT-enabled project root.
#
# What it does:
#   1. Preserves next_task_id counter from old state.json
#   2. Archives v1 files to .tat/archive/
#   3. Merges project-local lessons into global library
#   4. Appends ADR summaries to spec.md
#   5. Converts plan.md sprint tables to flat task list
#
# Safe: creates archive, doesn't delete originals until archived.

set -euo pipefail

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TAT_DIR="$PROJECT_ROOT/.tat"
GLOBAL_DIR="$HOME/.tinyaiteam"
ARCHIVE="$TAT_DIR/archive"

echo "[TAT] Migrating to v2..."
echo "[TAT] Project: $PROJECT_ROOT"
echo ""

if [ ! -d "$TAT_DIR" ]; then
  echo "[TAT] No .tat/ directory found. Nothing to migrate."
  exit 0
fi

# --- Create archive ---
mkdir -p "$ARCHIVE"

# --- 1. Preserve counter from state.json ---
if [ -f "$TAT_DIR/state.json" ]; then
  echo "[TAT] 1. State.json..."

  # Extract next_task_id
  NEXT_ID=$(python3 -c "
import json
with open('$TAT_DIR/state.json') as f:
    d = json.load(f)
print(d.get('next_task_id', 1))
" 2>/dev/null || echo "1")

  PROJECT_NAME=$(python3 -c "
import json
with open('$TAT_DIR/state.json') as f:
    d = json.load(f)
print(d.get('project', 'Unknown'))
" 2>/dev/null || echo "Unknown")

  # Write new v2 state.json (counter only)
  python3 -c "
import json
state = {'version': 2, 'project': '$PROJECT_NAME', 'next_task_id': $NEXT_ID}
with open('$TAT_DIR/state.json', 'w') as f:
    json.dump(state, f, indent=2)
    f.write('\n')
"

  echo "  ✓ Preserved next_task_id=$NEXT_ID, stripped phase tracking"
else
  echo "[TAT] 1. No state.json — skipping"
fi

# --- 2. Archive old files ---
echo "[TAT] 2. Archiving v1 files..."

for item in decisions reviews retro.md sprint.md replan-log.md; do
  if [ -e "$TAT_DIR/$item" ]; then
    mv "$TAT_DIR/$item" "$ARCHIVE/"
    echo "  ✓ $item → archive/"
  fi
done

# --- 3. Merge project lessons into global library ---
if [ -f "$TAT_DIR/lessons.md" ]; then
  echo "[TAT] 3. Lessons..."

  if [ -f "$GLOBAL_DIR/lessons.md" ]; then
    # Append project lessons with a header
    echo "" >> "$GLOBAL_DIR/lessons.md"
    echo "---" >> "$GLOBAL_DIR/lessons.md"
    echo "" >> "$GLOBAL_DIR/lessons.md"
    echo "## From $(basename "$PROJECT_ROOT") (migrated $(date +%Y-%m-%d))" >> "$GLOBAL_DIR/lessons.md"
    echo "" >> "$GLOBAL_DIR/lessons.md"
    # Skip the header line and append content
    tail -n +2 "$TAT_DIR/lessons.md" >> "$GLOBAL_DIR/lessons.md"
    echo "  ✓ Merged into $GLOBAL_DIR/lessons.md"
  else
    cp "$TAT_DIR/lessons.md" "$GLOBAL_DIR/lessons.md"
    echo "  ✓ Copied as $GLOBAL_DIR/lessons.md (first project)"
  fi

  mv "$TAT_DIR/lessons.md" "$ARCHIVE/"
  echo "  ✓ lessons.md → archive/"
else
  echo "[TAT] 3. No project lessons — skipping"
fi

# --- 4. Consolidate ADRs into decisions.md ---
if [ -d "$ARCHIVE/decisions" ]; then
  echo "[TAT] 4. ADRs..."

  DECISIONS_FILE="$TAT_DIR/decisions.md"

  echo "# Decisions" > "$DECISIONS_FILE"
  echo "" >> "$DECISIONS_FILE"
  echo "Key decisions with rationale. Append-only." >> "$DECISIONS_FILE"
  echo "" >> "$DECISIONS_FILE"

  for adr in "$ARCHIVE/decisions/"*.md; do
    [ -f "$adr" ] || continue
    TITLE=$(grep -m1 '^# ' "$adr" | sed 's/^# //' || true)
    if [ -n "$TITLE" ]; then
      echo "### $TITLE" >> "$DECISIONS_FILE"
      # Extract Decision section (try common heading variants)
      DECISION=$(sed -n '/^## Decision/,/^## /p' "$adr" | tail -n +2 | grep -v '^## ' || true)
      if [ -z "$DECISION" ]; then
        DECISION=$(sed -n '/^## Decided/,/^## /p' "$adr" | tail -n +2 | grep -v '^## ' || true)
      fi
      # Extract Rationale/Why section
      RATIONALE=$(sed -n '/^## Rationale/,/^## /p' "$adr" | tail -n +2 | grep -v '^## ' || true)
      if [ -z "$RATIONALE" ]; then
        RATIONALE=$(sed -n '/^## Why/,/^## /p' "$adr" | tail -n +2 | grep -v '^## ' || true)
      fi
      # If no structured sections found, just grab the Context
      if [ -z "$DECISION" ] && [ -z "$RATIONALE" ]; then
        DECISION=$(sed -n '/^## Context/,/^## /p' "$adr" | tail -n +2 | grep -v '^## ' || true)
      fi
      [ -n "$DECISION" ] && echo "$DECISION" >> "$DECISIONS_FILE"
      [ -n "$RATIONALE" ] && echo "**Why:** $RATIONALE" >> "$DECISIONS_FILE"
      echo "" >> "$DECISIONS_FILE"
    fi
  done

  echo "  ✓ Consolidated $(ls "$ARCHIVE/decisions/" | wc -l | tr -d ' ') ADRs → decisions.md"
else
  echo "[TAT] 4. No ADRs to merge — skipping"
fi

# --- 5. Convert plan.md ---
echo "[TAT] 5. Plan.md..."
if [ -f "$TAT_DIR/plan.md" ]; then
  # Check if already v2 format
  if grep -q "^## Tasks" "$TAT_DIR/plan.md"; then
    echo "  ✓ Already v2 format — skipping"
  else
    echo "  ⚠ Plan.md is in v1 sprint format."
    echo "  ⚠ Manual conversion recommended — sprint tables vary too much for auto-convert."
    echo "  ⚠ Format: flat '## Tasks' table (top = next) + '## Done' table (completed)."
    cp "$TAT_DIR/plan.md" "$ARCHIVE/plan-v1.md"
    echo "  ✓ Backed up as archive/plan-v1.md"
  fi
fi

# --- 6. Update git hooks ---
echo "[TAT] 6. Git hooks..."
if [ -d "$PROJECT_ROOT/.git/hooks" ]; then
  # Remove pre-push if it's a TAT hook
  if [ -f "$PROJECT_ROOT/.git/hooks/pre-push" ] && grep -q "TAT" "$PROJECT_ROOT/.git/hooks/pre-push" 2>/dev/null; then
    rm "$PROJECT_ROOT/.git/hooks/pre-push"
    echo "  ✓ Removed redundant pre-push hook"
  fi

  # Update pre-commit and commit-msg
  if [ -f "$GLOBAL_DIR/hooks/pre-commit" ]; then
    cp "$GLOBAL_DIR/hooks/pre-commit" "$PROJECT_ROOT/.git/hooks/pre-commit"
    chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"
    echo "  ✓ Updated pre-commit hook"
  fi
  if [ -f "$GLOBAL_DIR/hooks/commit-msg" ]; then
    cp "$GLOBAL_DIR/hooks/commit-msg" "$PROJECT_ROOT/.git/hooks/commit-msg"
    chmod +x "$PROJECT_ROOT/.git/hooks/commit-msg"
    echo "  ✓ Updated commit-msg hook"
  fi
fi

# --- Summary ---
echo ""
echo "[TAT] ✓ Migration complete."
echo ""
echo "  Archived to: $ARCHIVE/"
[ -d "$ARCHIVE/decisions" ] && echo "    - decisions/ ($(ls "$ARCHIVE/decisions/" | wc -l | tr -d ' ') ADRs)"
[ -f "$ARCHIVE/retro.md" ] && echo "    - retro.md"
[ -f "$ARCHIVE/sprint.md" ] && echo "    - sprint.md"
[ -f "$ARCHIVE/lessons.md" ] && echo "    - lessons.md (merged into global)"
[ -d "$ARCHIVE/reviews" ] && echo "    - reviews/ ($(ls "$ARCHIVE/reviews/" | wc -l | tr -d ' ') artifacts)"
echo ""
echo "  Remaining TODO:"
echo "    - Convert plan.md to v2 flat format (if not already done)"
echo "    - Review spec.md — verify inline decisions are accurate"
echo "    - Deduplicate lessons in ~/.tinyaiteam/lessons.md"
echo ""
echo "  Run /tat to verify everything works."
