# GPT Review

**Date:** 2026-04-04T07:50:13Z
**Branch:** tat-115/lessons-library-cleanup
**Model:** gpt-5.2-codex
**Task:** | TAT-115 | Kill lessons/reports/today/gpt-cursor — plan is single source | [x] |
**Diff:** 568 lines

BLOCKERS: 
- none

SUGGESTIONS:
- `scripts/tat-gpt-watch.sh`: you removed `gpt-cursor` but left `LAST_SEEN=0` with no replacement. That means every run treats all session entries as unseen. If you want to preserve “delta only” behavior, parse the cursor from `gpt.md` (as the comment suggests) or drop the comment to avoid misleading behavior.
- Check for lingering `/tat report`, `today.md`, or lessons mentions in other user-facing docs (e.g., README/CLAUDE.md) so the removal is consistent.

NOTES:
- Scope creep: `.tat/plan.md` now includes v3 table + task cards (TAT-116 content) and `.tat/state.json`/`.tat/gpt.md` updates. Not necessarily bad, but it’s beyond the stated TAT-115 scope.
- Removing lessons/reports/today/gpt-cursor references from TAT.md, spec.md, SKILL.md, install.sh, and gpt-watch aligns with the task.

CONFIDENCE: MEDIUM — I reviewed only the diff; other files might still reference removed artifacts.
