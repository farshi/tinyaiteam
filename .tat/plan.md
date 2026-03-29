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
- [~] Test on TAT's own code (dogfood round 2)
- [ ] Iterate based on what we learn

## Epic 4: Git Workflow
- [x] Define branch naming convention (in TAT.md: tat/<epic>/<task-name>)
- [x] Define PR template for TAT tasks (in SKILL.md: push + PR after review)
- [ ] Integrate review into PR flow
- [ ] Plan update after merge

## Backlog (captured during work)
- [ ] Install mechanism: copy TAT.md + skills + commands to ~/.claude (noted during Epic 1)
- [ ] GPT PR review before merge: send epic + tasks + full PR diff to GPT, max 2 fix rounds, then user decides (noted during Epic 2)
- [ ] Brainstorming loop: Opus proposes → GPT critiques → Opus adjusts, max 3 rounds, hard stop, user decides (noted during Epic 2)
- [ ] Summarize user input before storing: clean up typos/rough text into clear summary for context (noted during Epic 2)
- [ ] GPT review response summary: Opus writes accept/dismiss reasoning into PR description as audit trail and context for future GPT reviews (noted during Epic 2b)
