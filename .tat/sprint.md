# Sprint 10 — Foundation Repair + New Commands

**Goal:** Fix spec drift, capture missing ADRs, and build /tat wrapup + /tat replan commands.
**Date:** 2026-04-02

## Relevant Constraints
- L9: Format changes must update all downstream consumers — spec.md update may require downstream checks
- L8: Backlog tasks must carry Ref: links — /tat replan must enforce this
- ADR-005: Sprint table format — replan must parse tables correctly
- ADR-009: File-overlap gate — if parallelizing, check shared files
- GL-04: Self-review before GPT — always
- GL-08/GL-16: Plan updates in feature branch — always

## Scope
| ID | Task | Epic |
|----|------|------|
| TAT-101 | Update spec.md to match current reality | E18 |
| TAT-102 | Capture missing ADRs (6 decisions) | E18 |
| TAT-104 | /tat wrapup command | E19 |
| TAT-067 | /tat replan command | E19 |

## Out of Scope
- TAT-100: project-specific task ID prefixes (defer to Sprint 11)
- TAT-103: already captured in ADR-009
- New feature development — this sprint is about fixing foundations

## Risks
1. Spec update is subjective — risk of over/under-documenting. Mitigation: GPT reviews the spec draft.
2. /tat replan touches plan.md parsing — same format drift risk as Sprint 9. Mitigation: L9 constraint, test against current plan.md.
3. 6 ADRs is a lot of writing. Mitigation: keep them concise, one paragraph each.

## Definition of Done
- spec.md accurately describes TAT as it exists today
- All 6 missing ADRs captured in .tat/decisions/
- /tat wrapup command works in SKILL.md
- /tat replan command works in SKILL.md with GPT advisory
- install.sh works after all changes
- GL-02 updated to reflect gpt-5.2-codex
