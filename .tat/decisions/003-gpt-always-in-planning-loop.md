# ADR-003: GPT Must Review All Planning Changes

## Context
During TAT development, Opus made multiple planning updates (task prioritization rule, status command, backlog features) without running GPT review on any of them. This violated TAT's core principle — multiple brains on every decision. The user caught it.

## Options Considered
1. GPT reviews plans only when user asks — less friction but defeats the purpose
2. GPT reviews every planning change automatically — enforces the multi-brain principle

## Decision
Option 2: Every planning update runs through `tat-review.sh --plan`. No exceptions.

## Rationale
If GPT only reviews when asked, the default behavior is single-brain planning — exactly what TAT exists to prevent. The friction of running one API call is negligible compared to the value of a second opinion. This was a real bug caught in dogfooding.
