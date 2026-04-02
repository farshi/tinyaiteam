# Sprint 9 — Version Awareness + Lesson Lifecycle

**Goal:** Make TAT version-aware across projects and reduce lesson noise at sprint-start.
**Date:** 2026-04-01

## Relevant Constraints
- GL-08: Separate docs from code on branches
- GL-10: Don't force-override hooks — fix the root cause
- L5: Avoid em dashes in AI-generated content (applies to CHANGELOG writing)
- ADR-006: Graceful degradation — VERSION file may not exist in older installs

## Scope
| ID | Task | Epic |
|----|------|------|
| TAT-093 | Add VERSION file + CHANGELOG.md | E16 |
| TAT-094 | install.sh deploys VERSION | E16 |
| TAT-095 | /tat activation shows version | E16 |
| TAT-096 | Tag v0.4.0 release | E16 |
| TAT-097 | Add [active]/[applied] markers to lessons | E17 |
| TAT-098 | Sprint-start loads only [active] lessons | E17 |
| TAT-099 | /tat graduate command | E17 |

## Out of Scope
- Network-based version checking
- Auto-graduation of lessons
- Auto-upgrade functionality

## Risks
1. CHANGELOG retroactive entries may be incomplete — best-effort from git history
2. Lesson markers change the file format — simple string prefix, backwards compatible

## Definition of Done
- install.sh deploys VERSION, /tat shows it
- Sprint-start only prints [active] lessons
- v0.4.0 tagged and pushed
