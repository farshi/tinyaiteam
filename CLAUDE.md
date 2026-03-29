# TAT Project — Claude Code Instructions

This project IS TAT (Tiny AI Team) — the orchestration workflow tool itself.

## What This Project Is
A Claude Code skill + commands + minimal config that adds multi-model planning, structured review, and memory to software projects.

## Development Rules
- We use TAT's own workflow to build TAT (dogfooding)
- Read `.tat/plan.md` for current state
- Read `TAT.md` for the workflow rules we're implementing
- One subtask = one branch = one PR
- Opus plans, Opus or Sonnet codes, GPT reviews

## Project Structure
- `TAT.md` — Master copy of workflow rules (installed to ~/.tinyaiteam/)
- `.tat/` — Project planning state (spec, plan, decisions)
- `skills/tat/SKILL.md` — The /tat skill definition (installed to ~/.claude/skills/tat/)
- `commands/` — Slash commands (installed to ~/.claude/commands/)
- `scripts/` — GPT integration scripts
- `install.sh` — Copies files to ~/.tinyaiteam/ and ~/.claude/

## Install
Run `./install.sh` to copy TAT.md, skills, and commands to the right places.
