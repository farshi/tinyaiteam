# TAT — Tiny AI Team

## What
The persistent execution loop for AI-assisted projects. TAT adds structured state, checkpoint-driven workflow, and multi-model coordination to Claude Code. It's not a toolkit of specialist skills — it's the orchestration layer that ties planning, coding, review, and shipping into a repeatable loop with memory that persists across sessions.

## What TAT Is
- An orchestration loop: Spec → Plan → Branch → Code → Review → Ship → Repeat
- Persistent project state via `.tat/` files (spec, plan, decisions, session state)
- Multi-model coordination: Opus plans, Sonnet codes, GPT reviews
- Checkpoint-driven execution with strict gates between phases
- A system that gets smarter as you use it — every lesson becomes a rule

## What TAT Is Not
- Not a toolkit of independent skills (that's gstack's strength — and TAT can use gstack skills)
- Not a fully autonomous agent — user is product owner, always in the loop
- Not replacing Claude Code — orchestrating it
- Not a complex framework — markdown files, bash scripts, Claude Code skills

## Why
AI coding tools are strong at writing code but weak at long-term planning, remembering decisions, coordinating multiple models, and maintaining engineering discipline. TAT adds process and memory on top of existing tools so AI works like a real engineering team — not a random code generator.

## Constraints
- Built as Claude Code skills and commands — no external framework
- GPT integration via direct API calls (curl or minimal script)
- All state is flat files (markdown + JSON) — no database
- User is always in the loop as product owner
- Proper git workflow: branches, PRs, reviews
