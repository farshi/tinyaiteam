# Sprint 8 — Workflow Fixes + Medium Publish

**Goal:** Fix workflow inconsistencies found during Sprint 7 ship + build Medium auto-publish
**Date:** 2026-04-01

## Relevant Constraints
- ADR-005: Sprint tables with TAT-XXX IDs — fixing init template to match
- ADR-006: Graceful degradation — fixes must not break other TAT-managed projects
- GL-06: Shell escaping — use Python for JSON payloads (relevant for tat-publish.sh)
- GL-10: Don't force-override hooks — fix root cause
- Memory: Never commit/push to main, include plan updates in feature branch

## Scope
| ID | Task | Epic |
|----|------|------|
| TAT-085 | tat-publish.sh — auto-publish articles to Medium via REST API | E15 |
| TAT-086 | Fix POST-MERGE — plan updates in feature branch, not main | E10 |
| TAT-087 | Fix GL-08 + Branch Guard — remove "docs on main" advice | E10 |
| TAT-088 | Add GL-16 — never push to protected main | E13 |
| TAT-089 | Fix tat-gpt.sh — add gpt-5.3-codex to RESPONSES_ONLY_MODELS | E10 |
| TAT-090 | Deduplicate SKILL.md — remove redundant checklists and double GPT review | E10 |
| TAT-091 | Fix TAT.md model routing table (gpt-5.4-mini → gpt-5.3-codex) | E11 |
| TAT-092 | Fix init template + status command to use sprint format | E10 |

## Out of Scope
- TAT-065 through TAT-068, TAT-079 through TAT-084 (remain in backlog)
- New skills or features beyond Medium publish

## Risks
1. Medium API may require OAuth or integration tokens — mitigation: research API first
2. SKILL.md deduplication touches many sections — mitigation: careful diff review

## Definition of Done
- All tasks shipped with review artifacts
- install.sh works after all changes
- tat-gpt.sh works with gpt-5.3-codex
- Medium publish tested end-to-end (or documented if API access blocked)
- No duplicate gate checks remain in SKILL.md
