---
name: tat
version: 2.0.0
description: |
  Tiny AI Team v2 — lightweight orchestration for Claude Code. Loads project
  context, picks next task, coordinates Opus/Sonnet/GPT. GPT reviews in
  background. Use when asked to "/tat", "/tat status", or "/tat report".
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

# /tat — Tiny AI Team v2

## Subcommand Detection

Parse the user's input:
- `/tat` or no arguments → Full activation
- `/tat status` → **Status Command**
- `/tat init` → **Init Flow**
- `/tat review` → **Review Command**
- `/tat report` → **Report Command**
- `/tat replan` → **Replan Command**
- `/tat version` → **Version Command**

---

## Status Command

Read `.tat/plan.md` and `.tat/spec.md`, then display:

```
[TAT] Status: <project name from spec>
[TAT] Model: <current model> (Role: <Orchestrator|Coder>)
[TAT] Branch: <current git branch>
──────────────────────────────
[TAT] Current task: <first [ ] task>
[TAT] Next up: <the task after current>
──────────────────────────────
[TAT] Progress: ██████░░░░ 5/8 done
[TAT] Open PRs: <list or "none">
```

Then stop.

---

## Version Command

```bash
cat ~/.tinyaiteam/VERSION 2>/dev/null || echo "unknown"
```

```
[TAT] v<version>
[TAT] Working directory: <pwd>
```

Then stop.

---

## Review Command

Force a deep GPT review of the current branch. GPT sees both the conversation log and code diff:

```bash
~/.tinyaiteam/scripts/tat-gpt-watch.sh
```

This reads unseen conversation entries + diff, writes GPT responses back into `conversation.md`, and updates `.tat/gpt.md`.

Show GPT output with `[GPT]` tag. Add your own opinion with `[OPUS]` tag.
Then stop.

---

## Report Command

When the user says `/tat report <text>` or Claude spots a pattern/bug worth capturing:

```bash
PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
DATE=$(date -u +"%Y-%m-%d")
echo -e "\n### $DATE — $PROJECT_NAME\n$TEXT\n" >> ~/.tinyaiteam/reports.md
```

Print: `[TAT] Noted.`

Then stop. No ceremony. Claude should also call this proactively when hitting errors or spotting patterns during work.

---

## Replan Command

When the user says `/tat replan`:

1. Read plan.md and spec.md
2. Send to GPT via `ask-gpt.sh`:
   ```
   "Here's the current task list and spec. Suggest priority order.
   Consider: value to users, dependencies, effort. Be opinionated."
   ```
3. Show GPT's prioritization with `[GPT]` tag
4. Opus adds opinion with `[OPUS]` tag
5. User approves changes
6. Update plan.md with new order
7. Log replan timestamp:
   ```bash
   echo "$(date -u +%Y-%m-%d) — replanned" >> ~/.tinyaiteam/replan.log
   ```

Then stop.

---

## Init Flow

