# ADR-007: Sprint Ceremonies (Start / End)

## Context
TAT had quality gates at the task level (spec, review, GPT) but nothing at the sprint level. Without sprint-level gates, decisions and lessons from previous sprints weren't being fed back as constraints into the next sprint. Drift accumulates when agents start fresh each sprint without loading prior context.

## Options Considered
1. No sprint ceremonies — lightweight, but lessons and decisions don't propagate
2. Sprint-start loads decisions + lessons; sprint-end captures new lessons — explicit feedback loop

## Decision
Option 2: Sprint ceremonies are required. Sprint-start reads `.tat/decisions/` and `tasks/lessons.md` as constraints before planning. Sprint-end captures new lessons into `tasks/lessons.md`. The loop closes at the sprint boundary.

## Rationale
Lessons that aren't loaded are lessons ignored. Decisions that aren't loaded as constraints can be re-litigated or unknowingly violated. Sprint ceremonies are the mechanism that makes the TAT feedback loop real rather than aspirational. The cost is low (a few file reads); the benefit is drift prevention and compounding quality.
