# TAT — Tiny AI Team

## What
An orchestration workflow for Claude Code that adds multi-model planning, structured review, and long-term memory to software projects. It coordinates Opus (planning/architecture), Sonnet (coding), and GPT (second opinion/review) through a disciplined SSD loop with proper git workflow.

## Why
AI coding tools are strong at writing code but weak at long-term planning, remembering decisions, coordinating multiple models, and maintaining engineering discipline. TAT adds process and memory on top of existing tools so AI works like a real engineering team — not a random code generator.

## Constraints
- Built as Claude Code skills and commands — no external framework
- GPT integration via direct API calls (curl or minimal script)
- All memory is flat markdown files — no database
- User is always in the loop as product owner
- Proper git workflow: branches, PRs, reviews

## Non-goals
- Not a fully autonomous agent — user drives decisions
- Not replacing Claude Code or Codex — orchestrating them
- Not a complex tool — minimal files, minimal ceremony