When the user types `/tat init`:

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
ls "$PROJECT_ROOT/.tat/" 2>/dev/null || echo "NO_TAT_DIR"
```

If `.tat/` exists: `[TAT] Already initialized. Use /tat to continue.` Stop.

If `NO_TAT_DIR`:
1. Create `.tat/spec.md`:
   ```markdown
   # <Project Name>

   ## What
   <describe your project>

   ## Why
   <why are you building this>

   ## Constraints
   <any constraints>

   ## Constraints
   <any constraints>
   ```

3. Create `.tat/decisions.md`:
   ```markdown
   # Decisions

   Key decisions with rationale. Append-only.
   ```

2. Create `.tat/plan.md`:
   ```markdown
   # Plan

   ## Tasks
   | ID | Task | Status |
   |----|------|--------|
   | TAT-001 | Define project scope and spec | [ ] |
   | TAT-002 | Set up project structure | [ ] |

   ## Done
   | ID | Task | Status |
   |----|------|--------|
   ```

3. Initialize state counter:
   ```bash
   ~/.tinyaiteam/scripts/tat-state.sh init
   ```

4. Install git hooks:
   ```bash
   if [ -d ~/.tinyaiteam/hooks ]; then
     cp ~/.tinyaiteam/hooks/pre-commit .git/hooks/ 2>/dev/null
     cp ~/.tinyaiteam/hooks/commit-msg .git/hooks/ 2>/dev/null
     chmod +x .git/hooks/pre-commit .git/hooks/commit-msg 2>/dev/null
   fi
   ```

5. Print:
   ```
   [TAT] Project initialized:
     ✓ .tat/ (spec + plan)
     ✓ Git hooks (commit format, branch enforcement)
   [TAT] What are you building?
   ```

---

## Full Activation

### Pre-Step: Branch Guard

```bash
git branch --show-current
```

If on `main`: **STOP.**
```
[TAT] ✗ You are on main. Create a branch first.
```

Exception: `/tat status`, `/tat init`, `/tat version` work on main.

If no task is active (all tasks done or plan empty), allow main for planning.

### Step 1: Load context

```bash
cat ~/.tinyaiteam/TAT.md 2>/dev/null || echo "TAT_NOT_INSTALLED"
cat ~/.tinyaiteam/VERSION 2>/dev/null || echo "unknown"
```

If `TAT_NOT_INSTALLED`: tell user to run `install.sh`. Stop.

Also load:
```bash
cat .tat/spec.md
cat .tat/plan.md
cat .tat/decisions.md 2>/dev/null
cat ~/.tinyaiteam/lessons.md 2>/dev/null
cat .tat/gpt.md 2>/dev/null
```

```
[TAT] Active v<version>. Role: <Orchestrator|Coder> (<model>)
[TAT] Loaded spec + plan + decisions + <N> lessons.
```

Check replan freshness:
```bash
# Count completed tasks since last replan
DONE_COUNT=$(grep -c '\[x\]' .tat/plan.md 2>/dev/null || echo "0")
LAST_REPLAN=$(tail -1 ~/.tinyaiteam/replan.log 2>/dev/null | cut -d' ' -f1 || echo "never")
```

If 10+ tasks completed and no replan in the last 10 tasks, nudge:
```
[TAT] ⚠ <N> tasks done since last replan (<date>). Consider /tat replan to reprioritize.
```
This is a nudge, not a gate. User can ignore it.

### Step 2: Detect model role

From your system prompt:
- `claude-opus-*` → **Orchestrator**: plan, delegate to Sonnet, review
- `claude-sonnet-*` → **Coder**: code the current task, escalate architecture to Opus

### Step 3: Show current position

```
[TAT] Project: <name from spec>
[TAT] Current task: <first [ ] task from plan.md>
[TAT] Progress: <X of Y done>
```

### Step 4: Start working

**If Opus:**
- No spec → "What are you building?"
- Spec but no plan → "Let me break this into tasks."
- Plan exists → Pick next `[ ]` task, create branch if needed, start working
- All done → "All tasks complete. Add more or wrap up?"

**If Sonnet:**
- Show task context, start coding
- Escalate architecture questions to Opus

### Delegation (Opus → Sonnet)

When Opus identifies a standard coding task:

1. Prepare context:
   ```
   [TAT] Delegating to Sonnet →
   [TAT] Task: <description>
   [TAT] Branch: tat/<task-name>
   [TAT] Files: <list>
   ```

2. Spawn Agent with `model: "sonnet"` — include task, branch, files, guardrails

3. When Sonnet returns:
   - Self-review the diff
   - Check `.tat/conversation.md` for GPT notes
   - Fix issues
   - Push, PR, merge

---

## Conversation Log (MANDATORY)

Claude maintains `.tat/conversation.md` — a running log of the session with three voices: User, Claude, GPT. GPT reads this to stay aware of everything happening, not just code diffs.

**After every user turn, append an entry:**
```markdown
### #<N> — <HH:MM>
**User:** <what they asked — 1 line>
**Claude:** <approach/decision taken — 1 line>
```

If the user corrected you, note it:
```markdown
### #<N> — <HH:MM>
**User:** use quality model not 4o-mini
**Claude:** Switched to gpt-5.2-codex. Previous approach was wrong.
**Correction:** was using cheap model for background review
```

**`!!` Red flag:** If user prefixes with `!!`, mark the entry:
```markdown
### #<N> — <HH:MM> ⚠️
**User:** !! why didn't GPT review fire?
**Claude:** Rate limit was blocking. Investigating.
```
⚠️ entries trigger immediate GPT review (not waiting for commit).

**GPT adds its line** after reviewing:
```markdown
### #17 — 15:30
**User:** build the GPT watcher
**Claude:** PostToolUse hook → bash script → writes to conversation.md
**GPT:** Sound approach. Watch for shell escaping in diff payloads.
```

**Rules:**
- One entry per user turn. Keep lines short (1 sentence each).
- Use the next entry number (check last `### #` in the file).
- GPT cursor tracked in `.tat/gpt-cursor` (just a number).
- When file exceeds 100 entries, archive old ones to `.tat/archive/conversation-<date>.md`.
- conversation.md is in `.gitignore` — it's session state, not code.
- This is **mandatory**. Every user turn gets logged. No exceptions.

---

## Working Flow

This is guidance, not a checkpoint map. Follow the spirit, not numbered steps.

**Before coding:** Know what task you're doing and which files you'll touch.

**While coding:** Stay in scope. Off-topic ideas → append to bottom of plan.md:
```
[TAT] Noted — added to backlog.
```

**After coding:**
1. Self-review your diff (`git diff main...HEAD`). Check scope, bugs, completeness.
2. Read `.tat/conversation.md` for GPT's latest notes.
3. For complex changes, run `/tat review` for deep GPT analysis.
4. Mark task `[x]` in plan.md (on the branch, not main).
5. Push, create PR, merge.

**After merge:**
```bash
git checkout main && git pull origin main
```
Show next task. If skills/scripts changed, run `install.sh`.

---

## Source Tagging

Tag guidance with source:
- `[TAT]` — TAT workflow rules
- `[GPT]` — GPT review feedback
- `[OPUS]` — Opus's own opinion (after GPT)
- `[SYSTEM]` — Claude safety rules
- `[CLAUDE.md]` — User's global rules
- `[PROJECT]` — Project CLAUDE.md rules

Normal conversation and code output is NOT tagged.

---

## Inline GPT Opinion

When the user asks for GPT's take ("ask GPT", "what does GPT think"):

```bash
~/.tinyaiteam/scripts/ask-gpt.sh "<question>"
```

Show with `[GPT]` tag. Opus adds opinion with `[OPUS]` tag. Don't auto-update files — wait for user decision.
