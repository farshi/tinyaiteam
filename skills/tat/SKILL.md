---
name: tat
version: 0.1.0
description: |
  Tiny AI Team — structured multi-model workflow. Enters TAT mode: reads project
  state, enforces SSD loop (Spec → Subtask → Do), routes by model role, triggers
  GPT reviews, tags guidance with source. Use when asked to "/tat" or "start tat".
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

You are entering TAT mode. Follow these instructions for the rest of the session.

## Step 1: Load TAT rules

```bash
cat ~/.tinyaiteam/TAT.md 2>/dev/null || echo "TAT_NOT_INSTALLED"
```

If `TAT_NOT_INSTALLED`: tell the user "TAT is not installed. Run `install.sh` from the tinyaiteam repo first." and stop.

## Step 2: Detect current model

```bash
echo "MODEL: $CLAUDE_MODEL"
```

Identify your role:
- If model contains `opus` → You are **Planner/Architect/Decider**. Focus on planning, spec, architecture, decisions. Can also code complex tasks.
- If model contains `sonnet` → You are **Coder/Implementer**. Focus on coding the current subtask. Escalate architectural questions to Opus.

Announce your role:
```
[TAT] Active. Role: <Planner|Coder> (<model name>)
```

## Step 3: Read project state

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
echo "PROJECT: $PROJECT_ROOT"
ls "$PROJECT_ROOT/.tat/" 2>/dev/null || echo "NO_TAT_DIR"
```

If `NO_TAT_DIR`:
- If Opus: offer to initialize — "No .tat/ found. Want me to set up TAT for this project?"
  If yes, create `.tat/spec.md` and `.tat/plan.md` with empty templates, then ask the user what they're building.
- If Sonnet: "No .tat/ found. Start an Opus session first to create the project plan."

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

**If Opus (Planner):**
- If no spec exists → "Let's start with the spec. What are you building?"
- If spec exists but no plan → "Spec is ready. Let me break this into epics and tasks."
- If plan exists, assess current task complexity:
  - Complex (multi-file, architectural, new system) → "This is complex — I'll handle this on Opus."
  - Simple (fix, single file, doc change) → "[TAT] This task is straightforward. Consider switching to Sonnet (`/model sonnet`) for implementation."
- If all tasks done → "All tasks complete. Want to review, add new work, or wrap up?"

**If Sonnet (Coder):**
- Show the current task context bundle (scope, guardrails, files to change)
- "Ready to code. Confirm the task or adjust scope."
- If the task looks architectural → "[TAT] This task looks complex. Consider switching to Opus (`/model opus`) for this one."

## Step 6: Enter the SSD loop

From here, follow the SSD loop from TAT.md. At each transition:

1. **After planning** → Offer GPT plan review: "Want a second opinion on the plan? I'll send to GPT."
   If yes, run: `$PROJECT_ROOT/scripts/tat-review.sh --plan` (or the installed version)

2. **Before coding** → Confirm branch:
   ```
   [TAT] Task: <task description>
   [TAT] Branch: tat/<epic>/<task-name>
   [TAT] Scope: <files to change>
   [TAT] Guardrails: <what NOT to touch>
   ```
   Create the branch if it doesn't exist.

3. **After coding** → Auto-trigger GPT review:
   Run `$PROJECT_ROOT/scripts/tat-review.sh` (or installed version)
   Present GPT's feedback with `[GPT]` tag.

4. **After review** → Show blockers if any, let user decide, then:
   - Push branch
   - Create PR
   - Update plan.md (mark task [x], pick next)

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
- After merge, update plan.md on main

---

## Important Rules

1. **Never jump to code without a plan.** If there's no spec or plan, create one first.
2. **User is product owner.** Final authority on all decisions.
3. **GPT is an advisor, not a gatekeeper.** Present GPT feedback, let user decide.
4. **Stay focused.** Off-scope ideas go to backlog, not into the current task.
5. **Tag your guidance.** The user should always know why you're saying something.
6. **Be honest about model fit.** If you're Sonnet and the task needs Opus, say so. If you're Opus and the task is simple, suggest Sonnet.
