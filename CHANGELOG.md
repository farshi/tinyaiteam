# Changelog

All notable changes to TAT are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.5.0] — 2026-04-02

### Added
- `/tat wrapup` command: session hygiene gate (loose ends, summary, state, install check, next task)
- `/tat replan` command: backlog hygiene with GPT advisory (deduplicate, cluster, validate staleness, reprioritize)
- Sprint-start warns if backlog not replanned since last sprint
- Replan log (`.tat/replan-log.md`) tracks when backlog was last triaged

---

## [0.4.0] — 2026-04-02

### Added
- VERSION file at repo root; install.sh reads it instead of hardcoding
- CHANGELOG.md (this file)
- install.sh deploys VERSION to `~/.tinyaiteam/` so skills can read it
- /tat activation announces installed version: `[TAT] Active v<version>. Role: ...`
- Lesson lifecycle: `[active]`/`[applied]` markers for lesson entries
- Sprint-start loads only `[active]` lessons, filtering out `[applied]` ones
- `/tat graduate` command to move a lesson from `[active]` to `[applied]`

---

## [0.3.0] — 2025-12-01

### Added
- Global lessons library (`~/.tinyaiteam/lessons/library.md`) installed by `install.sh`
- Sprint-start checkpoint loads global lessons (GL-XX series) alongside project lessons
- `/ux-check` skill for design alignment review
- Medium auto-publish via `tat-publish.sh` (TAT-085)
- Workflow hardening: self-review gate before GPT review enforced in SKILL.md

### Changed
- Sprint-end now prompts lesson capture as a mandatory step
- install.sh copies `lessons/` directory to `~/.tinyaiteam/lessons/`

---

## [0.2.0] — 2025-09-01

### Added
- TAT state machine: `state.json` + `tat-state.sh` for phase tracking (IDLE → PLAN → CODE → REVIEW → SHIP → POST-MERGE)
- `/tat resume` command to restore a session from `state.json`
- `/tat recap` command to summarize the last session
- `/tat sprint-start` readiness gate: loads spec, ADRs, lessons before sprint begins
- `/tat sprint-end` retro gate: captures lessons and writes `retro.md`
- `tat-save-review.sh` and review artifact gate in SHIP checkpoint
- `tat-plan-review.sh` for GPT plan review at PLAN checkpoint
- Parallel delegation: Opus can spawn multiple Sonnet subagents for independent tasks

### Changed
- Checkpoint maps are now mandatory printed checklists at every phase transition
- Plan format migrated to sprint tables with TAT-XXX task IDs

---

## [0.1.0] — 2025-06-01

### Added
- `TAT.md` — master workflow rules file (SSD loop: Spec → Subtask → Do)
- `/tat` skill (`skills/tat/SKILL.md`) with full activation, model routing, and subcommand detection
- GPT integration: `ask-gpt.sh`, `tat-code-review.sh` for GPT-4 peer review
- `install.sh` to deploy TAT rules, skills, commands, scripts, and hooks
- Git hooks: `commit-msg` (conventional commits), `pre-push` (blocks main pushes)
- `/tat init` flow for new project setup with branch protection
- `/tat status` read-only project dashboard
- Source tagging (`[TAT]`, `[GPT]`, `[SYSTEM]`, `[CLAUDE.md]`, `[PROJECT]`)
- Backlog capture: off-scope ideas appended to `plan.md` without interrupting flow
- `.tat/` project state directory: `spec.md`, `plan.md`, `decisions/`, `reviews/`
