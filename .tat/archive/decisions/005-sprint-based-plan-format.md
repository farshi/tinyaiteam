# ADR-005: Sprint-Based Plan Format

## Context
The original plan format used epics with checkboxes. As TAT matured, it became clear that epics describe *what* to build but don't define *order* or *priority*. The PatchPilot project had already adopted sprint tables with TAT-XXX task IDs and the format proved effective there.

## Options Considered
1. Epic/checkbox format — simple, but no ordering or ID traceability
2. Sprint tables with TAT-XXX task IDs — ordered, traceable, matches proven convention

## Decision
Option 2: Plans use sprint tables with TAT-XXX task IDs. Each sprint is a time-boxed table of tasks with status, owner, and ID. Epics remain as high-level groupings but execution is tracked at the sprint level.

## Rationale
Epics define what, sprints define order. Without sprint ordering, work is prioritized ad hoc. TAT-XXX IDs enable traceability across commits, PRs, and ADRs. The format was already proven in PatchPilot — no reason to invent a different convention for TAT itself.
