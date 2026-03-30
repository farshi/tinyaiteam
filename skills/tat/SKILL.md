---
name: tat
version: 0.1.0
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

---

## Status Command

When the user says `/tat status`, show a compact project dashboard. No activation, no mode change — just info.

Read `.tat/plan.md` and `.tat/spec.md`, then display:

```
[TAT] Status: <project name from spec>
[TAT] Model: <current model> (Role: <Planner|Coder>)
[TAT] Branch: <current git branch>
──────────────────────────────
[TAT] Current epic: <epic heading>
[TAT] Current task: <first [~] or [ ] task>
[TAT] Next up: <the task after current>
──────────────────────────────
[TAT] Progress:
  Epic 1: ████████████ 8/8 done
  Epic 2: ████████░░░░ 7/7 done
  Epic 2b: ██████░░░░ 6/8 done  ← you are here
  Epic 4: ░░░░░░░░░░ 0/4 done
──────────────────────────────
[TAT] Backlog: <N items>
[TAT] Open PRs: <list or "none">
```

Then stop. Do not enter TAT mode or start the SSD loop.

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
- `docs(plan):` commits (updating plan.md after merge)
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

     ## Epic 1: Foundation
     - [ ] Define project scope and spec
     - [ ] Set up project structure

     ## Backlog
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

## Step 6: Enter the SSD loop

From here, follow the SSD loop from TAT.md. At each transition, print and follow the checkpoint map below. Do NOT skip steps or combine them.

---

### Checkpoint Map

At every task transition, print this map and check off each step as you complete it. This is mandatory — not optional guidance.

**PLAN checkpoint:**
```
[TAT] ▶ PLAN checkpoint:
  [ ] 1. Show task + epic from plan.md
  [ ] 2. Offer GPT plan review (tat-plan-review.sh)
  [ ] 3. User approves plan
```

**CODE checkpoint:**
```
[TAT] ▶ CODE checkpoint:
  [ ] 1. Create branch: tat/<epic>/<task-name>
  [ ] 2. Show scope: files to change + guardrails
  [ ] 3. User confirms scope
  [ ] 4. Code the task
```

**REVIEW checkpoint (after coding, before PR):**
```
[TAT] ▶ REVIEW checkpoint:
  [ ] 1. SELF-REVIEW: read full diff (git diff main...HEAD)
  [ ] 2. SELF-REVIEW: check scope — any files that shouldn't be here?
  [ ] 3. SELF-REVIEW: check for bugs, edge cases, incomplete work
  [ ] 4. SELF-REVIEW: fix anything found, commit fixes
  [ ] 5. Show self-review summary to user
  [ ] 6. GPT REVIEW: run tat-code-review.sh
  [ ] 7. Show GPT feedback to user
  [ ] 8. Address GPT blockers if any
```

**SHIP checkpoint (after review, before merge):**
```
[TAT] ▶ SHIP checkpoint:
  [ ] 1. Rebase on latest main
  [ ] 2. Verify diff scope (git diff origin/main --name-only)
  [ ] 3. No untracked files (git ls-files --others --exclude-standard)
  [ ] 4. Confirm REVIEW checkpoint completed (self-review + GPT review)
  [ ] 5. Push branch
  [ ] 6. Create PR with GPT review response
  [ ] 7. GPT reviews the PR (run tat-code-review.sh on final state)
  [ ] 8. User approves merge
```

**POST-MERGE checkpoint:**
```
[TAT] ▶ POST-MERGE checkpoint:
  [ ] 1. git checkout main && git pull origin main
  [ ] 2. Update plan.md — mark task [x]
  [ ] 3. Run install.sh if skills/config changed
  [ ] 4. Commit plan update, push to main
  [ ] 5. Show next task + model routing
```

---

**Rule: print the checkpoint map at each transition.** Seeing the checklist prevents skipping steps. Check off each item as you complete it. If you catch yourself about to skip ahead, stop and go back to the map.

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
3. Append it to `plan.md` under the `## Backlog` section:
   ```
   - [ ] <idea> (noted during <current epic>)
   ```
4. Continue with the current task

Never silently dismiss an idea. Always confirm capture.

---

## Git Workflow

- One subtask = one branch = one PR
- Branch naming: `tat/<epic-number>/<task-name>`
- Always work on a branch, never directly on main
- After merge, update plan.md on main and run `install.sh` if skills/config changed

### Pre-PR Checklist

Before creating a PR, TAT must complete this checklist:

```
[TAT] Pre-PR checklist:
  1. Rebase on latest main
     git fetch origin && git rebase origin/main
  2. Verify diff scope — only files related to the current task
     git diff origin/main --name-only
  3. No untracked files left behind
     git ls-files --others --exclude-standard
  4. GPT code review completed
     ./scripts/tat-code-review.sh main
  5. GPT review response summary written
```

Run each step. If step 1 has conflicts, resolve them before continuing. If step 2 shows unexpected files, flag scope creep to the user. If step 4 has blockers, address them before creating the PR.

Then create the PR with this structure:

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

### Post-Merge Checklist

After a PR is merged:

1. Sync local main:
   ```bash
   git checkout main && git pull origin main
   ```
2. Update plan.md — mark completed tasks `[x]`, pick next `[~]` task
3. If skills or config files changed, run `install.sh`
4. Commit plan update to main:
   ```
   git add .tat/plan.md && git commit -m "Update plan: mark <task> complete"
   git push origin main
   ```
5. Show next task:
   ```
   [TAT] Merged. Next task: <next [ ] task>
   [TAT] Model routing: <Opus or Sonnet recommendation for next task>
   ```

---

## Important Rules

1. **Never jump to code without a plan.** If there's no spec or plan, create one first.
2. **User is product owner.** Final authority on all decisions.
3. **GPT is an advisor, not a gatekeeper.** Present GPT feedback, let user decide.
4. **Stay focused.** Off-scope ideas go to backlog, not into the current task.
5. **Tag your guidance.** The user should always know why you're saying something.
6. **Delegate, don't suggest.** If you're Opus and the task is coding, spawn a Sonnet subagent — don't ask the user to switch models. If you're Sonnet and the task needs architecture, escalate to Opus.
7. **Self-review before GPT review. Always.** Read the diff, check scope, fix issues — THEN send to GPT. GPT is a second opinion, not a substitute for your own QA. Never skip this.
