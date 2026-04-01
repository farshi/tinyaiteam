# TAT Global Lessons Library

Universal lessons earned across TAT-managed projects. These apply to ANY project using TAT, not just the project where they were discovered.

Loaded by `/tat sprint-start` alongside project-local `.tat/lessons.md`. Sprint-start identifies which lessons are relevant to the current sprint's tasks.

---

## Reviews & Quality

### GL-01. Run code review after every task
**Source:** oneminuta Sprint 3 (Codex caught a security bug that self-review missed)
**Rule:** Run `tat-code-review.sh main` after each task. Address blockers before moving on. This is not optional.

### GL-02. Use the right GPT model for the right job
**Source:** oneminuta Sprint 2-3, devsecops Sprint 1
**Rule:** Code review = gpt-5.3-codex. Plan review = gpt-5.3-codex. Brainstorming = gpt-4o-mini. Never use the cheapest model for critical reviews. Always respect `config.sh` model settings — don't hardcode.

### GL-03. Schema and infrastructure changes need GPT review before applying
**Source:** oneminuta Sprint 3
**Rule:** All schema changes, infra config, and deployment changes must go through GPT review before being applied. Copy to clipboard, but don't tell user to run until review is done.

### GL-04. Self-review before GPT review — always
**Source:** TAT Sprint 6, devsecops Sprint 2
**Rule:** Read the diff, check scope, fix issues — THEN send to GPT. GPT is a second opinion, not a substitute for your own QA.

---

## Scripts & Shell Safety

### GL-05. GPT review payloads must be small
**Source:** devsecops Task 2.0+
**Rule:** Trim context to spec summary (~7 lines) + current task description. Large payloads break GPT calls or produce garbage.

### GL-06. Shell escaping breaks GPT calls silently
**Source:** devsecops (every code review with special chars)
**Rule:** Never use shell string interpolation for JSON payloads. Use Python + temp files for JSON construction. All GPT scripts must handle any content safely.

### GL-07. grep + set -e = silent death
**Source:** devsecops `tat-code-review.sh`
**Rule:** Any grep in TAT scripts that might not match needs `|| true`. `set -euo pipefail` kills the script silently when grep returns exit 1.

---

## Git & Branch Discipline

### GL-08. Include plan updates in the feature branch
**Source:** TAT Sprint 7 (POST-MERGE tried to push to protected main — blocked by branch protection)
**Rule:** Never commit directly to main — not even plan.md updates. Include plan status updates ([x] marks) in the feature branch before creating the PR. This avoids branch protection conflicts and eliminates throwaway PRs for housekeeping.

### GL-09. Never chain gh pr merge commands
**Source:** TAT Sprint 6 (happened twice — TAT and PatchPilot)
**Rule:** Always run `gh pr merge` one at a time. Never chain with `&&`. Chaining hides the success of the first if the second fails.

### GL-10. Don't force-override hooks — fix the root cause
**Source:** devsecops post-Epic 2
**Rule:** When a TAT hook blocks a commit, don't use `TAT_FORCE=1` to bypass it. Investigate WHY it blocked. Learn from failures, don't mask them.

---

## Workflow & Process

### GL-11. In auto-mode, announce what you're doing
**Source:** devsecops Task 2.3b (user couldn't see what was being coded)
**Rule:** After creating a branch, always print 2-3 lines saying what task is being implemented and what it does. Silence for minutes is bad UX.

### GL-12. Lessons come from everywhere — capture all of them
**Source:** devsecops Task 2.3b
**Rule:** Lessons can come from Opus (self-review insights), GPT (review feedback), or the user (corrections/preferences). All should be captured. This library exists because of this lesson.

### GL-13. Don't build without a plan — even for docs
**Source:** devsecops user feedback
**Rule:** Any request — including documentation — should go through the plan first. No ADR = no decision captured = no traceability.

---

## Security

### GL-14. Never expose secrets — rotate immediately
**Source:** oneminuta Sprint 3 (accidental `export` without args dumped all env vars)
**Rule:** Never run bare `export` command. Always use `! export VAR=value` with the specific variable. If secrets are exposed, rotate ALL affected keys immediately — don't wait.

---

## Worktree & Parallel Agents

### GL-15. Verify worktree agent commits before creating PRs
**Source:** TAT Sprint 6 (parallel delegation of TAT-062 + TAT-064)
**Rule:** After parallel worktree agents return, verify each branch has the expected commits (`git log branch -1`) before creating PRs. Commits may land on wrong branches silently.

---

## Branch Protection

### GL-16. Never push directly to protected main
**Source:** TAT Sprint 7 (POST-MERGE checkpoint failed — GitHub branch protection blocked `git push origin main`)
**Rule:** If a project uses `/tat init` (which enables branch protection), all changes — including plan.md updates — must go through PRs. The POST-MERGE checkpoint should NOT try to commit and push to main. Instead, include plan updates in the feature branch before merge.
