# Decisions

Key decisions with rationale. Append-only.

### ADR-001: TAT Mode Switching
Option 2: Skill-based activation. `/tat` enters TAT mode for the session. No explicit exit — start a new session or just stop using `/tat`.
**Why:** TAT is a way of working you invoke when you want structure, not a persistent mode you need to manage. Skills already work this way in Claude Code. Adding toggle state adds complexity with no real benefit.

### ADR-002: Source Tagging in Output
Option 3: Tag guidance and warnings with their source. Normal conversation and code output is untagged.
**Why:** User observed that a repo deletion warning appeared without explanation of where the rule came from. Source tags create transparency — you know which layer is speaking and can override or adjust the right config. Only applied to guidance/warnings to avoid noise in normal output.

### ADR-003: GPT Must Review All Planning Changes
Option 2: Every planning update runs through `tat-review.sh --plan`. No exceptions.
**Why:** If GPT only reviews when asked, the default behavior is single-brain planning — exactly what TAT exists to prevent. The friction of running one API call is negligible compared to the value of a second opinion. This was a real bug caught in dogfooding.

### ADR-004: GPT Must Review PRs Before Merge
GPT reviews every PR before merge, starting now. Even before the automation is built, run `tat-review.sh main` manually from the PR branch before merging. If a principle is agreed, enforce it immediately — don't wait for automation.
**Why:** Waiting for automation to enforce an agreed rule is a form of skipping the rule. The manual step takes 10 seconds. The value of a second opinion before merge is the core promise of TAT.

### ADR-005: Sprint-Based Plan Format
Option 2: Plans use sprint tables with TAT-XXX task IDs. Each sprint is a time-boxed table of tasks with status, owner, and ID. Epics remain as high-level groupings but execution is tracked at the sprint level.
**Why:** Epics define what, sprints define order. Without sprint ordering, work is prioritized ad hoc. TAT-XXX IDs enable traceability across commits, PRs, and ADRs. The format was already proven in PatchPilot — no reason to invent a different convention for TAT itself.

### ADR-006: Graceful Degradation for Cross-Project Compatibility
Option 2: New features fail silently when their artifacts don't exist. A missing `state.json` means the feature is inactive, not an error. A missing review gate config means the gate is skipped.
**Why:** `install.sh` deploys globally. We cannot gate a global deploy on every active project being migration-ready. Graceful degradation means TAT can ship improvements continuously without coordinating upgrades across all projects. Projects adopt new features by adding the artifact, not by unblocking a deploy.

### ADR-007: Sprint Ceremonies (Start / End)
Option 2: Sprint ceremonies are required. Sprint-start reads `.tat/decisions/` and `tasks/lessons.md` as constraints before planning. Sprint-end captures new lessons into `tasks/lessons.md`. The loop closes at the sprint boundary.
**Why:** Lessons that aren't loaded are lessons ignored. Decisions that aren't loaded as constraints can be re-litigated or unknowingly violated. Sprint ceremonies are the mechanism that makes the TAT feedback loop real rather than aspirational. The cost is low (a few file reads); the benefit is drift prevention and compounding quality.

### ADR-008: No gstack Dependency in v1
Option 2: gstack integration dropped from v1. TAT-058 and TAT-059 are moved to v2 backlog. TAT's built-in review flow (GPT via `ask-gpt.sh`, Opus planning, Sonnet coding) is sufficient for v1. Skill adapters are a v2 concern.
**Why:** v1 should be self-contained with no hidden dependencies. A user who installs TAT via `install.sh` should get the full v1 workflow without needing to install gstack separately. Skill adapters add architectural complexity that isn't justified until the core workflow is proven across multiple projects.

### ADR-009: Hard File-Overlap Gate for Parallel Agents
1. **File-overlap gate is mandatory before parallel delegation.** List all files each task will touch. If ANY file appears in both lists, tasks MUST run sequentially, not in parallel. This is a hard gate, not advice.

2. **Never edit plan.md on a feature branch unless it's part of the task's commit.** Backlog captures and plan updates should be staged and committed immediately, not left as unstaged changes.

3. **Sync main before spawning worktree agents.** Ensure all pending PRs that affect shared state (lessons, plan, spec) are merged first.
**Why:** Parallel agents save time only when tasks are truly independent. File overlap means sequential rebases, merge conflicts, and manual fixups — which cost more time than sequential execution. The "check file overlap" advice in SKILL.md was too soft and got ignored under speed pressure.

