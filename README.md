# TAT — Tiny AI Team

**Stop using AI like a solo developer. Use it like a team.**

TAT is a lightweight orchestration layer for [Claude Code](https://claude.ai/code) that adds planning, multi-model coordination, and persistent memory to AI-assisted development.

## What TAT Is

- A **core loop**: Pick task → Branch → Code → Self-review → GPT review → Ship → Repeat
- **Three-Chair Model**: User (Product Owner) + GPT (Senior Advisor) + Opus (Orchestrator)
- **Persistent project state** via `.tat/` files (spec, plan, decisions, session log)
- **Multi-model coordination**: Opus plans, Sonnet codes, GPT reviews in background
- **Version-based milestones**: tasks grouped by release, derived from git tags

## What TAT Is Not

- Not a process framework — no sprints, no ceremonies, no phases
- Not a fully autonomous agent — you're the product owner, always in the loop
- Not replacing Claude Code — orchestrating it

## The Problem

AI coding tools write code but share the same failure modes:

- They change files you didn't ask them to change
- They make architectural decisions silently
- They forget why you made certain decisions
- Every new session starts from zero

The problem isn't intelligence. It's the lack of **roles, memory, and review**.

## How TAT Works

```
         ┌─────────────────────────────────────────┐
         │          USER (Product Owner)            │
         │       Intent, priorities, final call     │
         └────────────────┬────────────────────────┘
                          │
         ┌────────────────▼────────────────────────┐
         │          OPUS (Orchestrator)             │
         │    Plans, decides, executes, delegates   │
         └──┬──────────────────────────────────┬───┘
            │                                  │
  ┌─────────▼─────────┐           ┌────────────▼──────────┐
  │  SONNET (Coder)   │           │   GPT (Senior Advisor) │
  │  Implements tasks  │           │   Reviews plans/code   │
  │  via subagents     │           │   Flags drift & risks  │
  └────────────────────┘           └───────────────────────┘
```

### The Loop

1. User says what they want
2. Opus writes spec, breaks into tasks grouped by version milestone
3. GPT critiques the plan (second opinion)
4. User approves
5. Opus picks next task, creates branch (`<TASK-ID>/<slug>`)
6. Sonnet codes (delegated via subagent) or Opus codes directly
7. Opus self-reviews the diff
8. GPT reviews the code
9. Push, PR, merge
10. Update plan → next task

### Memory

Everything lives in the repo as flat markdown:

```
your-project/
└── .tat/
    ├── spec.md         # What we're building and why
    ├── plan.md         # Tasks grouped by version milestone
    ├── decisions.md    # ADRs — why we chose X over Y
    ├── gpt.md          # Latest GPT review summary
    ├── session.md      # Live session log (gitignored)
    └── version         # Last-applied TAT version
```

The AI reads these before it acts. Context survives across sessions. No database, no external service — just files in your repo.

## Example

```
> /tat

[TAT] Active v2.2.0. Role: Orchestrator (Opus 4.6)
[TAT] Project: my-saas-app
[TAT] Version: v1.2.0 → v1.3.0
[TAT] Current task: OM-084 — Add contact gate
[TAT] Progress: 3/5 done (v1.3.0)

  ... Opus codes or delegates to Sonnet, self-reviews, GPT reviews ...

[GPT] BLOCKERS: none
[GPT] SUGGESTIONS: add rate limiting to reset endpoint
[TAT] No blockers. Ready to ship.
```

## Commands

| Command | What it does |
|---------|-------------|
| `/tat` | Full activation — load context, pick next task, start working |
| `/tat status` | Project dashboard — version, progress, open PRs |
| `/tat init` | Initialize `.tat/` for a new project |
| `/tat review` | Force GPT review of current branch |

| `/tat replan` | Reprioritize tasks with GPT input |
| `/tat version` | Show installed version |

## Scripts

| Script | What it does |
|--------|-------------|
| `tat-code-review.sh` | Send code diff to GPT for structured review |
| `tat-gpt-watch.sh` | Background watcher — reads session + diff, writes to gpt.md |
| `tat-gpt-gate.sh` | Auto-triggers GPT after 3+ user turns without review |
| `ask-gpt.sh` | Quick inline GPT second opinion |
| `tat-gpt.sh` | Shared GPT API caller (Chat + Responses API) |
| `tat-upgrade.sh` | Auto-sync hooks + version marker on activation |
| `tat-migrate-plan.sh` | Convert flat plans to version-based format |
| `tat-pr-description.sh` | Generate PR description from artifacts |
| `tat-state.sh` | Task ID counter management |
| `tat-publish.sh` | Medium/Dev.to article publishing |

## Quick Start

```bash
# 1. Install
git clone https://github.com/farshi/tinyaiteam.git
cd tinyaiteam
export OPENAI_API_KEY="your-key"
./install.sh

# 2. Verify
./scripts/smoke-test.sh

# 3. Use in any project
cd ~/your-project
# In Claude Code:
> /tat init    # First time — sets up .tat/
> /tat         # Every time — picks next task, starts working
> /tat status  # Dashboard
```

### What gets installed

| Source | Destination | What |
|--------|------------|------|
| `skills/` | `~/.claude/skills/` | Claude Code skills (`/tat`, `/brainstorm`, `/article`, `/ux-check`) |
| `TAT.md` | `~/.tinyaiteam/` | Workflow rules |
| `scripts/` | `~/.tinyaiteam/scripts/` | GPT review + utility scripts |
| `hooks/` | `~/.tinyaiteam/hooks/` | Git hooks (auto-synced per project on `/tat` activation) |

### Prerequisites

- [Claude Code](https://claude.ai/code) installed
- OpenAI API key (for GPT reviews) — TAT works without it, but you lose the second-brain review

## Git Workflow

- One task = one branch = one PR
- Branch naming: `<TASK-ID>/<slug>` (e.g. `tat-101/update-spec`, `om-083/history-fetch`)
- Commits: `type(scope): description (TASK-ID)` — hooks enforce both
- Self-review diff before GPT review
- Plan updates on the feature branch, not main

## Model Configuration

Configure GPT models in `~/.tinyaiteam/config.sh`:

```bash
TAT_CODE_REVIEW_MODEL="gpt-5.2-codex"       # Code review (quality)
TAT_FALLBACK_MODEL="gpt-5.4-mini"           # After daily budget hit
TAT_DAILY_BUDGET="3.00"                      # Daily GPT spend cap
```

## Philosophy

- **Minimal**: Skills + bash scripts + markdown. No framework, no database.
- **Roles over autonomy**: Planner, coder, reviewer, human — each has a job.
- **Memory over sessions**: Spec, plan, and decisions live in the repo.
- **Git is source of truth**: No phase tracking — derive state from branches and tags.
- **Human in the loop**: Not a weakness. The steering wheel.

## Dogfooding

TAT was built using TAT. Every task, review, and PR in this repo went through the same workflow. The `.tat/` directory is live — check `plan.md` for the roadmap.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for conventions. Check `.tat/plan.md` for the current roadmap.

## License

MIT
