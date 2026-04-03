# ADR-008: No gstack Dependency in v1

## Context
TAT-058 and TAT-059 planned optional gstack integration for browser-based QA and review steps. gstack is a separate headless browser skill. Adding it as a dependency would mean TAT requires gstack to be installed and working for certain review flows.

## Options Considered
1. Include gstack integration in v1 — richer review capabilities, but external dependency
2. Drop gstack from v1; make skill adapters a v2 backlog item — self-contained v1

## Decision
Option 2: gstack integration dropped from v1. TAT-058 and TAT-059 are moved to v2 backlog. TAT's built-in review flow (GPT via `ask-gpt.sh`, Opus planning, Sonnet coding) is sufficient for v1. Skill adapters are a v2 concern.

## Rationale
v1 should be self-contained with no hidden dependencies. A user who installs TAT via `install.sh` should get the full v1 workflow without needing to install gstack separately. Skill adapters add architectural complexity that isn't justified until the core workflow is proven across multiple projects.
