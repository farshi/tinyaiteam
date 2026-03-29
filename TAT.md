# TAT — Tiny AI Team: Workflow Rules

## The SSD Loop

Every task follows: **Spec → Subtask → Do**

```
USER says what they want
  → OPUS writes/updates spec + breaks into epics/tasks
  → SECOND BRAIN (GPT) critiques plan (for non-trivial plans)
  → USER approves/adjusts
  → OPUS picks next subtask, defines scope + guardrails
  → CODE the subtask (Opus if complex, Sonnet if simple)
  → AUTO-REVIEW by GPT (tiered — see below)
  → USER sees code + review, decides
  → Merge PR, update plan, pick next subtask
```

## Model Routing

| Task | Model | Reason |
|------|-------|--------|
| Planning, spec, architecture | Opus | Highest-leverage work needs strongest reasoning |
| Complex coding (multi-file, new systems) | Opus | Must hold the full architectural picture |
| Simple coding (fix, single file, small feature) | Sonnet | Fast, efficient, good enough |
| Which model to use | Opus decides | Self-routing based on task complexity |
| GPT review | gpt-4.1-mini | Cheap, fast second opinion |
| PR review before merge | Opus | Final technical authority (user is final authority) |

When `/tat` runs, it should suggest the right model: "This task is straightforward — switch to Sonnet" or "This is architectural — stay on Opus."

## Git Workflow

- One subtask = one branch = one PR
- Branch naming: `tat/<epic-number>/<task-name>` (e.g., `tat/1/foundation-setup`)
- Work on branch, push, create PR
- GPT reviews PR diff (auto-tiered)
- Opus or user evaluates review
- Merge PR, update plan.md on main

## Review Tiers

Not every change needs a deep review. The review tier is chosen automatically based on task type and diff size:

### Tier 1: Synopsis (small tasks)
**When**: fixes, doc changes, single-file changes, diff < 50 lines
**What GPT gets**: One-line summary of what was done + the task description
**Purpose**: Sanity check, not deep review

### Tier 2: Full Bundle (meaningful tasks)
**When**: new features, architectural changes, multi-file changes, diff > 50 lines
**What GPT gets**:
- Current task description from plan.md
- Scope: which files should change, which should NOT
- Guardrails: what constraints apply
- Full git diff (branch vs main)
- Content of new untracked files
- Relevant excerpt from spec.md

**Purpose**: Catch bugs, scope creep, architectural drift, missing edge cases

### Scope Validation
Before sending to GPT, check: does the actual diff match the declared scope? If files outside scope were touched, flag it immediately — don't wait for GPT to catch it.

## Context Bundle Format

The context bundle is what gets sent to GPT. It is auto-generated, never manually assembled.

```
## Task
<task description from plan.md>

## Scope
Files expected to change: <list>
Files NOT to change: <list or "everything else">

## Guardrails
<constraints for this task>

## Spec Context
<relevant excerpt from spec.md>

## Diff
<git diff output>

## New Files
<content of untracked files, if any>
```

## Project Structure

Each project using TAT has:
```
<project>/
└── .tat/
    ├── spec.md         # What we're building and why
    ├── plan.md         # Epics, tasks, status
    └── decisions/      # ADR files for non-obvious decisions
        └── 001-<title>.md
```

Global TAT config:
```
~/.tinyaiteam/
├── TAT.md              # This file (workflow rules)
└── config.sh           # GPT API settings
```

## Decision Records (ADR)

Only for non-obvious decisions. Format:

```markdown
# ADR-001: <Title>

## Context
<What situation prompted this decision>

## Options Considered
1. <Option A> — <tradeoff>
2. <Option B> — <tradeoff>

## Decision
<What we chose>

## Rationale
<Why — the reasoning, not just the conclusion>
```

## Source Tagging

When in TAT mode, tag all guidance, warnings, and workflow messages with their source. Normal conversation and code output is NOT tagged.

### Tags
- `[SYSTEM]` — Built-in Claude safety rules (destructive actions, security, reversibility checks)
- `[CLAUDE.md]` — User's global `~/.claude/CLAUDE.md` rules
- `[PROJECT]` — Project-level CLAUDE.md rules
- `[TAT]` — TAT workflow rules (from TAT.md or `.tat/` state)
- `[GPT]` — Feedback from GPT review

### When to tag
- Warnings and blocks: `[SYSTEM] This will delete the remote branch. Confirm?`
- Workflow guidance: `[TAT] Current task: Epic 2, Task 2.1 — switching to plan mode`
- Rule enforcement: `[CLAUDE.md] Entering plan mode — non-trivial task (3+ steps)`
- Review results: `[GPT] VERDICT: APPROVED — no issues found`
- Model routing: `[TAT] This is architectural — stay on Opus`

### When NOT to tag
- Normal conversation
- Code output
- Answering questions
- Tool calls

## Mode Activation

- `/tat` activates TAT mode for the session
- No explicit exit needed — session end or not invoking `/tat` means normal mode
- TAT is a way of working you invoke when you want structure, not a persistent state to manage

## Task Prioritization

After any plan change (new task, completed task, backlog capture), TAT re-evaluates priority:

- **Related to current epic** → offer to slot it in (before or after the current task)
- **Unrelated** → backlog, no disruption to current flow
- **Completed task unblocks something** → surface the unblocked task as the next candidate
- **Always explain the reasoning**: "[TAT] Moving task X before Y because it unblocks the API work"

TAT manages a living plan, not a dead checklist. Priority can shift — but only with explanation.

## GPT in the Planning Loop

Every planning update must go through GPT. No exceptions.

When Opus makes planning changes (new tasks, architecture decisions, spec updates, TAT rule changes):
1. Opus proposes the change
2. Run `tat-review.sh --plan` to get GPT's opinion
3. Present GPT's feedback with `[GPT]` tag
4. User decides what to act on
5. Then finalize the change

Skipping GPT during planning is a bug, not a shortcut. The whole point of TAT is multiple brains — if only one brain sees the plan, it's just regular AI coding with extra files.

## Rules for /tat Behavior

1. Always start in planning mode — never jump to code
2. Read .tat/ state before doing anything
3. Show current position: which epic, which task, what's next
4. Suggest model routing for the current task
5. Enforce the SSD loop — no skipping steps
6. User is product owner — final authority on everything
7. Tag all guidance with source (see Source Tagging above)
8. Re-prioritize tasks after any plan change (see Task Prioritization above)
9. Always run GPT plan review after planning changes (see GPT in the Planning Loop above)
