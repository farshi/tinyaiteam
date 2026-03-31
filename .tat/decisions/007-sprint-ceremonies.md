# ADR-007: Sprint Ceremonies (Start/End)

## Context
TAT had task-level quality gates (PLAN→CODE→REVIEW→SHIP) but no sprint-level gates. Lessons learned and architectural decisions were captured but not systematically loaded before new work.

## Options Considered
1. No sprint gates — rely on task-level checkpoints only
2. Sprint-start only — load constraints before planning
3. Both start and end — full feedback loop

## Decision
Option 3: Sprint-start loads decisions + lessons as constraints (hard acknowledge gate). Sprint-end captures what shipped, what slipped, and new lessons. Lessons flow from sprint-end → lessons.md → next sprint-start.

## Rationale
Task-level gates prevent bad code from shipping. Sprint-level gates prevent building the wrong thing. The key addition is the acknowledge gate — Claude must explicitly confirm it has read and will follow relevant constraints before planning starts. Without this, lessons get captured but never loaded. GPT consultation confirmed: "If you want this to actually change behavior, require acknowledgment."
