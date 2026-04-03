# Changelog

All notable changes to TAT are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [2.1.0] — 2026-04-03

### Added
- **Three-Chair Model**: User (Product Owner) + GPT (Senior Advisor) + Opus (Orchestrator)
- **session.md**: live session log with three voices, mode-tagged entries
- **today.md**: daily scope file — goals, mode, constraints
- **GPT briefing header**: every GPT call gets MODE + TODAY + DECISIONS + SESSION + DIFF
- **ACK mechanism**: GPT must restate context before advising
- **Meeting modes**: Design, Planning, Coding, Review — changes GPT's role
- **`@@` red flag**: user prefix for urgent GPT attention (replaces `!!`)
- **3-turn gate**: auto-triggers GPT review after 3+ user turns without GPT input (`tat-gpt-gate.sh`)
- **Cost guard**: daily budget ($3 default), downgrades from codex to 5.4-mini after budget hit
- **Symlink install**: `git pull` = instant update, no re-install needed
- **GL-20**: log [User] entries in session.md every turn
- **Migration script fix**: handles varied ADR formats across projects

### Changed
- **Model routing**: codex for code review only, gpt-5.4-mini for brainstorm/planning/ask
- **GPT review flow**: commit first, GPT reviews automatically via hook, fix in next commit
- **install.sh**: symlinks instead of copies (except config.sh and hooks)

### Removed
- `!!` red flag marker (conflicts with Claude Code `!` prefix)
- Rate limit on GPT watcher (every commit reviewed)
- Stale `backlog-notes.md`

---

## [2.0.0] — 2026-04-03

### Breaking Changes
- **Removed phase tracking** from `state.json` — git is the source of truth. Only `next_task_id` counter remains.
- **Removed commands:** `/tat resume`, `/tat recap`, `/tat graduate`, `/tat sprint-start`, `/tat sprint-end`, `/tat wrapup`
- **Removed files:** `tat-save-review.sh`, `tat-plan-review.sh`, `hooks/pre-push`
- **Removed lesson lifecycle** (`[active]`/`[applied]` markers, graduation flow)
- **Removed sprint structure** from plan format — replaced with prioritized task list
- **Removed checkpoint maps** (33 steps per task → free-form working flow)

### Added
- **GPT background watcher** (`tat-gpt-watch.sh`): auto-reviews significant diffs, writes to `.tat/gpt.md`
- **`/tat report`**: real-time observation capture to `~/.tinyaiteam/reports.md`
- **`/tat review`**: on-demand deep GPT review
- `tat-code-review.sh` now auto-saves GPT output to `.tat/gpt.md`
- Lessons installed as single file `~/.tinyaiteam/lessons.md` (was `lessons/` directory)

### Changed
- **SKILL.md**: 1109 → ~260 lines (removed ceremony, kept value)
- **TAT.md**: 282 → ~97 lines (core loop, model routing, file structure, rules)
- **tat-state.sh**: 230 → ~110 lines (counter only, deprecated commands print message)
- **lessons/library.md**: removed `**Status:**` markers from all 19 lessons
- **install.sh**: deploys lessons.md as single file, removed pre-push hook reference
- Plan format: no sprints/epics, just `## Tasks` and `## Done` tables
- Decisions live inline in spec.md, not separate ADR files

### Philosophy
TAT v1 was a process framework. TAT v2 is a memory + review + coordination layer.
Fewer steps, more signal. Git is the source of truth. GPT watches in background.

---

## [0.5.1] — 2026-04-02

### Fixed
- IDE project mismatch guard: detect when IDE has a file open from a different repo than the shell working directory and hard-stop instead of silently loading the wrong project's `.tat/` state (TAT-106)

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
