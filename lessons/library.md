# TAT Lessons

Universal lessons earned across TAT-managed projects. Loaded at `/tat` activation.

---

## Reviews & Quality

### GL-01. Run code review after every task
**Source:** oneminuta Sprint 3
**Rule:** Run `tat-code-review.sh main` after each task. Address blockers before moving on.

### GL-02. Use the right GPT model for the right job
**Source:** oneminuta Sprint 2-3, devsecops Sprint 1
**Rule:** Code review = gpt-5.2-codex. Brainstorming = gpt-4o-mini. Respect `config.sh` settings.

### GL-03. Schema and infrastructure changes need GPT review before applying
**Source:** oneminuta Sprint 3
**Rule:** All schema/infra/deployment changes must go through GPT review first.

### GL-04. Self-review before GPT review — always
**Source:** TAT Sprint 6, devsecops Sprint 2
**Rule:** Read the diff, check scope, fix issues — THEN send to GPT.

---

## Scripts & Shell Safety

### GL-05. GPT review payloads must be small
**Source:** devsecops Task 2.0+
**Rule:** Trim context to spec summary + task description. Large payloads break GPT calls.

### GL-06. Shell escaping breaks GPT calls silently
**Source:** devsecops
**Rule:** Use Python + temp files for JSON construction. Never shell string interpolation.

### GL-07. grep + set -e = silent death
**Source:** devsecops
**Rule:** Any grep in TAT scripts that might not match needs `|| true`.

---

## Git & Branch Discipline

### GL-08. Include plan updates in the feature branch
**Source:** TAT Sprint 7
**Rule:** Never commit directly to main. Include plan [x] marks in the feature branch before PR.

### GL-09. Never chain gh pr merge commands
**Source:** TAT Sprint 6
**Rule:** Always run `gh pr merge` one at a time. Never chain with `&&`.

### GL-10. Don't force-override hooks — fix the root cause
**Source:** devsecops
**Rule:** When a hook blocks a commit, investigate WHY. Don't use `TAT_FORCE=1`.

---

## Workflow

### GL-11. In auto-mode, announce what you're doing
**Source:** devsecops Task 2.3b
**Rule:** After creating a branch, print 2-3 lines about the task. Silence is bad UX.

### GL-12. Lessons come from everywhere — capture all of them
**Source:** devsecops Task 2.3b
**Rule:** Opus, GPT, or user corrections — all worth capturing via `/tat report`.

### GL-13. Don't build without a plan — even for docs
**Source:** devsecops
**Rule:** Any request should go through the plan first.

---

## Security

### GL-14. Never expose secrets — rotate immediately
**Source:** oneminuta Sprint 3
**Rule:** Never run bare `export`. If secrets are exposed, rotate immediately.

---

## Parallel Agents

### GL-15. Verify worktree agent commits before creating PRs
**Source:** TAT Sprint 6
**Rule:** After parallel agents return, verify each branch has expected commits.

### GL-16. Never push directly to protected main
**Source:** TAT Sprint 7
**Rule:** All changes go through PRs. Include plan updates in feature branch.

### GL-17. Hard file-overlap gate before parallel agents
**Source:** TAT Sprint 9
**Rule:** List files per task. Any overlap = run sequentially. Shared files are red flags.

### GL-18. Sync main before spawning worktree agents
**Source:** TAT Sprint 9
**Rule:** Merge pending PRs before spawning worktree agents. Stale main = stale work.

### GL-19. Never leave unstaged edits on a feature branch
**Source:** TAT Sprint 9
**Rule:** Commit or stash immediately. Unstaged changes block rebases.

---

## Session Discipline

### GL-20. Log [User] entries in session.md — every turn
**Source:** oneminuta Sprint 5, 2026-04-03
**Rule:** After every user message, append a `[User]` bullet to session.md summarizing their intent. Without these, GPT is blind during planning and the audit trail is useless.
