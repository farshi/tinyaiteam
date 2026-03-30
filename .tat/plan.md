# Plan

## Completed Sprints

### Sprint 1 — Foundation + Core Skill (Epics 1–2)

| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-001 | Create project structure and git repo | E1 | [x] |
| TAT-002 | Write spec.md | E1 | [x] |
| TAT-003 | Write plan.md | E1 | [x] |
| TAT-004 | Write TAT.md (global workflow rules) | E1 | [x] |
| TAT-005 | Write config.sh (GPT API config) | E1 | [x] |
| TAT-006 | Create .gitignore | E1 | [x] |
| TAT-007 | Create CLAUDE.md for the project | E1 | [x] |
| TAT-008 | Create install.sh | E1 | [x] |
| TAT-009 | Design SKILL.md structure | E2 | [x] |
| TAT-010 | Implement model detection (Opus vs Sonnet) | E2 | [x] |
| TAT-011 | Implement project state reader (.tat/ folder) | E2 | [x] |
| TAT-012 | Implement SSD loop guidance | E2 | [x] |
| TAT-013 | Implement model routing suggestions | E2 | [x] |
| TAT-014 | Implement .tat/ init for new projects | E2 | [x] |
| TAT-015 | Implement backlog capture | E2 | [x] |
| TAT-016 | Add /tat status command | E2 | [x] |

### Sprint 2 — GPT Integration + Git Workflow (Epics 2b, 4)

| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-017 | Design context bundle format | E2b | [x] |
| TAT-018 | Design review tier logic (synopsis vs full bundle) | E2b | [x] |
| TAT-019 | Write tat-review.sh script (curl-based) | E2b | [x] |
| TAT-020 | Rewrite GPT prompt: advisor, not gatekeeper | E2b | [x] |
| TAT-021 | Add plan review mode (--plan flag) | E2b | [x] |
| TAT-022 | Add source tagging ([TAT], [GPT], [SYSTEM], etc.) | E2b | [x] |
| TAT-023 | Record decisions: ADR-001, ADR-002 | E2b | [x] |
| TAT-024 | Test on TAT's own code (dogfood round 2) | E2b | [x] |
| TAT-025 | Iterate: fixed model detection, 7 dogfood lessons | E2b | [x] |
| TAT-026 | Define branch naming convention | E4 | [x] |
| TAT-027 | Define PR template for TAT tasks | E4 | [x] |
| TAT-028 | Integrate review into PR flow (pre-PR checklist) | E4 | [x] |
| TAT-029 | Plan update after merge (post-merge checklist) | E4 | [x] |

### Sprint 3 — Skills + Auto-delegation (Epics 5–7)

| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-030 | Create scripts/tat-image.sh (DALL-E wrapper) | E5 | [x] |
| TAT-031 | Create skills/article/SKILL.md | E5 | [x] |
| TAT-032 | Update install.sh to loop all skills/ | E5 | [x] |
| TAT-033 | Update config.sh with DALL-E model config | E5 | [x] |
| TAT-034 | Test article skill end-to-end — SKIPPED | E5 | [x] |
| TAT-035 | GPT review + PR — SKIPPED (local only) | E5 | [x] |
| TAT-036 | Improve SKILL.md boilerplate template | E5 | [x] |
| TAT-037 | Auto-delegate coding tasks to Sonnet subagents | E6 | [x] |
| TAT-038 | Split review scripts (plan + code) | E6 | [x] |
| TAT-039 | Shared GPT API caller (tat-gpt.sh) | E6 | [x] |
| TAT-040 | Configurable models per review type | E6 | [x] |
| TAT-041 | Enforce self-review before GPT review | E6 | [x] |
| TAT-042 | Generate PR description from checkpoint artifacts | E7 | [x] |
| TAT-043 | Add tat-pr-description.sh script | E7 | [x] |

### Sprint 4 — State Machine + Hardening (Epic 8, 10 partial)

| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-044 | Create .tat/state.json schema + tat-state.sh | E8 | [x] |
| TAT-045 | Wire state.json into all checkpoints | E8 | [x] |
| TAT-046 | Graceful degradation when state.json missing | E8 | [x] |
| TAT-047 | Fix zsh trap warnings in tat-gpt.sh | E10 | [x] |
| TAT-048 | Improve /tat init quick-start | E10 | [x] |
| TAT-049 | Add smoke tests (smoke-test.sh) | E10 | [x] |
| TAT-050 | Fix install.sh (version, validation, paths) | E10 | [x] |
| TAT-051 | Update README (what TAT is/isn't, quick start) | E11 | [x] |
| TAT-052 | Fix TAT.md model reference drift | E11 | [x] |

---

## Current Sprint: Sprint 5 — State IDs + Resume + Review Gates

Goal: complete the state machine (task IDs, resume, recap) and add review enforcement.

| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-053 | Add task IDs (TAT-001 format) + sprint plan format | E8 | [x] |
| TAT-054 | Add /tat resume (read state.json, continue where left off) | E8 | [x] |
| TAT-055 | Add /tat recap (summarize last session from state + git log) | E8 | [x] |
| TAT-056 | Strict review gates (refuse to advance without review artifacts) | E9 | [ ] |
| TAT-057 | Review artifact storage (.tat/reviews/TAT-xxx-review.md) | E9 | [ ] |

### Sprint 6 — Integration + Polish

| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-060 | Add retry/fallback for GPT API failures | E10 | [ ] |
| TAT-061 | Support parallel Sonnet subagents | E10 | [ ] |
| TAT-062 | Add CONTRIBUTING.md with setup + issue templates | E11 | [ ] |
| TAT-063 | Clean up repo structure (naming, dead files) | E11 | [ ] |
| TAT-064 | Record architecture decisions as ADRs | E11 | [ ] |

---

## Backlog

| ID | Idea | Noted during |
|----|------|--------------|
| TAT-065 | Tagged releases / versioning for install.sh | E8 |
| TAT-066 | /tat sprint command (show current sprint backlog) | PatchPilot lessons |
| TAT-067 | /tat replan (GPT reprioritizes remaining tasks into sprints) | PatchPilot lessons |
| TAT-068 | Optional skill adapter hooks — detect/use external skills as plugins (v2) | E9 dropped |
