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

## Epic 2b: GPT Integration (fast-tracked)
- [x] Design context bundle format
- [x] Design review tier logic (synopsis vs full bundle)
- [x] Write tat-review.sh script (curl-based)
- [ ] Test on TAT's own code (dogfood)
- [ ] Iterate based on what we learn

## Epic 4: Git Workflow
- [ ] Define branch naming convention
- [ ] Define PR template for TAT tasks
- [ ] Integrate review into PR flow
- [ ] Plan update after merge
