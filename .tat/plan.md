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
- [ ] Design SKILL.md structure
- [ ] Implement model detection (Opus vs Sonnet)
- [ ] Implement project state reader (.tat/ folder)
- [ ] Implement SSD loop guidance
- [ ] Implement model routing suggestions
- [ ] Implement .tat/ init for new projects
- [ ] Implement backlog capture ("noted, added to backlog" for off-scope ideas)

## Epic 2b: GPT Integration (fast-tracked)
- [x] Design context bundle format
- [x] Design review tier logic (synopsis vs full bundle)
- [x] Write tat-review.sh script (curl-based)
- [ ] Rewrite GPT prompt: advisor (BLOCKERS/SUGGESTIONS/NOTES), not gatekeeper (VERDICT)
- [ ] Add plan review mode (--plan flag, sends spec + plan instead of diff)
- [ ] Add source tagging ([TAT], [GPT], [SYSTEM], [CLAUDE.md], [PROJECT])
- [ ] Test on TAT's own code (dogfood round 2)
- [ ] Iterate based on what we learn

## Epic 4: Git Workflow
- [ ] Define branch naming convention
- [ ] Define PR template for TAT tasks
- [ ] Integrate review into PR flow
- [ ] Plan update after merge

## Backlog (captured during work)
- [ ] Install mechanism: copy TAT.md + skills + commands to ~/.claude (noted during Epic 1)
