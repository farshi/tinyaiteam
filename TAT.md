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

## Rules for /tat Behavior

1. Always start in planning mode — never jump to code
2. Read .tat/ state before doing anything
3. Show current position: which epic, which task, what's next
4. Suggest model routing for the current task
5. Enforce the SSD loop — no skipping steps
6. User is product owner — final authority on everything
