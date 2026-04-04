# Plan

## Next: v3.0.0

### TAT-121 — v3 docs + new plan format
- What: Update spec/README/CHANGELOG for v3. Switch plan format from tables to task cards with subtasks
- Files: spec.md, README.md, CHANGELOG.md, TAT.md, plan.md
- Done: Docs reflect v3. Plan uses card format. No stale v2 references
- [x] Update TAT.md with task format + sizing rules
- [x] Rewrite plan.md in card format
- [x] Update spec.md
- [x] Update README.md
- [x] Add CHANGELOG v3.0.0 entry
- [x] Update SKILL.md init template to card format

## Backlog

### TAT-068 — Optional skill adapter hooks
- What: Detect/use external skills as plugins
- Files: TBD
- Done: TAT can discover and invoke non-core skills

### TAT-079 — Docs follow context
- What: Auto-detect new concepts, prompt for glossary
- Files: TBD
- Done: New terms surfaced during planning/review

### TAT-080 — Split large tasks by value layer
- What: Suggest core/enhancement splits for oversized tasks
- Files: TBD
- Done: Planning flow detects and suggests splits

## Done (v3.0.0)

- TAT-115: Kill lessons/reports/today/gpt-cursor
- TAT-116: Fix-spec task card format
- TAT-117: Rewrite TAT.md — flows replace rules
- TAT-118: Slim SKILL.md + guardrailed flows + aux/
- TAT-119+120: Move migration scripts + clean install.sh

## Done (v2.x)

- TAT-114: Update README for v2.2.0
- TAT-113: Auto-upgrade on /tat activation
- TAT-112: Version-based planning
- TAT-111: Task-ID branch naming + commits
- TAT-110: v2 simplification (-1181 lines)
- TAT-101–109: Spec update, GPT review, report, version, mismatch guard, wrapup
- TAT-060–099: GPT integration, parallel agents, sprint ceremonies, lessons, ADRs
- TAT-030–059: Article skill, review gates, PR descriptions, state management
- TAT-001–029: Foundation, core skill, git workflow
