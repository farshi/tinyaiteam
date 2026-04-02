---
name: tat
version: 0.3.0
description: |
  Tiny AI Team — structured multi-model workflow. Enters TAT mode: reads project
  state, enforces SSD loop (Spec → Subtask → Do), routes by model role, triggers
  GPT reviews, tags guidance with source. Use when asked to "/tat", "start tat",
  or "/tat status".
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

# /tat — Tiny AI Team

## Subcommand Detection

Parse the user's input:
- `/tat` or `/tat` with no arguments → Full activation (Step 1 onwards)
- `/tat status` → Jump to **Status Command** below, skip activation steps
- `/tat init` → Jump to **Init Flow** below (explicit project setup)
- `/tat resume` → Jump to **Resume Command** below (pick up where you left off)
- `/tat recap` → Jump to **Recap Command** below (summarize last session)
- `/tat sprint-start` → Jump to **Sprint Start Command** below (readiness gate for new sprint)
- `/tat sprint-end` → Jump to **Sprint End Command** below (retro gate after sprint)

---

## Status Command

When the user says `/tat status`, show a compact project dashboard. No activation, no mode change — just info.

Read `.tat/plan.md` and `.tat/spec.md`, then display:

```
[TAT] Status: <project name from spec>
[TAT] Model: <current model> (Role: <Planner|Coder>)
[TAT] Branch: <current git branch>
──────────────────────────────
[TAT] Sprint: <current sprint name>
[TAT] Current task: <first [~] or [ ] task>
[TAT] Next up: <the task after current>
──────────────────────────────
[TAT] Sprint progress:
  Sprint N: ██████░░░░ 5/8 done  ← current
──────────────────────────────
[TAT] Completed sprints: <N>
[TAT] Backlog: <N items>
[TAT] Open PRs: <list or "none">
```

Then stop. Do not enter TAT mode or start the SSD loop.

---

## Resume Command

When the user says `/tat resume`, restore the session from `.tat/state.json`. No fresh activation — jump straight back to where you were.

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cat "$PROJECT_ROOT/.tat/state.json" 2>/dev/null || echo "NO_STATE"
```

If `NO_STATE` or state.json doesn't exist:
```
[TAT] No state.json found. Use /tat to start a new session.
```
Then stop.

If `phase` is `IDLE`:
```
[TAT] No active task. Use /tat to pick the next task.
```
Then stop.

If `phase` is anything else, show the resume dashboard:
```
[TAT] ▶ Resuming session
[TAT] Task: <task_id> — <task>
[TAT] Epic: <epic>
[TAT] Phase: <phase>
[TAT] Branch: <branch>
[TAT] Last action: <last_action.timestamp>
[TAT] Model: <session.model>
──────────────────────────────
[TAT] Pick up from <phase> checkpoint?
```

Then:
1. Load TAT rules (Step 1) and detect model (Step 2) — same as full activation
2. Verify you're on the correct branch: `git branch --show-current` must match `state.json branch`
   - If on wrong branch: `[TAT] ⚠ Expected branch <branch> but on <current>. Switch first: git checkout <branch>`
3. Enter TAT mode and jump directly to the checkpoint map for the stored phase
4. Print the checkpoint map for that phase and continue from where you left off

This lets a new session pick up mid-task without re-reading the full plan or re-running earlier checkpoints.

---

## Recap Command

When the user says `/tat recap`, show a summary of the last session's work. Read-only — no mode change.

1. Read `.tat/state.json`:
   ```bash
   PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
   cat "$PROJECT_ROOT/.tat/state.json" 2>/dev/null || echo "NO_STATE"
   ```

   If `NO_STATE`: `[TAT] No state.json found. Nothing to recap.` Then stop.

2. Get recent commits using the session timestamp as anchor:
   ```bash
   # Use last_action.timestamp from state.json, or fall back to last 24h
   git log --oneline --since="<last_action.timestamp or 24 hours ago>" main
   ```

3. Get recently merged PRs:
   ```bash
   gh pr list --state merged --limit 10 --json number,title,mergedAt --jq '.[] | select(.mergedAt > "<timestamp>") | "#\(.number) \(.title)"'
   ```

4. Read `plan.md` to find the next open task.

5. Display the recap:
   ```
   [TAT] ▶ Session Recap
   [TAT] Last task: <task_id> — <task>
   [TAT] Phase: <phase>
   [TAT] Model: <session.model>
   [TAT] Session time: <last_action.timestamp>
   ──────────────────────────────
   [TAT] Recent commits on main:
     <hash> <message>
     <hash> <message>
   ──────────────────────────────
   [TAT] PRs merged: <list or "none">
   ──────────────────────────────
   [TAT] Next task: <next [ ] task from plan.md>
   ```

Then stop. Do not enter TAT mode or start the SSD loop.

---

## Sprint Start Command

When the user says `/tat sprint-start`, run the sprint readiness gate. This ensures decisions, lessons, and spec alignment are loaded before any coding begins.

**This is also auto-prompted** at POST-MERGE when all tasks in the current sprint are complete.

### Sprint Start Checkpoint

```
[TAT] ▶ SPRINT START checkpoint:
  [ ] 1. Read spec.md — confirm sprint aligns with project goals
  [ ] 2. Read .tat/decisions/ — load all ADRs
  [ ] 3. Read .tat/lessons.md — load project lessons (if exists)
  [ ] 3b. Read global lessons library — load ~/.tinyaiteam/lessons/library.md
  [ ] 4. Identify relevant constraints for this sprint's tasks
  [ ] 5. Write sprint.md with relevant constraints section
  [ ] 6. ACKNOWLEDGE GATE: list constraints, confirm before proceeding
  [ ] 7. Define sprint goal, scope, risks, definition of done
  [ ] 8. User approves sprint plan
