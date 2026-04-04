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

## Sprint 9 — Version Awareness + Lesson Lifecycle
**Date:** 2026-04-02
**Goal met?** Yes — all 7 planned tasks shipped + 4 bonus fixes + 3 process improvements

### Shipped
- TAT-093: VERSION file + CHANGELOG.md (#45)
- TAT-094: install.sh deploys VERSION (#45)
- TAT-095: /tat activation shows version (#45)
- TAT-096: Tag v0.4.0 (tag pushed)
- TAT-097: [active]/[applied] lesson markers (#46)
- TAT-098: Sprint-start filters [active] lessons (#46)
- TAT-099: /tat graduate command (#46)
- Bonus: Fix plan.md parsing — GPT reviews blind since Sprint 5 (#47)
- Bonus: Revert GPT models to gpt-5.2-codex (#48)
- Bonus: Backlog Ref: links pattern (#49)
- Bonus: TAT-067 replan design spec (#50)
- ADR-009: hard file-overlap gate for parallel agents
- GL-17/18/19: parallel agent safeguards
- Script paths fixed (./scripts/ → ~/.tinyaiteam/scripts/)

### Slipped
- None

### Lessons
- L7: Never sweep unexpected review results under the carpet
- L8: Backlog tasks must carry context via Ref: links
- L9: Format changes must update all downstream consumers

### Process Notes
- Combining 7 tasks into 2 PRs broke review context (GPT couldn't identify which task). ADR-009 now gates this.
- Drift audit found major spec divergence — spec.md hasn't been updated in months (TAT-101)
- Parallel agents touching shared files (SKILL.md) caused rebase conflicts. Now a hard gate.
- Sprint was reactive — found crooked brick, fixed it, found more. Good for quality but sprint-start should catch format mismatches earlier.
- New commands designed: /tat wrapup (TAT-104), /tat replan (TAT-067 updated)
- ask-gpt.sh upgraded from gpt-4o-mini to gpt-5.2-codex for better advisory quality
