# ADR-008: No gstack Dependency in v1

## Context
TAT planned optional gstack integration (TAT-058: detect installed skills, TAT-059: graceful fallback). This would let TAT use gstack's specialist skills (/review, /qa) as subroutines.

## Options Considered
1. Build gstack integration — detect and use external skills
2. Drop from v1 — TAT's built-in review flow is sufficient
3. Add generic skill adapter hooks for v2

## Decision
Option 2 + 3 as backlog. gstack tasks dropped from Sprint 6. Skill adapter hooks added to backlog as TAT-068.

## Rationale
GPT consultation was decisive: "TAT's value prop is orchestration, not skill discovery. v1 should work out of the box with only Claude Code + flat files + git. Detection logic is maintenance debt. Optional integrations belong in v2+ as plugins, not core." TAT already has built-in review (tat-code-review.sh, self-review) and doesn't need gstack for anything in the core loop.
