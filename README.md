# TAT — Tiny AI Team

**Stop using AI like a solo developer. Use it like a team.**

TAT is a lightweight orchestration workflow for [Claude Code](https://claude.ai/code) that gives your AI coding sessions structure, roles, memory, and review — without a framework, database, or ceremony.

*The persistent execution loop for AI-assisted projects.*

*For engineers using Claude Code who want repeatable planning, review, and memory across AI coding sessions.*

## What TAT Is

- An **orchestration loop**: Spec → Plan → Branch → Code → Review → Ship → Repeat
- **Persistent project state** via `.tat/` files (spec, plan, decisions)
- **Multi-model coordination**: Opus plans, Sonnet codes, GPT reviews
- **Checkpoint-driven execution** with strict gates between phases
- A system that **gets smarter as you use it** — every lesson becomes a rule

## What TAT Is Not

- Not a toolkit of independent skills (that's [gstack](https://github.com/garrytandev/gstack)'s strength — TAT can use gstack skills)
- Not a fully autonomous agent — you're the product owner, always in the loop
- Not replacing Claude Code — orchestrating it
- Not a complex framework — markdown files, bash scripts, Claude Code skills

## The Problem

Autonomous AI coding tools are impressive, but they share the same failure modes:

- They change files you didn't ask them to change
- They make architectural decisions silently
- They forget why you made certain decisions
- Every new session starts from zero
- The project slowly drifts from what you intended

The problem isn't intelligence. It's the lack of **process, roles, and memory**.

## How TAT Works

TAT assigns roles to different AI models and runs them through a structured loop:

```
         ┌─────────────────────────────────────────┐
         │              USER (Product Owner)        │
         │         Decides, prioritizes, approves   │
         └────────────────┬────────────────────────┘
                          │
         ┌────────────────▼────────────────────────┐
         │          OPUS (Orchestrator)             │
         │    Plans, specs, architects, delegates   │
         └──┬──────────────────────────────────┬───┘
            │                                  │
  ┌─────────▼─────────┐           ┌────────────▼──────────┐
  │  SONNET (Coder)   │           │   GPT (Reviewer)      │
  │  Implements tasks  │           │   Reviews plans/code  │
  │  via subagents     │           │   Flags drift & bugs  │
  └────────────────────┘           └───────────────────────┘
```

### The SSD Loop

Every task follows: **Spec → Subtask → Do**

```
1. User says what they want
2. Opus writes spec + breaks into epics/tasks
3. GPT critiques the plan (second opinion)
4. User approves
5. Opus picks next task, defines scope + guardrails
6. Sonnet codes the task (delegated via subagent)
7. Opus self-reviews the diff
8. GPT reviews the code (auto-tiered by diff size)
9. User sees code + review, decides
10. Merge PR → update plan → next task
```

### Memory

Everything is written into the repo as flat markdown:

```
your-project/
└── .tat/
    ├── spec.md         # What we're building and why
    ├── plan.md         # Epics, tasks, progress
    └── decisions/      # ADRs — why we chose X over Y
```

The AI reads these before it acts. Context survives across sessions. No database, no external service — just files in your repo.

### Checkpoints

TAT enforces a checkpoint map at every transition to prevent skipping steps:

```
PLAN → CODE → REVIEW → SHIP → POST-MERGE
```

Each checkpoint is a printed checklist that must be completed before moving on. Self-review happens before GPT review. Always.

## Example

```
> /tat

[TAT] Active. Role: Orchestrator (claude-opus-4-6)
[TAT] Project: my-saas-app
[TAT] Current epic: Epic 3 — User Authentication
[TAT] Current task: Add password reset flow
[TAT] Progress: 12 of 18 tasks complete

[TAT] This is a standard coding task. Delegating to Sonnet →
[TAT] Task: Add password reset flow
[TAT] Branch: tat/3/password-reset
[TAT] Files to change: src/auth/reset.ts, src/routes/auth.ts
[TAT] Guardrails: don't touch existing login flow

  ... Sonnet codes, Opus self-reviews, GPT reviews ...

[TAT] ▶ REVIEW checkpoint:
  [x] 1. SELF-REVIEW: read full diff
  [x] 2. SELF-REVIEW: check scope — no unexpected files
  [x] 3. SELF-REVIEW: check for bugs
  [x] 4. GPT REVIEW: run tat-code-review.sh
[GPT] BLOCKERS: none
[GPT] SUGGESTIONS: add rate limiting to reset endpoint
[TAT] No blockers. Ready to ship.
```

## Skills

TAT installs as Claude Code skills:

| Skill | What it does |
|-------|-------------|
| `/tat` | Full workflow — plan, code, review, ship |
| `/tat status` | Quick project dashboard |
| `/brainstorm` | GPT + Opus ideation loop (3 rounds, GPT first to avoid bias) |
| `/article` | Article writing workflow with DALL-E cover images |

## Scripts

| Script | What it does |
|--------|-------------|
| `tat-code-review.sh` | Send code diff to GPT for structured review |
| `tat-plan-review.sh` | Send spec + plan to GPT for plan review |
| `ask-gpt.sh` | Quick inline GPT second opinion |
| `tat-gpt.sh` | Shared GPT API caller (Chat + Responses API) |
| `tat-image.sh` | DALL-E image generation wrapper |

## Quick Start (5 minutes)

```bash
# 1. Install
git clone https://github.com/farshi/tinyaiteam.git
cd tinyaiteam
export OPENAI_API_KEY="your-key"
./install.sh

# 2. Verify installation
./scripts/smoke-test.sh

# 3. Use in any project
cd ~/your-project
# Then in Claude Code:
> /tat init    # First time — sets up .tat/ with spec + plan templates
> /tat         # Every time after — enters the SSD loop
> /tat status  # Quick dashboard — see where you are
```

### What gets installed

| Source | Destination | What |
|--------|------------|------|
| `skills/` | `~/.claude/skills/` | Claude Code skills (/tat, /brainstorm, /article) |
| `TAT.md` + `config.sh` | `~/.tinyaiteam/` | Workflow rules + GPT model config |
| `scripts/` | `~/.tinyaiteam/scripts/` | GPT review scripts |
| `hooks/` | `~/.tinyaiteam/hooks/` | Git hooks (optional, per-project) |

### Prerequisites

- [Claude Code](https://claude.ai/code) installed
- OpenAI API key (for GPT reviews) — TAT works without it, but you lose the second-brain review

## Git Workflow

- One task = one branch = one PR
- Branch naming: `tat/<epic>/<task-name>`
- Conventional commits enforced via git hooks
- GPT reviews every PR before merge
- Plan updates committed to main after each merge

## Model Configuration

Configure which GPT models handle reviews in `~/.tinyaiteam/config.sh`:

```bash
# Plan review — deep reasoning model
TAT_PLAN_REVIEW_MODEL="gpt-5.2-codex"

# Code review — fast model
TAT_CODE_REVIEW_MODEL="gpt-5.4-mini"

# Synopsis review — small diffs
TAT_CODE_REVIEW_SYNOPSIS_MODEL="gpt-4o-mini"
```

## Philosophy

- **Minimal**: Skills + bash scripts + markdown. No framework, no database.
- **Roles over autonomy**: Planner, builder, reviewer, human — each has a job.
- **Memory over sessions**: Spec, plan, and decisions live in the repo.
- **Process over intelligence**: Structure prevents drift. Checkpoints prevent skipping.
- **Human in the loop**: Not a weakness. The steering wheel.

## Dogfooding

TAT was built using TAT. Every epic, task, review, and PR in this repo went through the same SSD loop and checkpoint workflow that TAT provides. The `.tat/` directory in this repo is live — check `plan.md` to see the real roadmap.

## Contributing

This is v0.3.0 — complete SDLC loop with sprint ceremonies, review gates, and lessons feedback. If you're experimenting with AI coding workflows, I'd love to hear what's working for you and what isn't.

- Open an [issue](https://github.com/farshi/tinyaiteam/issues) with feedback or ideas
- Check `.tat/plan.md` for the current roadmap

## License

MIT
