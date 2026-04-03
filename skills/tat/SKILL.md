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

This reads unseen session entries + diff, writes GPT responses back into `session.md`, and updates `.tat/gpt.md`.

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
   [TAT] Branch: <TASK-ID>/<slug>
   [TAT] Files: <list>
   ```

2. Spawn Agent with `model: "sonnet"` — include task, branch, files, guardrails

3. When Sonnet returns:
   - Self-review the diff
   - Check `.tat/session.md` for GPT notes
   - Fix issues
   - Push, PR, merge

---

## Three-Chair Model

TAT is three people working together:
- **User** — Product Owner. Intent, priorities, corrections, final authority.
- **GPT** — Senior Advisor. Critiques, alternatives, risk flags. Always watching.
- **Opus** — Orchestrator. Decides, executes, manages flow, delegates to Sonnet.

### Meeting Modes

Opus detects the mode from context, or user declares it explicitly:

| Mode | User's role | GPT's role | Opus's role |
|------|-------------|-----------|-------------|
| **Design** | Share vision, react | Suggest patterns, challenge | Capture decisions, ask questions |
| **Planning** | Prioritize, scope | Challenge estimates, flag risks | Break into tasks, sequence |
| **Coding** | Approve/correct | Review diffs, catch bugs | Write code, self-review |
| **Review** | Final sign-off | Deep analysis | Present summary |

---

## Session Log (MANDATORY)

Claude maintains `.tat/session.md` — a timestamped log of the session. All three voices. This is how GPT stays in the loop.

**After every user turn, append a bullet:**
```
- [HH:MM][Mode][Speaker] what happened — 1 line
```

**Examples:**
```
- [14:30][Design][User] wants GPT to see conversations, not just diffs
- [14:32][Design][Opus] proposed session.md with three voices
- [14:35][Design][GPT] sound approach, add ack mechanism for continuity
- [14:40][Design][User] @@ what about brainstorming, don't lose that
- [14:42][Decision] keep /brainstorm as explicit 3-round flow
```

**Rules:**
- One bullet per significant action. Keep each line short.
- Tag with mode and speaker: `[User]`, `[Opus]`, `[Sonnet]`, `[GPT]`, `[Decision]`
- `[Decision]` entries also go into decisions.md.
- `@@` marks urgent — GPT addresses these first.
- When file exceeds 400 lines, archive older entries to `.tat/archive/session-<date>.md` and add a summary block at top.
- session.md is in `.gitignore` — it's session state, not code.
- **This is mandatory.** Every user turn gets logged.

---

## Today File

At session start, Opus creates or updates `.tat/today.md`:

```markdown
DATE: 2026-04-03
MODE: Planning

GOALS:
- TAT-111: Session log + GPT as third team member

SCOPE:
- SKILL.md, tat-gpt-watch.sh, TAT.md

OUT OF SCOPE:
- Anything not tied to today's goals
```

User confirms or adjusts. GPT sees this on every call. today.md is in `.gitignore`.

---

## GPT Briefing

Every GPT call automatically gets this header:

```
MODE: <Design|Planning|Coding|Review>
TODAY: <from today.md>
LAST DECISIONS: <last 3 from decisions.md>
SESSION: <last 10 entries from session.md>
DIFF: <if coding/review mode>
```

GPT must start every response with an acknowledgment:
```
ACK: Task=<one-line> | Constraints=<key constraints>
```
This forces GPT to prove it understands the context before advising.

---

## Working Flow

**Before coding:** Know what task you're doing. Confirm today.md scope.

**While coding:** Stay in scope. Off-topic ideas → append to bottom of plan.md:
```
[TAT] Noted — added to backlog.
```

**After coding:**
1. Self-review your diff (`git diff`). Check scope, bugs, completeness.
2. Commit.
3. GPT reviews automatically (PostToolUse hook fires after commit).
4. Read GPT's response in `.tat/session.md` or `.tat/gpt.md`.
5. If GPT flagged issues → fix and commit again.
6. Mark task `[x]` in plan.md (on the branch).
7. Push, create PR, merge.

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
