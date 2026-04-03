# TAT — Tiny AI Team

## What
An orchestration layer for Claude Code. Adds planning, multi-model coordination (Opus plans, Sonnet codes, GPT reviews), and persistent project memory to AI-assisted development.

## What TAT Is
- A core loop: Pick task → Branch → Code → Self-review → GPT review → Ship → Repeat
- Persistent project state via `.tat/` files (spec, plan, decisions, session log, GPT notes)
- Three-Chair Model: User (Product Owner) + GPT (Senior Advisor) + Opus (Orchestrator)
- Multi-model coordination with GPT as background reviewer
- A system that captures lessons globally across projects

## What TAT Is Not
- Not a process framework — no sprints, no phases, no ceremonies
- Not a fully autonomous agent — user is product owner
- Not replacing Claude Code — orchestrating it

## Why
AI coding tools write code but lack long-term planning, decision memory, and multi-model coordination. TAT adds memory and review on top of existing tools.

## Architecture

### Commands
| Command | Purpose |
|---------|---------|
| `/tat` | Full activation — load context, pick next task, start working |
| `/tat status` | Show plan progress, current task, open PRs |
| `/tat init` | Initialize `.tat/` directory for a new project |
| `/tat review` | Force GPT review of current branch |
| `/tat report` | Log observation to `~/.tinyaiteam/reports.md` |
| `/tat replan` | Reprioritize tasks with GPT input |
| `/tat version` | Show installed version |

### File Structure
**Per-project (`.tat/`):**
- `spec.md` — project definition (this file)
- `plan.md` — prioritized task list (Tasks + Done tables)
- `decisions.md` — append-only ADRs with rationale
- `gpt.md` — latest GPT review summary (auto-updated)
- `gpt-cursor` — tracks last session.md line GPT has seen
- `state.json` — task ID counter
- `session.md` — live session log, all three voices (gitignored)
- `today.md` — daily scope and goals (gitignored)

**Global (`~/.tinyaiteam/`):**
- `TAT.md` — master workflow rules
- `VERSION` — installed version
- `config.sh` — model and budget configuration
- `lessons.md` — universal lessons across all projects
- `reports.md` — cross-project observations
- `replan.log` — replan history timestamps
- `scripts/` — GPT integration and utility scripts
- `hooks/` — git hooks (commit-msg, pre-commit, pre-push)

### Scripts
| Script | Purpose |
|--------|---------|
| `tat-gpt.sh` | Shared GPT API caller (model routing, cost tracking) |
| `ask-gpt.sh` | Inline GPT questions |
| `tat-code-review.sh` | Code diff review via GPT |
| `tat-gpt-watch.sh` | Background watcher — reads session + diff, writes to gpt.md |
| `tat-gpt-gate.sh` | 3-turn gate — auto-triggers GPT after 3+ user turns |
| `tat-state.sh` | Task ID counter management |
| `tat-pr-description.sh` | Generate PR description from artifacts |
| `tat-publish.sh` | Medium/Dev.to article publishing |

### GPT Integration
- **Model routing:** `gpt-5.2-codex` for code review, `gpt-5.4-mini` for planning/brainstorming
- **Cost guard:** daily budget ($3 default), auto-downgrades model when exceeded
- **Review flow:** manual via `/tat review` or `tat-code-review.sh main`
- **GPT briefing:** every call gets MODE, TODAY, LAST DECISIONS, SESSION context
- **ACK mechanism:** GPT must restate context before advising

### Git Workflow
- One task = one branch = one PR
- Branch naming: `<TASK-ID>/<slug>` (e.g. `om-083/history-fetch`)
- Commits: `type(scope): description (TASK-ID)` — hooks enforce both
- Never commit code directly to main (`.tat/` metadata allowed)
- Self-review diff before GPT review

## Constraints
- Built as Claude Code skills — no external framework
- GPT integration via API calls (bash scripts with Python for JSON)
- All state is flat files (markdown + JSON counter)
- User is always in the loop as product owner
- Git discipline: branches, PRs, conventional commits

## Non-goals
- Complex state machines or phase tracking
- Sprint ceremonies or checkpoint maps
- Automatic GPT review on every commit (review is manual/gated)
- gstack or external tool dependencies in core workflow

## Key Principles
- Git is source of truth — no phase tracking, derive state from branches/PRs
- GPT reviews on request — manual trigger, not automatic hook
- Self-review before GPT — Claude reads its own diff first
- User is product owner — final authority on everything
- Decisions tracked in `.tat/decisions.md` (single file, append-only)
- Lessons are global — earned in one project, available in all
- Graceful degradation — missing artifacts mean feature inactive, not error
