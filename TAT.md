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
  gpt.md            # GPT's latest review summary (auto-updated)

~/.tinyaiteam/
  TAT.md          # This file
  config.sh       # GPT model settings
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

**Review flow:** GPT reviews on request (`/tat review`, `tat-code-review.sh main`) or after 3+ user turns (gated, not automatic). GPT reads session entries + diff, writes responses back into session.md.

**`@@` red flag:** User prefixes with `@@` for urgent GPT attention.

**Self-review first (always).** Claude reads its own diff before GPT sees it.


## Source Tagging

Tag guidance with source: `[TAT]`, `[GPT]`, `[OPUS]`, `[SYSTEM]`, `[CLAUDE.md]`, `[PROJECT]`.
Normal conversation and code output is not tagged.

## Commands

| Command | What it does |
|---------|-------------|
| `/tat` | Load context, pick next task, create branch, go |
| `/tat status` | Show plan progress (read-only) |
| `/tat review` | Force GPT deep review |
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

## Progress Bar (MANDATORY)

After EVERY step, show this bar with `▲` under the current step:

```
Load → Pick → Branch → Code → Self-review → GPT review → Ship
                                ▲
                             YOU ARE HERE
```

## GPT Review Display (MANDATORY)

Summarize GPT results as a table — never dump raw output:

```
GPT says (TAT-XXX):
| # | Type | Issue | Action |
|---|------|-------|--------|
| 1 | BLOCKER | description | fix needed |
| 2 | SUGGESTION | description | skip/fix/defer |

Verdict: CLEARED / BLOCKED / NEEDS_INPUT
```

Then show the progress bar.

## Working Flow

1. **Load** — read spec, plan, decisions, gpt.md
2. **Pick** — select next `[ ]` task, show fix-spec
3. **Branch** — create/switch to `<TASK-ID>/<slug>`
4. **Code** — implement the fix-spec. Stay in scope. Off-topic → backlog
5. **Self-review** — `git diff`, check scope/bugs/completeness
6. **GPT review** — run `tat-code-review.sh main`, show summary table
7. **Ship** — commit, mark `[x]`, push, create PR. User merges.

**Gates:**
- Auto-proceed: Load, Branch, Code (unless decision needed)
- STOP: Pick (if ambiguous), Self-review (if issues), GPT review (if BLOCKED), Ship (user merges)

## Rules

1. User is product owner — final authority
2. GPT is advisor, not gatekeeper
3. Spec before code — every task gets: what changes, what to reuse, done means
4. Self-review your diff before GPT sees it
5. One task = one branch = one PR
6. Never commit directly to main — plan updates go in the feature branch
7. Never auto-merge — create PR, read GPT review, show user, user decides
8. Never chain `gh pr merge` with `&&` — one merge at a time
9. Never bypass hooks — fix the root cause, don't use `TAT_FORCE=1`
10. Branch: `<TASK-ID>/<slug>`, commit: `type(scope): description (TASK-ID)`
11. Off-scope ideas go to bottom of plan.md
12. Tag guidance with source: `[TAT]`, `[GPT]`, `[OPUS]`
13. Log `[User]` entry in session.md after every user turn
14. Sync main and check file overlap before spawning parallel agents
15. Announce what you're doing — silence is bad UX
