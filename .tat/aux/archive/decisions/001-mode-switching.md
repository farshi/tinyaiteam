# ADR-001: TAT Mode Switching

## Context
Users need to switch between TAT structured workflow and normal Claude usage.

## Options Considered
1. Explicit toggle (`/tat on` / `/tat off`) — clear but adds ceremony
2. Skill invocation (`/tat` activates, session end deactivates) — natural, no exit needed

## Decision
Option 2: Skill-based activation. `/tat` enters TAT mode for the session. No explicit exit — start a new session or just stop using `/tat`.

## Rationale
TAT is a way of working you invoke when you want structure, not a persistent mode you need to manage. Skills already work this way in Claude Code. Adding toggle state adds complexity with no real benefit.
