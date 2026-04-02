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

### Sprint 5 — State IDs + Resume + Review Gates

| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-053 | Add task IDs (TAT-001 format) + sprint plan format | E8 | [x] |
| TAT-054 | Add /tat resume (read state.json, continue where left off) | E8 | [x] |
| TAT-055 | Add /tat recap (summarize last session from state + git log) | E8 | [x] |
| TAT-056 | Strict review gates (refuse to advance without review artifacts) | E9 | [x] |
| TAT-057 | Review artifact storage (.tat/reviews/TAT-xxx-review.md) | E9 | [x] |

### Sprint 6 — Integration + Polish

| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-069 | /tat sprint-start — readiness gate (goal, scope, risks, DoD → sprint.md) | E12 | [x] |
| TAT-070 | /tat sprint-end — retro gate (shipped, slipped, lessons, drift check → retro.md) | E12 | [x] |
| TAT-060 | Add retry/fallback for GPT API failures | E10 | [x] |
| TAT-061 | Support parallel Sonnet subagents | E10 | [x] |
| TAT-062 | Add CONTRIBUTING.md with setup + issue templates | E11 | [x] |
| TAT-063 | Clean up repo structure — assessed, already clean | E11 | [x] |
| TAT-064 | Record architecture decisions as ADRs | E11 | [x] |

---

### Sprint 7 — Lessons Library + UX Alignment Skill

| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-072 | Extract universal lessons → lessons/library.md | E13 | [x] |
| TAT-073 | Update install.sh to deploy lessons library | E13 | [x] |
| TAT-074 | Update sprint-start to load global lessons library | E13 | [x] |
| TAT-075 | Add T-series backlog items to plan.md | E13 | [x] |
| TAT-076 | Brainstorm UX alignment approach with GPT | E14 | [x] |
| TAT-077 | Build /ux-check skill based on brainstorm | E14 | [x] |
| TAT-078 | Wire /ux-check into install.sh + test | E14 | [x] |

---

### Sprint 8 — Workflow Fixes + Medium Publish

| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-085 | tat-publish.sh — auto-publish articles to Medium via REST API | E15 | [x] |
| TAT-086 | Fix POST-MERGE — plan updates in feature branch, not main | E10 | [x] |
| TAT-087 | Fix GL-08 + Branch Guard — remove "docs on main" advice | E10 | [x] |
| TAT-088 | Add GL-16 — never push to protected main | E13 | [x] |
| TAT-089 | Fix tat-gpt.sh — add gpt-5.3-codex to RESPONSES_ONLY_MODELS | E10 | [x] |
| TAT-090 | Deduplicate SKILL.md — remove redundant checklists and double GPT review | E10 | [x] |
| TAT-091 | Fix TAT.md model routing table (gpt-5.4-mini → gpt-5.3-codex) | E11 | [x] |
| TAT-092 | Fix init template + status command to use sprint format | E10 | [x] |

---

### Sprint 9 — Version Awareness + Lesson Lifecycle

| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-093 | Add VERSION file + CHANGELOG.md | E16 | [x] |
| TAT-094 | install.sh deploys VERSION | E16 | [x] |
| TAT-095 | /tat activation shows version | E16 | [x] |
| TAT-096 | Tag v0.4.0 release | E16 | [x] |
| TAT-097 | Add [active]/[applied] markers to lessons | E17 | [x] |
| TAT-098 | Sprint-start loads only [active] lessons | E17 | [x] |
| TAT-099 | /tat graduate command | E17 | [x] |

---

## Current Sprint: Sprint 10 — Foundation Repair + New Commands

Goal: Fix spec drift, capture missing ADRs, and build /tat wrapup + /tat replan commands.

| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-101 | Update spec.md to match current reality | E18 | [ ] |
| TAT-102 | Capture missing ADRs (6 decisions) | E18 | [ ] |
| TAT-104 | /tat wrapup command | E19 | [ ] |
| TAT-067 | /tat replan command | E19 | [ ] |

---

## Backlog

| ID | Idea | Noted during |
|----|------|--------------|
| ~~TAT-065~~ | ~~Tagged releases / versioning for install.sh~~ — moved to Sprint 9 (E16) | E8 |
| TAT-066 | /tat sprint command (show current sprint backlog) | PatchPilot lessons |
| TAT-067 | /tat replan — backlog hygiene: deduplicate, cluster related tasks, validate staleness, reprioritize with GPT advisory, annotate Refs. Sprint-start warns if replan not fresh. Ref: GPT 5.2-codex consultation (Sprint 9), ADR-009 | PatchPilot lessons |
| TAT-068 | Optional skill adapter hooks — detect/use external skills as plugins (v2) | E9 dropped |
| ~~TAT-071~~ | ~~Bug: pre-push hook blocks tag pushes~~ — FIXED in v0.2.0 (#29) | PatchPilot bug |
| TAT-079 | Docs follow context, not calendar — auto-detect new concepts, prompt for glossary | devsecops T2 |
| TAT-080 | Split large tasks by value layer — suggest core/enhancement splits during planning | devsecops T4 |
| TAT-081 | Alignment checks at milestones — GPT drift check (spec vs built) after epic completion | devsecops T5 |
| TAT-082 | /tat vision — capture strategic input as ADR + backlog without disrupting sprint | devsecops T6 |
| TAT-083 | Show what was built before asking for approval — deliverable summary in SHIP checkpoint | devsecops T7 |
| TAT-084 | Auto-mode periodic self-check — every 3 tasks, verify checkpoints are being followed | devsecops T8 |
| ~~TAT-085~~ | ~~tat-publish.sh — auto-publish articles to Medium via REST API~~ — moved to Sprint 8 | Sprint 7 article |
| TAT-100 | Project-specific task ID prefixes (max 4 chars, e.g. OMT-, DESA-) instead of always TAT-. Ref: ADR-005 | Sprint 9 |
| TAT-101 | Update spec.md to match current reality. Ref: Sprint 9 drift audit (6 gaps found) | Sprint 9 drift audit |
| TAT-102 | Capture missing ADRs (lessons arch, self-review gate, worktree isolation, script paths, plan-in-branch). Ref: Sprint 9 drift audit | Sprint 9 drift audit |
| ~~TAT-103~~ | ~~Task granularity decision~~ — DONE: captured in ADR-009 | Sprint 9 drift audit |
| TAT-104 | /tat wrapup command — session hygiene gate. Ref: GPT 5.2-codex consultation (session close gap), GL-19 | Sprint 9 |
| TAT-105 | Optimize GPT review payloads — send acceptance criteria + relevant ADR snippets instead of raw context. Skip spec in ask-gpt follow-ups. Ref: GPT 5.2-codex self-review (Sprint 9), GL-05 | Sprint 10 |
| TAT-106 | IDE project mismatch guard — detect when IDE file is in a different repo than shell working directory, warn and stop. Ref: GPT 5.2-codex consultation (Sprint 10) | Sprint 10 |
| TAT-107 | Cross-project limitation: Claude Code sessions are pinned to startup directory, cd doesn't persist. TAT should detect and warn clearly instead of letting user retry cd. Ref: Sprint 10 bug | Sprint 10 |
