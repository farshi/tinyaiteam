# ADR-005: Sprint-Based Plan Format

## Context
TAT originally used epic headings with checkbox lists for plan.md. PatchPilot proved that sprint-based tables with task IDs work better for prioritization and tracking.

## Options Considered
1. Keep epic/checkbox format — familiar, simple, but no task IDs or priority ordering
2. Sprint tables with TAT-XXX IDs — proven in PatchPilot, better for cross-epic prioritization

## Decision
Option 2: Sprint-based tables. Epics define WHAT to build, sprints define WHAT ORDER. Tasks get sequential TAT-XXX IDs, auto-generated via `tat-state.sh new-task-id`.

## Rationale
Sprints group tasks by delivery value, not by architectural category. This matches how work actually gets done — you ship value, not epics. Task IDs enable tracking across state.json, review artifacts, and branch names. Format proven across multiple projects.