```

**Step-by-step:**

1. **Read spec.md** — Remind yourself what the project IS. Check: does this sprint serve the spec's goals?

2. **Read decisions/** — Load every ADR. These are durable constraints.
   ```bash
   for f in .tat/decisions/*.md; do cat "$f"; done
   ```

3. **Read project lessons** — Load lessons learned from prior sprints. These are process rules earned from experience.
   ```bash
   cat .tat/lessons.md 2>/dev/null || echo "NO_LESSONS"
   ```
   If `NO_LESSONS`: skip — lessons will be created by the first sprint-end.

3b. **Read global lessons library** — Load universal lessons earned across all TAT-managed projects.
   ```bash
   cat ~/.tinyaiteam/lessons/library.md 2>/dev/null || echo "NO_GLOBAL_LESSONS"
   ```
   If `NO_GLOBAL_LESSONS`: skip — run `install.sh` from the tinyaiteam repo to install the library.
   Global lessons (GL-01 through GL-XX) complement project-local lessons. Both are loaded as constraints.

4. **Identify relevant constraints** — For each sprint task, check which ADRs and lessons apply. Don't list everything — only what's relevant to THIS sprint's work.

5. **Write sprint.md** — Create/overwrite `.tat/sprint.md`:
   ```markdown
   # Sprint N — <name>

   **Goal:** <one sentence>
   **Date:** <today>

   ## Relevant Constraints
   - ADR-001: <title> — <why it matters this sprint>
   - Lesson 3: <title> — <why it matters this sprint>

   ## Scope
   | ID | Task | Epic |
   |----|------|------|
   | TAT-069 | ... | E12 |

   ## Out of Scope
   - <what we're NOT doing>

   ## Risks
   1. <risk and mitigation>

   ## Definition of Done
   - All tasks shipped with review artifacts
   - install.sh works after all changes
   - <sprint-specific criteria>
   ```

6. **ACKNOWLEDGE GATE** — Print relevant constraints and confirm:
   ```
   [TAT] ▶ Constraints for Sprint N:
     - ADR-001: <constraint>
     - Lesson 3: <constraint>
   [TAT] Acknowledged. These constraints will be followed throughout this sprint.
   ```
   **This is mandatory.** Do not skip the acknowledgment.

7. **Define sprint goal, scope, risks, DoD** — Fill in the sprint.md template.

8. **User approves** — Show the sprint.md summary, get user confirmation.

After approval, enter TAT mode and begin the first task.

---

## Sprint End Command

When the user says `/tat sprint-end`, run the sprint retro gate. This captures what happened, what was learned, and feeds lessons back into the next sprint-start.

**This is also auto-prompted** at POST-MERGE when all tasks in the current sprint are complete (step 7).

### Sprint End Checkpoint

```
[TAT] ▶ SPRINT END checkpoint:
  [ ] 1. Outcome: list what shipped this sprint (PRs, tasks marked [x])
  [ ] 2. Slipped: what didn't ship, and why?
  [ ] 3. Quality: any bugs, review misses, or regressions?
  [ ] 4. Spec drift: did implementation diverge from spec? Update spec if needed.
  [ ] 5. Lessons: capture 1-3 lessons → append to .tat/lessons.md
  [ ] 6. Process: any workflow changes needed? Note for next sprint.
  [ ] 7. Write retro summary → append to .tat/retro.md
  [ ] 8. User confirms retro complete
```

**Step-by-step:**

1. **Outcome** — Read plan.md, list all tasks that moved to `[x]` this sprint. Cross-reference with merged PRs:
   ```bash
   gh pr list --state merged --limit 20 --json number,title,mergedAt
   ```

2. **Slipped** — Any tasks still `[ ]` in the current sprint? Why didn't they ship? Should they carry over or be dropped?

3. **Quality** — Review the sprint's review artifacts (`.tat/reviews/`). Did GPT flag anything that was ignored? Any post-merge issues?

4. **Spec drift** — Re-read spec.md. Does what we built still match what we said we'd build? If not:
   - Minor drift: note it
   - Major drift: update spec.md to match reality, or flag for course correction

5. **Lessons** — The most important step. Capture 1-3 lessons in `.tat/lessons.md`:
   ```markdown
   ### L<N>. <Title>
   **When:** Sprint <N> retro
   **Source:** <user | GPT | self-review | bug>
   **Lesson:** <what we learned>
   **Rule:** <concrete rule for future sprints>
   ```
   Good lessons become constraints that sprint-start loads. Bad sprints produce the best lessons.

6. **Process** — Did any TAT workflow steps slow things down? Were checkpoints too strict or too loose? Note changes but don't implement them during retro — that's a task for the next sprint.

7. **Write retro** — Append to `.tat/retro.md`:
   ```markdown
   ## Sprint N — <name>
   **Date:** <today>
   **Goal:** <was it met? yes/no>

   ### Shipped
   - TAT-069: /tat sprint-start (#28)
   - TAT-071: pre-push tag fix (#29)

   ### Slipped
   - <none, or list with reasons>

   ### Lessons
   - L1: <title>
   - L2: <title>

   ### Process Notes
   - <any workflow observations>
   ```

8. **User confirms** — Show the retro summary. User approves. Sprint is officially closed.

After sprint-end, prompt `/tat sprint-start` for the next sprint.

---

## Init Flow

When the user types `/tat init` explicitly:

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
ls "$PROJECT_ROOT/.tat/" 2>/dev/null || echo "NO_TAT_DIR"
```

If `.tat/` already exists:
```
[TAT] Project already initialized. Use /tat to continue.
```
Then stop.

If `NO_TAT_DIR`: proceed with the init sequence in **Step 3** below (the `NO_TAT_DIR` branch). Skip to that block directly — do not run Steps 1–2 first.

---

## Full Activation

You are entering TAT mode. Follow these instructions for the rest of the session.

## Step 0: Branch Guard (MANDATORY)

Before doing ANYTHING else, check the current branch:

```bash
git branch --show-current
```

If on `main`: **STOP. Do not proceed.** Print:
```
[TAT] ✗ You are on main. TAT refuses to work on main.
[TAT] Create a branch first: git checkout -b tat/<epic>/<task-name>
```

The ONLY allowed actions on main are:
- Running `/tat status` (read-only)
- Running `/tat init` (project setup)

**This is a hard stop, not a suggestion.** Do not rationalize skipping this for "quick fixes" or "small changes."

## Step 1: Load TAT rules

```bash
cat ~/.tinyaiteam/TAT.md 2>/dev/null || echo "TAT_NOT_INSTALLED"
```

If `TAT_NOT_INSTALLED`: tell the user "TAT is not installed. Run `install.sh` from the tinyaiteam repo first." and stop.

## Step 2: Detect current model

You know which model you are from your system prompt (it states your model ID). Use that directly:
- If you are `claude-opus-*` → You are **Orchestrator**. Plan, spec, architect, decide, AND delegate coding to Sonnet subagents. You stay in control the entire session — the user never needs to switch models.
- If you are `claude-sonnet-*` → You are **Coder/Implementer**. Focus on coding the current subtask. Escalate architectural questions to Opus.
- If you are `claude-haiku-*` → You are **Quick Tasker**. Only handle simple, well-scoped tasks. Escalate anything complex.

Announce your role:
```
[TAT] Active. Role: <Orchestrator|Coder> (<model name>)
```

## Step 3: Read project state

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
echo "PROJECT: $PROJECT_ROOT"
ls "$PROJECT_ROOT/.tat/" 2>/dev/null || echo "NO_TAT_DIR"
```

If `NO_TAT_DIR`:
- If Sonnet: "No .tat/ found. Start an Opus session first to create the project plan."
- If Opus: announce and proceed:
  ```
  [TAT] ▶ Project Setup
  ```
  1. Check if git is initialized:
     ```bash
     git rev-parse --is-inside-work-tree 2>/dev/null || echo "NO_GIT"
     ```
     - If `NO_GIT`: run `git init` and make an initial commit
     - If git exists: skip git init, do NOT re-initialize
  2. Create `.tat/spec.md` with this template:
     ```
     # <Project Name>

     ## What
     <describe your project>

     ## Why
     <why are you building this>

     ## Constraints
     <any constraints>

     ## Non-goals
     <what this is NOT>
     ```
  3. Create `.tat/plan.md` with this template:
     ```
     # Plan

     ## Current Sprint: Sprint 1 — Foundation

     Goal: Set up project structure and define scope.

     | ID | Task | Epic | Status |
     |----|------|------|--------|
     | TAT-001 | Define project scope and spec | E1 | [ ] |
     | TAT-002 | Set up project structure | E1 | [ ] |

     ## Backlog

     | ID | Idea | Noted during |
     |----|------|--------------|
     ```
  4. Install git hooks (automatic — best practices by default):
     ```bash
     if [ -d ~/.tinyaiteam/hooks ]; then
       cp ~/.tinyaiteam/hooks/* .git/hooks/ && chmod +x .git/hooks/*
     fi
     ```
     Print:
     ```
     [TAT] ✓ Git hooks installed:
       - pre-commit: blocks non-plan commits on main
       - commit-msg: enforces conventional commit format
       - pre-push: blocks direct pushes to main
     ```
     If hooks directory doesn't exist, warn: `[TAT] ⚠ No hooks found at ~/.tinyaiteam/hooks/. Run install.sh from the tinyaiteam repo first.`
  5. Enable GitHub branch protection if `gh` is available:
     ```bash
     gh api repos/:owner/:repo/branches/main/protection -X PUT --silent --input - <<'PROTECTION'
     {"required_pull_request_reviews":{"required_approving_review_count":0},"enforce_admins":true,"required_status_checks":null,"restrictions":null}
     PROTECTION
     ```
     Print: `[TAT] ✓ GitHub branch protection enabled on main`
     If `gh` not available or fails, warn: `[TAT] ⚠ Could not set branch protection. Do it manually in GitHub settings.`
  6. Print:
     ```
     [TAT] Project initialized with best practices:
       ✓ .tat/ project state (spec + plan)
       ✓ Git hooks (commit format, branch enforcement)
       ✓ Branch protection (PRs required)
     [TAT] Let's start with the spec — what are you building?
     ```

If `.tat/` exists, read the state:

```bash
cat "$PROJECT_ROOT/.tat/spec.md" 2>/dev/null
cat "$PROJECT_ROOT/.tat/plan.md" 2>/dev/null
cat "$PROJECT_ROOT/.tat/state.json" 2>/dev/null
```

If `state.json` exists and `phase` is not `IDLE`, hint about resume:
```
[TAT] Active session detected (phase: <phase>, task: <task_id>). Use /tat resume to continue, or proceed to pick a new task.
```

## Step 4: Show current position

Parse `plan.md` and display:

```
[TAT] Project: <name from spec>
[TAT] Current epic: <epic heading containing active task>
[TAT] Current task: <first [~] task, or first [ ] if none in-progress>
[TAT] Progress: <X of Y tasks complete>
```

## Step 5: Route and suggest

Based on the current task and your model role:

**If Opus (Orchestrator):**
- If no spec exists → "Let's start with the spec. What are you building?"
- If spec exists but no plan → "Spec is ready. Let me break this into epics and tasks."
- If plan exists, assess current task complexity:
  - Complex (multi-file, architectural, new system) → "This is complex — I'll handle this directly on Opus."
  - Standard coding task → Delegate to a Sonnet subagent (see **Delegation** below)
- If all tasks done → "All tasks complete. Want to review, add new work, or wrap up?"

**If Sonnet (Coder):**
- Show the current task context bundle (scope, guardrails, files to change)
- "Ready to code. Confirm the task or adjust scope."
- If the task looks architectural → "[TAT] This task needs architecture decisions. Start an Opus session for this one."

### Delegation (Opus → Sonnet subagent)

When Opus identifies a coding task, delegate it using the Agent tool with `model: "sonnet"`. The user never switches models — Opus orchestrates everything.

1. **Prepare the context bundle** — gather everything Sonnet needs:
   ```
   [TAT] Delegating to Sonnet →
   [TAT] Task: <task description>
   [TAT] Branch: tat/<epic>/<task-name>
   [TAT] Files to change: <list>
   [TAT] Guardrails: <what NOT to touch>
   ```

2. **Spawn the subagent** with a detailed prompt containing:
   - The task description and acceptance criteria
   - Branch name (create it first if needed)
   - Files to read and modify
   - Guardrails (files/patterns to avoid)
   - Instruction to commit when done with a conventional commit message

3. **Review the result** — when Sonnet returns, Opus:
   - Self-review first: read the diff, check scope, check for bugs, fix anything found
   - Then run GPT review (`tat-code-review.sh`) as second opinion
   - Present both self-review and GPT feedback to the user
   - Proceeds with PR flow if approved

This keeps Opus as the orchestrator and Sonnet as the executor. The user stays in one session.

### Parallel Delegation (multiple independent tasks)

When Opus identifies **2+ tasks that are independent** (no shared files, no dependency between them), it can spawn parallel Sonnet subagents using multiple Agent tool calls in a single message.

**When to parallelize:**
- Tasks touch different files/directories with no overlap
- Neither task depends on the other's output
- Both are standard coding tasks (not architectural)

**When NOT to parallelize:**
- Tasks modify the same files
- One task's output is the other's input
- Either task needs architectural decisions

**Parallel delegation flow:**
1. **Identify independent tasks** — check file overlap and dependencies
2. **Create separate branches** for each task (e.g., `tat/11/task-a`, `tat/11/task-b`)
3. **Spawn subagents in parallel** — use `isolation: "worktree"` so each gets its own copy:
   ```
   [TAT] Parallel delegation →
   [TAT] Agent 1: TAT-062 — CONTRIBUTING.md (branch: tat/11/contributing)
   [TAT] Agent 2: TAT-063 — Repo cleanup (branch: tat/11/cleanup)
   [TAT] Both agents running in parallel...
   ```
4. **Review each result independently** — self-review + GPT review per task
5. **Ship as separate PRs** — one branch = one PR rule still applies

**Key constraint:** Each parallel subagent works in a git worktree (`isolation: "worktree"`), so they can't conflict. Opus reviews and ships each result sequentially after all agents return.

## Step 6: Enter the SSD loop

From here, follow the SSD loop from TAT.md. At each transition, print and follow the checkpoint map below. Do NOT skip steps or combine them.

---

### Checkpoint Map

At every task transition, print this map and check off each step as you complete it. This is mandatory — not optional guidance.

**PLAN checkpoint:**
```
[TAT] ▶ PLAN checkpoint:
  [ ] 0. Update state: tat-state.sh transition PLAN (+ set epic, task, branch)
  [ ] 1. Show task + epic from plan.md
  [ ] 2. Offer GPT plan review (tat-plan-review.sh)
  [ ] 3. User approves plan
```

**CODE checkpoint:**
```
[TAT] ▶ CODE checkpoint:
  [ ] 0. Update state: tat-state.sh transition CODE
  [ ] 1. Create branch: tat/<epic>/<task-name>
  [ ] 2. Show scope: files to change + guardrails
  [ ] 3. User confirms scope
  [ ] 4. Code the task
```

**REVIEW checkpoint (after coding, before PR):**
```
[TAT] ▶ REVIEW checkpoint:
  [ ] 0. Update state: tat-state.sh transition REVIEW
  [ ] 1. SELF-REVIEW: read full diff (git diff main...HEAD)
  [ ] 2. SELF-REVIEW: check scope — any files that shouldn't be here?
  [ ] 3. SELF-REVIEW: check for bugs, edge cases, incomplete work
  [ ] 4. SELF-REVIEW: fix anything found, commit fixes
  [ ] 5. Show self-review summary to user
  [ ] 6. GPT REVIEW: run tat-code-review.sh
  [ ] 7. Show GPT feedback to user
  [ ] 8. Address GPT blockers if any
  [ ] 9. Save review artifact: tat-save-review.sh <task-id> "<self-review summary>"
```

**SHIP checkpoint (after review, before merge):**
```
[TAT] ▶ SHIP checkpoint:
  [ ] 0. Update state: tat-state.sh transition SHIP
  [ ] 1. REVIEW GATE: verify .tat/reviews/<task-id>-review.md exists (refuse if missing)
  [ ] 2. Rebase on latest main
  [ ] 3. Verify diff scope (git diff origin/main --name-only)
  [ ] 4. No untracked files (git ls-files --others --exclude-standard)
  [ ] 5. Update plan.md — mark task(s) [x] (include in this branch, not on main)
  [ ] 6. Push branch
  [ ] 7. Create PR with GPT review response
  [ ] 8. User approves merge
```

**POST-MERGE checkpoint:**
```
[TAT] ▶ POST-MERGE checkpoint:
  [ ] 0. Update state: tat-state.sh transition POST-MERGE
  [ ] 1. git checkout main && git pull origin main
  [ ] 2. Verify plan.md shows task [x] (was updated in SHIP step 5)
  [ ] 3. Run install.sh if skills/config changed
  [ ] 4. Show next task + model routing
  [ ] 5. Update state: tat-state.sh transition IDLE (reset for next task)
  [ ] 6. If current sprint is complete → prompt: "[TAT] Sprint complete! Run /tat sprint-end for retro, then /tat sprint-start for next sprint."
```

---

**Rule: print the checkpoint map at each transition.** Seeing the checklist prevents skipping steps. Check off each item as you complete it. If you catch yourself about to skip ahead, stop and go back to the map.

**State update protocol (step 0 in each checkpoint):**
Step 0 is **graceful** — if `.tat/state.json` doesn't exist, the script prints a skip message and continues. Projects without state.json are unaffected.
```bash
# Transition phase (no-op if state.json missing)
./scripts/tat-state.sh transition <PHASE>

# Set context fields (at PLAN checkpoint — these persist through the task lifecycle)
./scripts/tat-state.sh set epic "<epic name>"
./scripts/tat-state.sh set task "<task description>"
./scripts/tat-state.sh set branch "$(git branch --show-current)"
./scripts/tat-state.sh set session.model "<model name>"
```
Context fields are set once at PLAN and carry through CODE → REVIEW → SHIP. Reset to IDLE at POST-MERGE.

**Review artifact protocol (step 9 in REVIEW checkpoint):**
```bash
# Save review artifact after self-review + GPT review are complete
./scripts/tat-save-review.sh <task-id> "<self-review summary>"
```
This creates `.tat/reviews/<task-id>-review.md`. The SHIP checkpoint gate checks for this file.

**Review gate (step 1 in SHIP checkpoint):**
```bash
# Check review artifact exists — refuse to ship without it
ls .tat/reviews/<task-id>-review.md 2>/dev/null || echo "GATE_FAILED"
```
If `GATE_FAILED`:
```
[TAT] ✗ REVIEW gate failed — no review artifact for <task-id>
[TAT] Complete the REVIEW checkpoint first (self-review + GPT review + save artifact).
```
**This is a hard stop.** Do not proceed to push/PR without the review artifact.

---

## Inline GPT Second Opinion

When the user asks for a quick GPT opinion during work (e.g., "ask GPT about this", "what does GPT think", "can you check with GPT"):

1. Run `ask-gpt.sh` with the question:
   ```bash
   $PROJECT_ROOT/scripts/ask-gpt.sh "<question>"
   ```
   Or call `tat_gpt_call` directly if you need custom context.

2. Present GPT's response with `[GPT]` tag.

3. **Opus gives its own opinion after GPT.** Agree, disagree, or add what GPT missed. Tag with `[OPUS]`.

4. **Do NOT auto-update plans, spec, or any files.** Wait for the user to decide what to do with the opinions.

5. **If the user makes a decision**, offer to record it as an ADR in `.tat/decisions/`:
   ```
   [TAT] Record this decision as an ADR? (e.g., ADR-005: chose X because Y)
   ```

---

## Source Tagging

While in TAT mode, tag all guidance and warnings with their source:

- `[SYSTEM]` — Built-in Claude safety rules (destructive actions, security)
- `[CLAUDE.md]` — User's global ~/.claude/CLAUDE.md rules
- `[PROJECT]` — Project-level CLAUDE.md rules
- `[TAT]` — TAT workflow rules (from TAT.md or .tat/ state)
- `[GPT]` — Feedback from GPT review

**When to tag**: Warnings, workflow guidance, rule enforcement, review results, model routing suggestions.
**When NOT to tag**: Normal conversation, code output, answering questions, tool calls.

---

## Backlog Capture

When the user mentions an idea or feature that is NOT related to the current task:

1. Do NOT act on it
2. Acknowledge it: `[TAT] Noted — added to backlog.`
3. Append a row to `plan.md` under the `## Backlog` table:
   ```
   | TAT-XXX | <idea> | <current sprint> |
   ```
   Use the next available TAT-XXX ID (check the last ID in plan.md and increment).
4. Continue with the current task

Never silently dismiss an idea. Always confirm capture.

---

## Git Workflow

- One subtask = one branch = one PR
- Branch naming: `tat/<epic-number>/<task-name>`
- Always work on a branch, never directly on main
- Plan updates (marking tasks [x]) go in the feature branch before merge — never on main
- After merge, sync local main and run `install.sh` if skills/config changed

### PR Template

```
Title: <short description>

## Summary
- <what changed and why, 1-3 bullets>

## Task
<epic and task from plan.md>

## GPT Review Response
- "<GPT suggestion>" → <accept/dismiss with reasoning>

## Test plan
- [x] <what was tested>
```

Note: Pre-PR checks (rebase, diff scope, untracked files) are handled by the SHIP checkpoint.
Post-merge steps (sync main, install.sh, next task) are handled by the POST-MERGE checkpoint.

---

## Project State Schema

TAT maintains machine-readable state in `.tat/state.json`. Managed by `scripts/tat-state.sh`.

```json
{
  "version": 1,
  "project": "<name from spec.md>",
  "phase": "IDLE",
  "epic": null,
  "task": null,
  "task_id": null,
  "branch": null,
  "last_action": {
    "type": null,
    "model": null,
    "timestamp": null
  },
  "session": {
    "model": null,
    "started_at": null,
    "updated_at": null
  },
  "next_task_id": 1
}
```

**Valid phases:** `IDLE` | `PLAN` | `CODE` | `REVIEW` | `SHIP` | `POST-MERGE`

Use `scripts/tat-state.sh <subcommand>` to read and update state:
- `init` — create state.json with IDLE defaults
- `get <field>` — read a field (dot notation)
- `set <field> <value>` — write a field
- `transition <phase>` — set phase and update timestamps
- `show` — pretty-print current state
- `new-task-id` — generate next TAT-XXX ID and increment counter

---

## Plan Format (Sprint Tables)

Plans use sprint-based tables with task IDs. Epics define WHAT to build, sprints define WHAT ORDER.

```markdown
## Current Sprint: Sprint N — <goal>

Goal: <one-line sprint goal>

| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-053 | Add task IDs + sprint format | E8 | [~] |
| TAT-054 | Add /tat resume | E8 | [ ] |

### Sprint N+1 — <goal>
| ID | Task | Epic | Status |
|----|------|------|--------|
| TAT-058 | Optional gstack integration | E9 | [ ] |
```

**Task IDs:**
- Format: `TAT-XXX` (zero-padded to 3 digits)
- Generated via `tat-state.sh new-task-id` (auto-increments counter in state.json)
- Assigned when a task is created, never reused
- Used in branch names, review artifacts, and state.json tracking

**Sprint rules:**
- Group tasks by delivery value, not by epic
- Current sprint at the top, future sprints below
- Completed sprints collapse into a "Completed Sprints" section
- After completing a sprint, reprioritize remaining tasks into the next sprint

---

## Important Rules

1. **Never jump to code without a plan.** If there's no spec or plan, create one first.
2. **User is product owner.** Final authority on all decisions.
3. **GPT is an advisor, not a gatekeeper.** Present GPT feedback, let user decide.
4. **Stay focused.** Off-scope ideas go to backlog, not into the current task.
5. **Tag your guidance.** The user should always know why you're saying something.
6. **Delegate, don't suggest.** If you're Opus and the task is coding, spawn a Sonnet subagent — don't ask the user to switch models. If you're Sonnet and the task needs architecture, escalate to Opus.
7. **Self-review before GPT review. Always.** Read the diff, check scope, fix issues — THEN send to GPT. GPT is a second opinion, not a substitute for your own QA. Never skip this.
