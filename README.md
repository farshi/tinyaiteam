# TAT — Tiny AI Team

**Stop using AI like a solo developer. Use it like a team.**

TAT is a lightweight orchestration layer for [Claude Code](https://claude.ai/code) that adds planning, multi-model coordination, and persistent memory to AI-assisted development.

## What TAT Does

- **Session flows** with guardrails: Coding, Planning, Design — each with steps, scripts, gates
- **Task cards** with fix-specs (What/Files/Reuse/Done) + subtasks — the spec IS the design
- **Multi-model coordination**: Opus orchestrates, Sonnet codes, GPT reviews
- **Persistent memory** via `.tat/` files — context survives across sessions
- **Progress visibility** — you always know what step you're on

## How It Works

```
User says what they want
  → Opus writes fix-spec, breaks into tasks
  → GPT critiques (second opinion)
  → User approves
  → Opus picks task, creates branch
  → Sonnet codes (or Opus directly)
  → Self-review → GPT review → Ship
  → Next task
```

### Memory

Everything lives in the repo as flat markdown:

```
your-project/.tat/
  spec.md        # What we're building and why
  plan.md        # Task cards with fix-specs + subtasks
  decisions.md   # ADRs — why we chose X over Y
  aux/           # Project artifacts (brainstorm drafts, proposals)
  session.md     # Session log (gitignored)
  gpt.md         # GPT review cache (gitignored)
```

## Commands

| Command | What it does |
|---------|-------------|
| `/tat` | Coding session — load context, pick task, code, review, ship |
| `/tat brainstorm` | Planning session — generate candidate tasks |
| `/tat replan` | Reprioritize tasks with GPT |
| `/tat design <ID>` | Write fix-spec before coding |
| `/tat ask "<q>"` | Quick GPT second opinion |
| `/tat status` | Project dashboard |
| `/tat review` | Force GPT review of current branch |
| `/tat init` | Initialize `.tat/` for a new project |

## Quick Start

```bash
# 1. Install
git clone https://github.com/farshi/tinyaiteam.git
cd tinyaiteam
export OPENAI_API_KEY="your-key"
./install.sh

# 2. Use in any project
cd ~/your-project
> /tat init    # First time — sets up .tat/
> /tat         # Every time — picks next task, starts working
```

### Prerequisites

- [Claude Code](https://claude.ai/code) installed
- OpenAI API key (for GPT reviews) — TAT works without it, but you lose the second-brain review

## Task Format

Every task is a card with a fix-spec and subtasks:

```markdown
### TAT-123 — Add user auth
- What: Add login/logout with session tokens
- Files: src/auth.ts, src/middleware.ts
- Reuse: existing session store
- Done: Login flow works, sessions persist
- [ ] Create auth routes
- [ ] Add session middleware
- [ ] Wire up logout
```

One task = one branch = one PR. Subtasks are steps, not separate tasks.

## Philosophy

- **Minimal**: Skills + bash scripts + markdown. No framework, no database.
- **Flows over rules**: Steps with scripts and gates, not markdown rule lists.
- **Memory over sessions**: Spec, plan, and decisions live in the repo.
- **Git is source of truth**: Derive state from branches and tags.
- **Human in the loop**: Not a weakness. The steering wheel.

## Dogfooding

TAT was built using TAT. Check `.tat/plan.md` for the roadmap.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
