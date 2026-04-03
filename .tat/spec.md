# TAT — Tiny AI Team

## What
An orchestration layer for Claude Code. Adds planning, multi-model coordination (Opus plans, Sonnet codes, GPT reviews in background), and persistent project memory to AI-assisted development.

## What TAT Is
- A core loop: Pick task → Branch → Code → Self-review → GPT watches → Ship → Repeat
- Persistent project state via `.tat/` files (spec, plan, GPT notes)
- Multi-model coordination with GPT as background third eye
- A system that captures lessons automatically, not just at retros

## What TAT Is Not
- Not a process framework — no phases, no checkpoints, no ceremonies
- Not a fully autonomous agent — user is product owner
- Not replacing Claude Code — orchestrating it

## Why
AI coding tools write code but lack long-term planning, decision memory, and multi-model coordination. TAT adds memory and review on top of existing tools.

## Constraints
- Built as Claude Code skills — no external framework
- GPT integration via API calls (bash scripts with Python for JSON)
- All state is flat files (markdown + JSON counter)
- User is always in the loop as product owner
- Git discipline: branches, PRs, conventional commits

## Non-goals
- Complex state machines or phase tracking
- Sprint ceremonies or checkpoint maps
- Multiple lesson files with lifecycle management

## Key Decisions
- **Git is source of truth** — no state.json phase tracking, derive state from branches/PRs
- **GPT watches in background** — PostToolUse hook triggers auto-review, not manual ceremony
- **One lessons file globally** — `~/.tinyaiteam/lessons.md`, append-only, no lifecycle
- **Decisions inline** — key decisions live here in spec.md, not separate ADR files
- **Self-review before GPT** — Claude reads its own diff first, GPT is second opinion
- **Plan is a flat task list** — prioritized top-down, no sprints or epics
- **Graceful degradation** — missing files = feature inactive, not an error
- **One task = one branch = one PR** — clean git history
- **File-overlap gate for parallel agents** — if tasks touch same files, run sequentially
