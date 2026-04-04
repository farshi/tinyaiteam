# Plan

## Next: v3.0.0

| ID | Task | Status |
|----|------|--------|
| TAT-115 | Kill lessons/reports/today/gpt-cursor — plan is single source | [x] |
| TAT-116 | Add task descriptions to plan format — table index + task cards | [ ] |
| TAT-117 | Rewrite TAT.md — flows replace rules, kill role theater | [x] |
| TAT-118 | Slim SKILL.md + guardrailed flows — 4 modes, step visibility | [ ] |
| TAT-119 | Move migration scripts out of core scripts/ | [ ] |
| TAT-120 | Update install.sh — remove lessons/reports symlinks | [ ] |
| TAT-121 | Update spec.md + README + CHANGELOG for v3 | [ ] |

### TAT-115 — Kill lessons/reports/today/gpt-cursor
- **What:** Delete lessons/library.md, ~/.tinyaiteam/reports.md, today.md, gpt-cursor. Remove /tat report and lessons loading from SKILL.md
- **File:** lessons/, skills/tat/SKILL.md, TAT.md, install.sh
- **Reuse:** Actionable lessons already captured as tasks in this plan
- **Done means:** No separate lessons/reports files. SKILL.md doesn't load lessons. /tat report removed

### TAT-116 — Fix-spec task card format
- **What:** Tasks use fix-spec format (What/File/Reuse/Done means). Table as index, specs below. Fix-spec IS the design — no separate design step
- **File:** TAT.md (document format), skills/tat/SKILL.md (enforce at task creation)
- **Reuse:** OM-096 pattern from oneminuta
- **Done means:** TAT.md documents fix-spec format. /tat init creates plan with example. Reviews check against fix-spec

### TAT-117 — Rewrite TAT.md — flows replace rules
- **What:** Kill Rules section. Replace with 3 session flows (Coding/Planning/Design) where each step has script + gate. Keep only 4 global invariants. Kill Three-Chair/meeting modes. Add "where things belong" table
- **File:** TAT.md, CLAUDE.md
- **Reuse:** Existing scripts mapped to flow steps. GPT consultation from this session
- **Done means:** No standalone Rules section. Every rule embedded in a flow step. TAT.md under 120 lines. CLAUDE.md under 10 lines

### TAT-118 — Slim SKILL.md + guardrailed flows
- **What:** SKILL.md as thin activation wrapper with 4 modes: /tat (8-step coding loop), /tat brainstorm (ideas → fix-specs), /tat replan (reorder), /tat ask (inline GPT). Each step shows one-line status. Auto-proceed default, STOP with lettered options when needed
- **File:** skills/tat/SKILL.md
- **Reuse:** gstack step/gate patterns. Merge standalone /brainstorm skill into /tat brainstorm
- **Done means:** SKILL.md under 6KB. User always knows what step they're on. /tat status shows dashboard

### TAT-119 — Move migration scripts out of core
- **What:** Move tat-migrate-v2.sh, tat-migrate-plan.sh to scripts/archive/
- **File:** scripts/ → scripts/archive/
- **Reuse:** n/a
- **Done means:** Core scripts/ has only runtime scripts

### TAT-120 — Update install.sh
- **What:** Remove lessons/reports symlinks, clean dead paths
- **File:** install.sh
- **Reuse:** Existing structure
- **Done means:** install.sh doesn't reference lessons.md or reports.md

### TAT-121 — Update spec.md + README + CHANGELOG for v3
- **What:** Docs match what shipped
- **File:** .tat/spec.md, README.md, CHANGELOG.md
- **Reuse:** Existing doc structure
- **Done means:** spec.md reflects v3 files. README updated. CHANGELOG has v3.0.0 entry

## Backlog

| ID | Task | Status |
|----|------|--------|
| TAT-068 | Optional skill adapter hooks — detect/use external skills as plugins | [ ] |
| TAT-079 | Docs follow context — auto-detect new concepts, prompt for glossary | [ ] |
| TAT-080 | Split large tasks by value layer — suggest core/enhancement splits | [ ] |

## Done

