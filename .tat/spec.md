# TAT — Tiny AI Team

## What
An orchestration layer for Claude Code. Memory + review + coordination for AI-assisted development.

## What TAT Is
- Session flows: Coding, Planning, Design — each with steps, scripts, gates
- Persistent project state via `.tat/` (spec, plan, decisions, session log)
- Multi-model: Opus orchestrates, Sonnet codes, GPT reviews
- Task cards with fix-specs (What/Files/Reuse/Done) + subtasks

## What TAT Is Not
- Not a process framework — no sprints, no phases, no ceremonies
- Not a fully autonomous agent — user is product owner
- Not replacing Claude Code — orchestrating it

## Why
AI coding tools write code but lack long-term planning, decision memory, and multi-model coordination. TAT adds structure on top of existing tools.

## Architecture

### Commands
| Command | Session |
|---------|---------|
| `/tat` | Coding — load context, pick task, code, review, ship |
| `/tat brainstorm` | Planning — generate candidate tasks |
| `/tat replan` | Planning — reprioritize existing tasks |
| `/tat design <ID>` | Design — write fix-spec before coding |
| `/tat ask "<q>"` | GPT consult — inline question |
| `/tat status` | Dashboard — read-only |
| `/tat review` | Force GPT review of current branch |
| `/tat init` | Setup `.tat/` for new project |

### File Structure
**Per-project (`.tat/`):**
- `spec.md` — project definition (this file)
- `plan.md` — task cards with fix-specs + subtasks
- `decisions.md` — append-only ADRs with rationale
- `state.json` — task ID counter
- `aux/` — project artifacts (brainstorm drafts, proposals, research)
- `session.md` — session log (gitignored)
- `gpt.md` — GPT review cache (gitignored)

**Global (`~/.tinyaiteam/`):**
- `TAT.md` — canonical workflow rules and session flows
- `VERSION` — installed version
- `config.sh` — GPT model and budget settings
- `scripts/` — runtime scripts
- `hooks/` — git hooks (deployed per-project)

### Scripts
| Script | Purpose |
|--------|---------|
| `tat-gpt.sh` | Shared GPT API caller (model routing, cost tracking) |
| `ask-gpt.sh` | Inline GPT questions |
| `tat-code-review.sh` | Code diff review via GPT |
| `tat-gpt-watch.sh` | Background watcher — reads session + diff, writes gpt.md |
| `tat-state.sh` | Task ID counter management |
| `tat-pr-description.sh` | Generate PR description from artifacts |

### GPT Integration
- **Model routing:** configurable via `config.sh`
- **Cost guard:** daily budget, auto-downgrades model when exceeded
- **Review:** manual via `/tat review` or `tat-code-review.sh main`
- **ACK mechanism:** GPT must restate context before advising

## Constraints
- Claude Code skills — no external framework
- GPT via API (bash scripts with Python for JSON)
- All state is flat files (markdown + JSON counter)
- User is product owner — always in the loop
- Git discipline: branches, PRs, conventional commits

## Non-goals
- Complex state machines or phase tracking
- Sprint ceremonies or checkpoint maps
- Automatic GPT review on every commit
