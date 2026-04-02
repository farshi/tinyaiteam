# Sprint Retros

Append-only log of sprint retrospectives. Each sprint-end appends a section here.

<!-- /tat sprint-end appends retro summaries below this line -->

## Sprint 6 — Integration + Polish
**Date:** 2026-03-31
**Goal met?** Yes — all 7 tasks shipped + bug fix + v0.2.0 release

### Shipped
- TAT-069: /tat sprint-start (#28)
- TAT-070: /tat sprint-end (#31)
- TAT-071: Pre-push tag fix (#29)
- TAT-060: GPT API retry/fallback (#33)
- TAT-061: Parallel Sonnet subagents (#34)
- TAT-062: CONTRIBUTING.md (#35)
- TAT-064: ADR-005 through ADR-008 (#35)
- TAT-063: Repo cleanup — assessed, already clean, no changes needed
- v0.2.0 release (#30) + tag pushed

### Slipped
- None. TAT-063 declared done after assessment.

### Lessons
- L1: Never chain gh pr merge commands
- L2: Worktree agents may not land commits on expected branches
- L3: GPT code review is slow but quality is worth the wait

### Process Notes
- First sprint-end ever — checkpoint structure works
- Review gate enforced on all PRs, artifact trail useful
- Parallel delegation partially worked (worktree branch issue)
- Plan update PRs add friction with branch protection

## Sprint 8 — Workflow Fixes + Medium Publish
**Date:** 2026-04-01
**Goal met?** Yes — all 8 tasks shipped + article published to Dev.to

### Shipped
- TAT-085: tat-publish.sh for Medium + Dev.to (#42)
- TAT-086: POST-MERGE plan updates in feature branch (#42)
- TAT-087: GL-08 + Branch Guard fix (#42)
- TAT-088: GL-16 never push to protected main (#42)
- TAT-089: tat-gpt.sh RESPONSES_ONLY_MODELS fix (#42)
- TAT-090: SKILL.md deduplication (#42)
- TAT-091: TAT.md model routing table fix (#42)
- TAT-092: Init template + status sprint format (#42)
- Bonus: Dev.to image URL fix (#43)

### Slipped
- None

### Lessons
- L4: Use absolute URLs for images in published articles
- L5: Avoid em dashes in AI-generated content
- L6: Create platform-specific article files

### Process Notes
- Bundled 8 fixes into one PR — acceptable for fix sprints, not for feature work
- Article publish workflow needs platform-specific file generation in /article skill
- Consider a pre-publish image URL validator
