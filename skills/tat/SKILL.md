---
name: tat
version: 3.0.0
description: |
  Tiny AI Team v3 — orchestration for Claude Code. Loads project context,
  picks next task, coordinates Opus/Sonnet/GPT. Use when asked to "/tat",
  "/tat status", "/tat brainstorm", "/tat replan", or "/tat ask".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
---

# /tat — Tiny AI Team v3

Read `TAT.md` for all rules, flows, and invariants. This file handles activation only.

## Subcommand Detection

- `/tat` → **Coding Session**
- `/tat status` → **Status**
- `/tat init` → **Init**
- `/tat review` → **Review**
- `/tat brainstorm` → **Planning Session**
- `/tat replan` → **Planning Session**
- `/tat design <ID>` → **Design Session**
- `/tat ask "<q>"` → **GPT Consult**
- `/tat version` → **Version**

---

## Status

```bash
git tag --sort=-v:refname | head -1
```

```
[TAT] Status: <project name>
[TAT] Version: <tag> → <next from plan.md>
[TAT] Branch: <current branch>
──────────────────────────────
[TAT] Current task: <first [ ] task>
[TAT] Progress: ██████░░░░ X/Y done (vX.Y.Z)
```

Then stop.

---

## Version

```bash
cat ~/.tinyaiteam/VERSION 2>/dev/null || echo "unknown"
```

Then stop.

---

## Review

```bash
~/.tinyaiteam/scripts/tat-code-review.sh main
```

Show GPT result as summary table (see TAT.md). Add `[OPUS]` opinion. Then stop.

---

## GPT Consult (`/tat ask`)

```bash
~/.tinyaiteam/scripts/ask-gpt.sh "<question>"
```

Show with `[GPT]` tag. Add `[OPUS]` opinion. Don't auto-update files. Then stop.

---

## Init

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
ls "$PROJECT_ROOT/.tat/" 2>/dev/null || echo "NO_TAT_DIR"
```

If `.tat/` exists: `[TAT] Already initialized.` Stop.

If `NO_TAT_DIR`:
1. Create `.tat/spec.md` (What/Why/Constraints template)
2. Create `.tat/decisions.md` (append-only ADR log)
3. Create `.tat/plan.md` with task cards:
   ```markdown
   # Plan

   ## Next: v0.1.0

   ### <PREFIX>-001 — Define project scope and spec
   - What: Fill in spec.md with what, why, and constraints
   - Files: .tat/spec.md
   - Done: spec.md has concrete project definition
   - [ ] Describe what the project does
   - [ ] Describe why it exists
   - [ ] List constraints

   ## Done
   ```
4. Create `.tat/aux/` directory for project artifacts
5. `~/.tinyaiteam/scripts/tat-state.sh init`
6. Install git hooks from `~/.tinyaiteam/hooks/`
6. Print initialized summary. Ask "What are you building?"

---

## Replan

1. Read plan.md and spec.md
2. Send to GPT via `ask-gpt.sh` — ask for priority order
3. Show GPT's prioritization with `[GPT]` tag
4. Opus adds opinion with `[OPUS]` tag
5. User approves → update plan.md

---

## Coding Session (`/tat`)

### Guards

```bash
ls .tat/ 2>/dev/null || echo "NO_TAT_DIR"
git branch --show-current
```

- No `.tat/` → STOP, suggest `/tat init`
- On `main` → STOP, create branch first (exception: all tasks done → allow planning)

### Activation

```bash
cat ~/.tinyaiteam/TAT.md 2>/dev/null || echo "TAT_NOT_INSTALLED"
~/.tinyaiteam/scripts/tat-upgrade.sh
cat .tat/spec.md && cat .tat/plan.md && cat .tat/decisions.md 2>/dev/null && cat .tat/gpt.md 2>/dev/null
```

Then follow **Session: Coding** from TAT.md:

```
Load → Pick → Branch → Code → Self-review → GPT review → Ship
```

Show progress bar after every step. Show GPT review as summary table.

### Model Roles
- `claude-opus-*` → Orchestrator: plan, delegate, review
- `claude-sonnet-*` → Coder: implement, escalate architecture to Opus

### Delegation (Opus → Sonnet)
```
[TAT] Delegating to Sonnet →
[TAT] Task: <description>
[TAT] Branch: <TASK-ID>/<slug>
[TAT] Files: <list>
```
Spawn Agent with `model: "sonnet"`. Self-review the diff when Sonnet returns.

### After merge
```bash
git checkout main && git pull origin main
```
Show next task. If skills/scripts changed, run `install.sh`.

---

## Planning Session (`/tat brainstorm`)

Follow **Session: Planning** from TAT.md:

```
Load → Brainstorm/Replan → GPT consult → Update plan
```

Output: fix-spec task cards added to plan.md backlog.

---

## Design Session (`/tat design <ID>`)

Follow **Session: Design** from TAT.md:

```
Load → Pick task → Write fix-spec → GPT consult → Approve
```

Output: fix-spec (What/File/Reuse/Done means) written in plan.md under the task.

---

## Session Log

Append to `.tat/session.md` after significant events (decisions, GPT calls, user corrections):
```
- [HH:MM][Speaker] what happened — 1 line
```
Tags: `[User]`, `[Opus]`, `[GPT]`, `[Decision]`. `@@` = urgent for GPT.
