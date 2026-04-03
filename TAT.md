# TAT v2 — Tiny AI Team

## What TAT Is

An orchestration layer for Claude Code. Adds planning, multi-model coordination, and GPT as a background reviewer to AI-assisted development. Not a process framework — a memory + review + coordination layer.

## Core Loop

```
Pick next task → Branch → Code → Self-review → GPT reviews (background) → Ship → Repeat
```

No phases. No checkpoints. Just work through the task list, top to bottom.

## Model Routing

| Role | Model | What it does |
|------|-------|-------------|
| Orchestrator | Opus | Plans, specs, architecture, delegates to Sonnet |
| Coder | Sonnet | Codes tasks delegated by Opus |
| Background reviewer | GPT (gpt-4o-mini) | Auto-reviews diffs via hook, writes to .tat/gpt.md |
| Deep reviewer | GPT (gpt-5.2-codex) | Manual `/tat review` for complex changes |

Opus delegates coding to Sonnet subagents. GPT watches in background. User is product owner.

## File Structure

```
<project>/.tat/
  spec.md           # What + why + constraints
  plan.md           # Prioritized task list (top = next)
  decisions.md      # Key decisions with rationale (append-only)
  conversation.md   # Session log — User + Claude + GPT voices (gitignored)
  gpt.md            # GPT's latest review summary (auto-updated)
  gpt-cursor        # Last conversation entry GPT has reviewed

~/.tinyaiteam/
  TAT.md          # This file
  config.sh       # GPT model settings
  lessons.md      # Global lessons (one file, append-only)
  reports.md      # Real-time observations from any project
  scripts/        # Minimal script set
  hooks/          # Git hooks
```

## Plan Format

Prioritized task list. No sprints, no epics. Top = next.

```markdown
## Tasks
| ID | Task | Status |
|----|------|--------|
| TAT-110 | GPT background watcher | [ ] |
| TAT-111 | Next thing | [ ] |

## Done
| ID | Task | Status |
|----|------|--------|
| TAT-109 | GPT review fix | [x] |
```

- **Task IDs**: `TAT-XXX`, auto-generated via `tat-state.sh new-task-id`
- **Status**: `[x]` done, `[ ]` todo
- Mark tasks `[x]` on the feature branch before merge

## Git Workflow

- One task = one branch = one PR
- Branch naming: `tat/<task-name>`
- Conventional commits: `feat(scope): description`
- Never commit directly to main

## GPT Integration

**Background (automatic):** Claude Code PostToolUse hook triggers GPT review on commits. GPT reads unseen conversation entries + code diff. Responses written back into `conversation.md`. Summary in `gpt.md`.

**On-demand:** `/tat review` forces immediate GPT review.

**Conversation log:** Claude appends to `.tat/conversation.md` after every user turn. Three voices — User, Claude, GPT. GPT sees intent, approach, corrections — not just final code.

**`!!` red flag:** User prefixes with `!!` for urgent GPT attention. Triggers immediate review.

**Self-review first (always).** Claude reads its own diff before GPT sees it.

## Lessons

One global file: `~/.tinyaiteam/lessons.md`. Append-only. No lifecycle states.

Capture anytime via `/tat report`. Don't wait for retros.

## Source Tagging

Tag guidance with source: `[TAT]`, `[GPT]`, `[OPUS]`, `[SYSTEM]`, `[CLAUDE.md]`, `[PROJECT]`.
Normal conversation and code output is not tagged.

## Commands

| Command | What it does |
|---------|-------------|
| `/tat` | Load context, pick next task, create branch, go |
| `/tat status` | Show plan progress (read-only) |
| `/tat review` | Force GPT deep review |
| `/tat report` | Log observation to ~/.tinyaiteam/reports.md |
| `/tat replan` | Reprioritize with GPT |
| `/tat init` | Setup .tat/ for new project |
| `/tat version` | Show installed version |

## Rules

1. User is product owner — final authority
2. GPT is advisor, not gatekeeper
3. Self-review before GPT review
4. One task = one branch = one PR
5. Never work on main
6. Off-scope ideas go to bottom of plan.md
7. Tag your guidance with source
