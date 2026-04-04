# TAT v3 — Tiny AI Team

An orchestration layer for Claude Code. Memory + review + coordination.

## Invariants

These always apply, regardless of session type:

1. **User is product owner** — final authority on everything
2. **Git is source of truth** — branches, tags, PRs. No separate state machines
3. **Decisions are append-only** — `.tat/decisions.md` records why, not just what
4. **Graceful degradation** — missing artifacts = feature inactive, not error

## Where Things Belong

| Artifact | Contains | Must NOT contain |
|----------|----------|------------------|
| `spec.md` | What the project is + why + constraints | Task list, implementation details |
| `plan.md` | Tasks with fix-specs (What/File/Reuse/Done means) | Architecture rationale |
| `decisions.md` | ADRs — what we decided + why + alternatives rejected | Casual notes, task status |
| `session.md` | Live session log — decisions + GPT calls (gitignored) | Code, full diffs |
| `gpt.md` | Latest GPT review cache (generated, gitignored) | Anything hand-written |

## Fix-Spec Format

Every task gets a fix-spec before coding:

```
### TAT-XXX — Short title
- What: what changes
- File: which files
- Reuse: existing code to leverage
- Done means: how to verify it works
```

The fix-spec IS the design. Self-review and GPT review check against it.

## Session: Coding

```
Load → Pick → Branch → Code → Self-review → GPT review → Ship
```

After EVERY step, show progress bar with `▲` under current step.

| Step | What happens | Script/Tool | Gate |
|------|-------------|-------------|------|
| **Load** | Read spec, plan, decisions, gpt.md. Check branch | — | STOP if no `.tat/` or on `main` |
| **Pick** | Select next `[ ]` task, show fix-spec | `tat-state.sh` | STOP if ambiguous |
| **Branch** | Create `<TASK-ID>/<slug>` | `pre-commit` hook validates | STOP if on main or name invalid |
| **Code** | Implement the fix-spec. Off-scope ideas → backlog | — | Auto-proceed |
| **Self-review** | `git diff` — check scope, bugs, completeness against fix-spec | — | STOP if issues found |
| **GPT review** | Send diff + context to GPT. Show summary as table (Type/Issue/Action), never raw dump. Verdict: CLEARED/BLOCKED/NEEDS_INPUT | `tat-code-review.sh main` | STOP if BLOCKED |
| **Ship** | Commit, mark `[x]`, push, create PR | `commit-msg` hook, `tat-pr-description.sh` | STOP — user merges |

## Session: Planning

```
Load → Brainstorm/Replan → GPT consult → Update plan
```

| Step | What happens | Script/Tool | Gate |
|------|-------------|-------------|------|
| **Load** | Read spec, plan, decisions | — | Auto-proceed |
| **Brainstorm/Replan** | Generate or reorder tasks as fix-specs | — | STOP if coding urge |
| **GPT consult** | Ask GPT for prioritization/sequencing | `ask-gpt.sh` | Advisory only |
| **Update plan** | Edit plan.md, record decisions if durable | — | STOP until consistent |

## Session: Design

```
Load → Pick task → Write fix-spec → GPT consult → Approve
```

| Step | What happens | Script/Tool | Gate |
|------|-------------|-------------|------|
| **Load** | Read spec, plan, related decisions | — | Auto-proceed |
| **Pick task** | Select task needing spec work | — | STOP if no target |
| **Write fix-spec** | Draft What/File/Reuse/Done means | — | STOP if too vague |
| **GPT consult** | Review spec for gaps and edge cases | `ask-gpt.sh` | STOP if spec needs revision |
| **Approve** | User confirms spec is code-ready | — | STOP until approved |

## Model Routing

| Role | Model | When |
|------|-------|------|
| Orchestrator | Opus | Plans, specs, reviews, delegates |
| Coder | Sonnet | Implements tasks delegated by Opus |
| Reviewer | GPT (config.sh) | Code review, planning advice |

## Commands

| Command | Session type |
|---------|-------------|
| `/tat` | Coding (default) |
| `/tat brainstorm` | Planning |
| `/tat replan` | Planning |
| `/tat design <ID>` | Design |
| `/tat ask "<q>"` | GPT consult (any session) |
| `/tat status` | Read-only dashboard |
| `/tat init` | Setup `.tat/` |
| `/tat version` | Show version |

