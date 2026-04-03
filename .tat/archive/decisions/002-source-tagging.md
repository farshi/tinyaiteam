# ADR-002: Source Tagging in Output

## Context
When Claude gives warnings, guidance, or suggestions, it's unclear whether the guidance comes from built-in system rules, user's CLAUDE.md, project CLAUDE.md, or TAT rules. This makes it hard to understand WHY a particular behavior is happening and which configuration to change if you disagree.

## Options Considered
1. No tagging — user has to guess where guidance comes from
2. Source tags on all output — too noisy
3. Source tags on guidance/warnings only — clear without noise

## Decision
Option 3: Tag guidance and warnings with their source. Normal conversation and code output is untagged.

## Tags
- `[SYSTEM]` — built-in safety rules (destructive actions, security)
- `[CLAUDE.md]` — user's global CLAUDE.md rules
- `[PROJECT]` — project-level CLAUDE.md rules
- `[TAT]` — TAT workflow rules (from TAT.md or .tat/)

## Rationale
User observed that a repo deletion warning appeared without explanation of where the rule came from. Source tags create transparency — you know which layer is speaking and can override or adjust the right config. Only applied to guidance/warnings to avoid noise in normal output.
