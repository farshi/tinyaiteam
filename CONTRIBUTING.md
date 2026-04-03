# Contributing to TAT

TAT is built using TAT. Every change goes through the same SSD loop and checkpoint workflow the tool provides.

## Prerequisites

- [Claude Code](https://claude.ai/code) installed and authenticated
- `bash` and `jq` (standard on macOS/Linux)
- [gh CLI](https://cli.github.com/) for PR workflows
- OpenAI API key for GPT reviews (optional — TAT works without it, but review quality drops)

## Setup

```bash
git clone https://github.com/farshi/tinyaiteam.git
cd tinyaiteam
export OPENAI_API_KEY="your-key"   # optional but recommended
./install.sh
./scripts/smoke-test.sh            # verify everything works
```

`smoke-test.sh` checks that skills, scripts, and hooks are in place and that GPT connectivity is live.

## How TAT Works (for contributors)

```
tinyaiteam/
├── TAT.md              # Master workflow rules — installed to ~/.tinyaiteam/
├── config.sh           # GPT model config — installed to ~/.tinyaiteam/
├── skills/tat/         # /tat skill definition — installed to ~/.claude/skills/tat/
├── commands/           # Slash commands — installed to ~/.claude/commands/
├── scripts/            # GPT review scripts — installed to ~/.tinyaiteam/scripts/
├── hooks/              # Git hooks — installed per-project via /tat init
├── .tat/               # Live project state (spec, plan, decisions)
└── install.sh          # Copies everything above to its active location
```

After editing any source file, re-run `./install.sh` to push it live.

## Development Workflow

TAT uses itself. The workflow:

1. Check `.tat/plan.md` for the current epic and next task
2. Open Claude Code and run `/tat` to enter orchestrator mode
3. Opus picks the task, defines scope and guardrails
4. Sonnet codes it on a branch (one task = one branch)
5. Opus self-reviews the diff, then GPT reviews
6. PR opened, reviewed, merged — plan updated

To start contributing:

```bash
# In Claude Code on this repo:
> /tat status      # see current epic + task list
> /tat             # enter the SSD loop for the next task
```

## Conventions

**Branches:** `<TASK-ID>/<slug>`
```
tat-042/status-dashboard
om-080/web-identity
```
Also OK: `docs/<slug>`, `fix/<slug>`, `chore/<slug>` for non-task branches.

**Commits:** [Conventional Commits](https://www.conventionalcommits.org/) with TAT task ID
```
feat(skill): add /tat status dashboard (TAT-042)
fix(scripts): handle empty diff in tat-code-review.sh (TAT-055)
docs: update README install instructions (TAT-061)
```

**PRs:** One task = one PR. Title matches the commit message. No stacked PRs.

## Testing

```bash
# Smoke test after any change
./scripts/smoke-test.sh

# Test install.sh in isolation
mkdir /tmp/tat-test && cd /tmp/tat-test
git clone /path/to/tinyaiteam . && ./install.sh
```

If you change a skill or script, manually run the relevant workflow in a test project to verify end-to-end behavior.

## Filing Issues

Open an [issue on GitHub](https://github.com/farshi/tinyaiteam/issues). Include:
- What you expected TAT to do
- What it actually did
- The relevant `.tat/` state if applicable

Check `.tat/plan.md` first — it may already be on the roadmap.
