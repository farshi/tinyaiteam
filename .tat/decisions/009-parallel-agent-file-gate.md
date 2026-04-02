# ADR-009: Hard File-Overlap Gate for Parallel Agents

## Context
Sprint 9: two parallel Sonnet agents were launched for version-awareness and lesson-lifecycle. Both modified `skills/tat/SKILL.md`, causing sequential rebase/conflict resolution. Additionally, ad-hoc edits to `plan.md` on feature branches created unstaged changes that blocked rebases. Worktree agents based on stale main missed recent changes (L4-L6 lessons), requiring manual fixes.

## Decision
1. **File-overlap gate is mandatory before parallel delegation.** List all files each task will touch. If ANY file appears in both lists, tasks MUST run sequentially, not in parallel. This is a hard gate, not advice.

2. **Never edit plan.md on a feature branch unless it's part of the task's commit.** Backlog captures and plan updates should be staged and committed immediately, not left as unstaged changes.

3. **Sync main before spawning worktree agents.** Ensure all pending PRs that affect shared state (lessons, plan, spec) are merged first.

## Rationale
Parallel agents save time only when tasks are truly independent. File overlap means sequential rebases, merge conflicts, and manual fixups — which cost more time than sequential execution. The "check file overlap" advice in SKILL.md was too soft and got ignored under speed pressure.

## Rules
- Before parallel delegation: `git diff main --name-only` each task's expected files. Overlap = sequential.
- Shared files (SKILL.md, plan.md, lessons.md, install.sh) are red flags for parallelization.
- If in doubt, run sequentially. The cost of a conflict is higher than the cost of waiting.