| ID | Task | Status |
|----|------|--------|
| TAT-114 | Update README to match v2.2.0 reality | [x] |
| TAT-113 | Auto-upgrade on /tat activation — sync hooks + version marker | [x] |
| TAT-112 | Version-based planning — derive milestones from git tags | [x] |
| TAT-111 | Enforce task-ID branch naming + commit messages | [x] |
| TAT-101 | Update spec.md to match v2 reality | [x] |
| TAT-105 | Optimize GPT review payloads — send task description instead of raw context | [x] |
| TAT-107 | Cross-project cd limitation — detect and warn instead of letting user retry | [x] |
| TAT-110 | TAT v2 simplification — strip ceremony, keep value (-1181 lines) | [x] |
| TAT-109 | GPT review auto-save to .tat/gpt.md | [x] |
| TAT-108 | /tat report command — real-time capture to ~/.tinyaiteam/reports.md | [x] |
| TAT-107 | /tat version subcommand | [x] |
| TAT-106 | IDE project mismatch guard | [x] |
| TAT-104 | /tat wrapup command | [x] |
| TAT-067 | /tat replan command | [x] |
| TAT-099 | /tat graduate command | [x] |
| TAT-098 | Sprint-start loads only [active] lessons | [x] |
| TAT-097 | Add [active]/[applied] markers to lessons | [x] |
| TAT-096 | Tag v0.4.0 release | [x] |
| TAT-095 | /tat activation shows version | [x] |
| TAT-094 | install.sh deploys VERSION | [x] |
| TAT-093 | Add VERSION file + CHANGELOG.md | [x] |
| TAT-092 | Fix init template + status command | [x] |
| TAT-091 | Fix TAT.md model routing table | [x] |
| TAT-090 | Deduplicate SKILL.md | [x] |
| TAT-089 | Fix tat-gpt.sh RESPONSES_ONLY_MODELS | [x] |
| TAT-088 | Add GL-16 — never push to protected main | [x] |
| TAT-087 | Fix GL-08 + Branch Guard | [x] |
| TAT-086 | Fix POST-MERGE — plan updates in feature branch | [x] |
| TAT-085 | tat-publish.sh — Medium auto-publish | [x] |
| TAT-078 | Wire /ux-check into install.sh | [x] |
| TAT-077 | Build /ux-check skill | [x] |
| TAT-076 | Brainstorm UX alignment approach | [x] |
| TAT-075 | Add T-series backlog items | [x] |
| TAT-074 | Sprint-start loads global lessons | [x] |
| TAT-073 | install.sh deploys lessons library | [x] |
| TAT-072 | Extract universal lessons → library.md | [x] |
| TAT-064 | Record architecture decisions as ADRs | [x] |
| TAT-063 | Repo structure cleanup | [x] |
| TAT-062 | Add CONTRIBUTING.md | [x] |
| TAT-061 | Parallel Sonnet subagents | [x] |
| TAT-060 | GPT API retry/fallback | [x] |
| TAT-070 | /tat sprint-end retro gate | [x] |
| TAT-069 | /tat sprint-start readiness gate | [x] |
| TAT-057 | Review artifact storage | [x] |
| TAT-056 | Strict review gates | [x] |
| TAT-055 | /tat recap command | [x] |
| TAT-054 | /tat resume command | [x] |
| TAT-053 | Task IDs + sprint plan format | [x] |
| TAT-052 | Fix TAT.md model reference drift | [x] |
| TAT-051 | Update README | [x] |
| TAT-050 | Fix install.sh | [x] |
| TAT-049 | Smoke tests | [x] |
| TAT-048 | Improve /tat init | [x] |
| TAT-047 | Fix zsh trap warnings | [x] |
| TAT-046 | Graceful degradation | [x] |
| TAT-045 | Wire state.json into checkpoints | [x] |
| TAT-044 | Create state.json + tat-state.sh | [x] |
| TAT-043 | tat-pr-description.sh | [x] |
| TAT-042 | PR description from artifacts | [x] |
| TAT-041 | Enforce self-review before GPT | [x] |
| TAT-040 | Configurable models per review type | [x] |
| TAT-039 | Shared GPT caller (tat-gpt.sh) | [x] |
| TAT-038 | Split review scripts | [x] |
| TAT-037 | Auto-delegate to Sonnet | [x] |
| TAT-036 | SKILL.md boilerplate template | [x] |
| TAT-030–035 | Article skill + image generation | [x] |
| TAT-017–029 | GPT integration + git workflow | [x] |
| TAT-001–016 | Foundation + core skill | [x] |
