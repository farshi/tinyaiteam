# Lessons Learned

Lessons captured from sprint retros. Each lesson becomes a constraint that sprint-start loads before planning.

Format: `### L<N>. <Title>` with Status, When, Source, Lesson, and Rule fields.

<!-- Lesson lifecycle: [active] = enforced at sprint-start, [applied] = graduated into code/config/habit, no longer loaded -->

<!-- Sprint-end appends new lessons here. Sprint-start reads them as constraints. -->

### L1. Never chain gh pr merge commands
**Status:** [active]
**When:** Sprint 6 retro
**Source:** User correction (happened twice — TAT and PatchPilot)
**Lesson:** Chaining `gh pr merge A && gh pr merge B` hides the success of A if B fails. User sees "already merged" on retry and thinks it's a bug.
**Rule:** Always run `gh pr merge` one at a time. Never chain with `&&`.

### L2. Worktree agents may not land commits on expected branches
**Status:** [active]
**When:** Sprint 6 — parallel delegation of TAT-062 + TAT-064
**Source:** Self-review
**Lesson:** Sonnet agents with `isolation: "worktree"` created files but commits didn't always land on the named branch. The CONTRIBUTING PR (#35) silently included both agents' work. ADRs PR had no diff.
**Rule:** After parallel worktree agents return, verify each branch has the expected commits (`git log branch -1`) before creating PRs. If commits are missing, recreate manually.

### L3. GPT code review is slow (~5-8min) but quality is worth the wait
**Status:** [active]
**When:** Sprint 6 — user asked about 8-minute review time
**Source:** User feedback
**Lesson:** gpt-5.4-mini takes 5-8 minutes for full reviews. Faster models (gpt-4o-mini) are available but lower quality. User explicitly chose to keep the better model.
**Rule:** Keep gpt-5.4-mini for code reviews. Don't optimize for speed at the cost of quality. Warn user about expected wait time.

### L4. Use absolute URLs for images in published articles
**Status:** [active]
**When:** Sprint 8 — Dev.to article publish
**Source:** Bug (user reported broken images)
**Lesson:** Dev.to rewrites image src through its CDN proxy. Relative paths (`../assets/foo.png`) become unresolvable. Only absolute GitHub raw URLs work.
**Rule:** All images in platform article files (devto.md, medium.md) must use `https://raw.githubusercontent.com/...` URLs. Never relative paths.

### L5. Avoid em dashes in AI-generated content
**Status:** [active]
**When:** Sprint 8 — article cleanup
**Source:** User feedback
**Lesson:** Heavy em dash usage is widely recognized as "AI slop." Readers notice and it hurts credibility.
**Rule:** Replace em dashes with periods, colons, or commas. Use short declarative sentences instead.

### L6. Create platform-specific article files
**Status:** [active]
**When:** Sprint 8 — Dev.to publish
**Source:** Self-review
**Lesson:** Medium and Dev.to have different frontmatter formats (Medium: `tags: [AI, Tools]`, Dev.to: `tags: ai, tools` + `published: false`). A single file can't serve both.
**Rule:** Create separate `platform/devto.md` and `platform/medium.md` files with platform-appropriate frontmatter.

### L7. Never sweep unexpected review results under the carpet
**Status:** [active]
**When:** Sprint 9 — GPT returned "LOW CONFIDENCE — no stated task"
**Source:** User correction
**Lesson:** GPT review returned low confidence because it had no task context. I dismissed it as "expected since we skipped checkpoints." User caught this and pushed back. The root cause was a format mismatch in the review script that had been broken since Sprint 5.
**Rule:** When any check, review, or gate returns unexpected results, STOP and investigate the root cause. Never rationalize away warnings. The system is telling you something is broken.

### L8. Backlog tasks must carry context via Ref: links
**Status:** [active]
**When:** Sprint 9 — backlog tasks had no traceability
**Source:** User feedback
**Lesson:** Backlog tasks like "add /tat wrapup" had no link to the ADR, lesson, or GPT consultation that informed them. When sprint-start picks them up, the planning context is lost.
**Rule:** Every backlog task must include `Ref:` pointing to related ADRs, GLs, or GPT consultations. Context travels with the task.

### L9. Format changes must update all downstream consumers
**Status:** [active]
**When:** Sprint 9 — plan.md format change broke 3 scripts
**Source:** Self-review (drift audit)
**Lesson:** ADR-005 changed plan.md from checkbox to table format in Sprint 5, but tat-code-review.sh, tat-pr-description.sh, and ask-gpt.sh were never updated. The scripts silently returned empty results for ~40 PRs.
**Rule:** When changing a data format (plan.md, lessons.md, state.json), grep the entire codebase for consumers of that format and update them in the same PR.
