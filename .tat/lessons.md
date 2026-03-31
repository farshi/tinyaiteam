# Lessons Learned

Lessons captured from sprint retros. Each lesson becomes a constraint that sprint-start loads before planning.

Format: `### L<N>. <Title>` with When, Source, Lesson, and Rule fields.

<!-- Sprint-end appends new lessons here. Sprint-start reads them as constraints. -->

### L1. Never chain gh pr merge commands
**When:** Sprint 6 retro
**Source:** User correction (happened twice — TAT and PatchPilot)
**Lesson:** Chaining `gh pr merge A && gh pr merge B` hides the success of A if B fails. User sees "already merged" on retry and thinks it's a bug.
**Rule:** Always run `gh pr merge` one at a time. Never chain with `&&`.

### L2. Worktree agents may not land commits on expected branches
**When:** Sprint 6 — parallel delegation of TAT-062 + TAT-064
**Source:** Self-review
**Lesson:** Sonnet agents with `isolation: "worktree"` created files but commits didn't always land on the named branch. The CONTRIBUTING PR (#35) silently included both agents' work. ADRs PR had no diff.
**Rule:** After parallel worktree agents return, verify each branch has the expected commits (`git log branch -1`) before creating PRs. If commits are missing, recreate manually.

### L3. GPT code review is slow (~5-8min) but quality is worth the wait
**When:** Sprint 6 — user asked about 8-minute review time
**Source:** User feedback
**Lesson:** gpt-5.4-mini takes 5-8 minutes for full reviews. Faster models (gpt-4o-mini) are available but lower quality. User explicitly chose to keep the better model.
**Rule:** Keep gpt-5.4-mini for code reviews. Don't optimize for speed at the cost of quality. Warn user about expected wait time.
