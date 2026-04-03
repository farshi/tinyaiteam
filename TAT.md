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
  session.md        # Live session log — User + Opus + GPT voices (gitignored)
  today.md          # Daily scope — goals, mode, constraints (gitignored)
  gpt.md            # GPT's latest review summary (auto-updated)
  gpt-cursor        # Last session entry GPT has reviewed

~/.tinyaiteam/
  TAT.md          # This file
  config.sh       # GPT model settings
  lessons.md      # Global lessons (one file, append-only)
  reports.md      # Real-time observations from any project
  scripts/        # Minimal script set
  hooks/          # Git hooks
```

## Plan Format

Tasks grouped by version milestone. Current version = latest git tag. Next version = plan header.

```markdown
## Next: v2.2.0
| ID | Task | Status |
|----|------|--------|
| TAT-112 | Version-based planning | [ ] |
| TAT-105 | Optimize GPT review payloads | [ ] |

## Backlog
| ID | Task | Status |
|----|------|--------|
| TAT-068 | Skill adapter hooks | [ ] |

## Done
| ID | Task | Status |
|----|------|--------|
| TAT-111 | Task-ID branch naming | [x] |
```

- **Versions**: derived from git tags. Plan header declares next target.
- **Task IDs**: `<PREFIX>-XXX`, auto-generated via `tat-state.sh new-task-id`
- **Status**: `[x]` done, `[ ]` todo
- Mark tasks `[x]` on the feature branch before merge
- When all tasks in a version are done → bump VERSION, update CHANGELOG, tag

## Git Workflow

- One task = one branch = one PR
- Branch naming: `<TASK-ID>/<slug>` (e.g. `tat-101/update-spec`, `om-083/history-fetch`)
- Conventional commits: `feat(scope): description (TASK-ID)` — hooks enforce both
- Never commit directly to main

## GPT Integration

**Three-Chair Model:** User (Product Owner) + GPT (Senior Advisor) + Opus (Orchestrator). Each has a role that changes by mode (Design/Planning/Coding/Review).

**Session log:** Claude appends to `.tat/session.md` after every user turn. All three voices. GPT sees intent, approach, corrections — not just final code.

**GPT briefing:** Every GPT call gets: MODE + TODAY + DECISIONS + SESSION + DIFF. GPT must ACK context before advising.

**Background (automatic):** PostToolUse hook triggers GPT review on commits. GPT reads unseen session entries + diff, writes responses back into session.md.

**`@@` red flag:** User prefixes with `@@` for urgent GPT attention.

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

## GPT Call Points

Call `tat-gpt-watch.sh` at these checkpoints — not just on commits:
- End of planning discussion (before coding starts)
- Before creating a PR
- When user asks for GPT's opinion
- After 3+ user turns without a GPT call

## Session Log Enforcement

Log `[User]` entries in session.md after EVERY user turn — no exceptions.
Summarize intent in one line, don't quote verbatim.
Without user entries, GPT has no planning context and the audit trail is broken.

## Rules

1. User is product owner — final authority
2. GPT is advisor, not gatekeeper
3. Self-review before GPT review
4. One task = one branch = one PR
5. Never work on main
6. Off-scope ideas go to bottom of plan.md
7. Tag your guidance with source
