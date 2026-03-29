# Plan

## Epic 1: Foundation
- [x] Create project structure and git repo
- [x] Write spec.md
- [x] Write plan.md (this file)
- [x] Write TAT.md (global workflow rules) at ~/.tinyaiteam/
- [x] Write config.sh (GPT API config) at ~/.tinyaiteam/
- [x] Create .gitignore
- [x] Create CLAUDE.md for the project
- [x] Create install.sh

## Epic 2: /tat Skill
- [x] Design SKILL.md structure
- [x] Implement model detection (Opus vs Sonnet)
- [x] Implement project state reader (.tat/ folder)
- [x] Implement SSD loop guidance
- [x] Implement model routing suggestions
- [x] Implement .tat/ init for new projects
- [x] Implement backlog capture ("noted, added to backlog" for off-scope ideas)
- [x] Add /tat status command (compact project dashboard without entering TAT mode)

## Epic 2b: GPT Integration (fast-tracked)
- [x] Design context bundle format
- [x] Design review tier logic (synopsis vs full bundle)
- [x] Write tat-review.sh script (curl-based)
- [x] Rewrite GPT prompt: advisor (BLOCKERS/SUGGESTIONS/NOTES), not gatekeeper (VERDICT)
- [x] Add plan review mode (--plan flag, sends spec + plan instead of diff)
- [x] Add source tagging ([TAT], [GPT], [SYSTEM], [CLAUDE.md], [PROJECT])
- [x] Record decisions: ADR-001 mode switching, ADR-002 source tagging
- [x] Test on TAT's own code (dogfood round 2)
- [x] Iterate: fixed model detection, documented 7 dogfood lessons

## Epic 4: Git Workflow
- [x] Define branch naming convention (in TAT.md: tat/<epic>/<task-name>)
- [x] Define PR template for TAT tasks (in SKILL.md: push + PR after review)
- [x] Integrate review into PR flow (pre-PR checklist with rebase, scope check, GPT review)
- [x] Plan update after merge (post-merge checklist in SKILL.md)

## Epic 5: /article Skill (local only, no PR)

- [x] 5.1 Create `scripts/tat-image.sh` — DALL-E API wrapper (same pattern as tat-review.sh)
- [x] 5.2 Create `skills/article/SKILL.md` — skill definition with full article workflow
- [x] 5.3 Update `install.sh` to copy new skill and script (now loops all skills/)
- [x] 5.4 Update `config.sh` with DALL-E model config (`TAT_IMAGE_MODEL`)
- [x] 5.5 Test end-to-end — SKIPPED: DALL-E access not enabled on OpenAI project
- [x] 5.6 GPT review + PR — SKIPPED: skill is local only for now
- [x] 5.7 Improve SKILL.md boilerplate template — scaffold folder structure, platform export step, image direction in spec

## Epic 6: Auto-delegation + Model Config
- [x] Auto-delegate coding tasks to Sonnet subagents (Opus orchestrates, user never switches)
- [x] Split review scripts: tat-plan-review.sh (gpt-5.4-pro) + tat-code-review.sh (gpt-5.4-mini)
- [x] Shared GPT API caller (tat-gpt.sh) with Chat + Responses endpoint support
- [x] Configurable models per review type (TAT_PLAN_REVIEW_MODEL, TAT_CODE_REVIEW_MODEL)
- [x] Enforce self-review before GPT review in SKILL.md

## Backlog (captured during work)
- [x] Install mechanism: done — skills + commands → ~/.claude, runtime → ~/.tinyaiteam (noted during Epic 1)
- [ ] GPT PR review before merge: send epic + tasks + full PR diff to GPT, max 2 fix rounds, then user decides (noted during Epic 2)
- [ ] Brainstorming loop: Opus proposes → GPT critiques → Opus adjusts, max 3 rounds, hard stop, user decides (noted during Epic 2)
- [ ] Summarize user input before storing: clean up typos/rough text into clear summary for context (noted during Epic 2)
- [ ] GPT review response summary: Opus writes accept/dismiss reasoning into PR description as audit trail and context for future GPT reviews (noted during Epic 2b)
- [x] Pre-PR checklist: already in SKILL.md with full checklist (noted during Epic 4)
- [ ] Inline GPT second opinion: when user asks for a quick opinion, send context to GPT and show response inline — not PR comments, just a fast second opinion during work (noted during Epic 4)
- [ ] .tat/ schema: define file contract, ownership (which command writes what), stale-data rules (noted from GPT plan review)
- [x] GPT script error handling: fixed in Epic 6 — multi-endpoint support, temp file parsing, model compatibility (noted from GPT plan review)
