# ADR-004: GPT Must Review PRs Before Merge

## Context
During TAT development, PR #1 was merged without GPT review. This happened even though the team had already discussed and agreed that GPT should review PRs before merge. The rule existed conceptually but wasn't enforced because it was "in the backlog."

## Decision
GPT reviews every PR before merge, starting now. Even before the automation is built, run `tat-review.sh main` manually from the PR branch before merging. If a principle is agreed, enforce it immediately — don't wait for automation.

## Rationale
Waiting for automation to enforce an agreed rule is a form of skipping the rule. The manual step takes 10 seconds. The value of a second opinion before merge is the core promise of TAT.
