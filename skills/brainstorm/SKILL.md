---
name: brainstorm
version: 0.2.0
description: |
  Brainstorming skill for TAT projects. Three-phase ideation: GPT thinks
  independently first (no bias), then Opus critiques, then user decides.
  Max 3 rounds. Output is draft epics and tasks sorted by ease of
  implementation. Use when asked to "/brainstorm" or "brainstorm this".
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

# /brainstorm — Independent Ideation Loop

## When to Use

- Starting a new project or feature and need to explore approaches
- User says "brainstorm", "let's think about", "what should we build"
- Before creating epics/tasks in `/tat` — brainstorm first, plan second

## Step 1: Gather the Seed

Read the starting context:

```bash
TAT_DIR=".tat"
cat "$TAT_DIR/spec.md" 2>/dev/null
cat "$TAT_DIR/plan.md" 2>/dev/null
```

Ask the user if no spec exists: "What are you trying to build or solve?"

Combine into a **seed prompt** — the spec + any user input. This is what GPT and Opus both work from.

Show the seed:
```
[BRAINSTORM] Seed: <1-2 sentence summary of what we're brainstorming>
[BRAINSTORM] Starting round 1 of 3. GPT goes first.
```

## Step 2: The Loop (max 3 rounds)

Each round has 3 phases in strict order:

### Phase A: GPT (independent, no bias)

Send ONLY the seed + user input to GPT. Do NOT include Opus's opinions, analysis, or suggestions. GPT must think independently.

Run via the shared GPT caller:
```bash
source ~/.tinyaiteam/config.sh
source scripts/tat-gpt.sh  # or ~/.tinyaiteam/scripts/tat-gpt.sh
```

**GPT system prompt:**
```
You are a senior product engineer brainstorming a project.
Think independently — do not defer to prior opinions.

Given the project goal, propose:
1. Possible approaches (2-3 max)
2. Recommended approach and why
3. Draft epics and tasks, sorted by ease of implementation (easiest first)
4. Risks or unknowns

Keep it concise. Output as markdown with ## headers.
```

**GPT user prompt:** The seed (spec + user input). In rounds 2-3, also include the user's feedback from the previous round.

Present GPT's response:
```
[GPT] Round <N> ideas:
<GPT's response>
```

### Phase B: Opus (critique and refine)

Now Opus reviews GPT's output. Opus should:
- Agree or disagree with GPT's approach — say why
- Add architecture or feasibility considerations GPT missed
- Suggest different task breakdown if GPT's is wrong
- Flag anything that's harder than it looks

Present as:
```
[OPUS] Round <N> thoughts:
<Opus's critique and additions>
```

**Important:** Opus critiques and refines. Do not rewrite everything GPT said. Build on it.

### Phase C: Auto-continue or User decides

**Rounds 1-2 auto-continue:** After Opus critiques, feed the combined output (seed + GPT ideas + Opus critique) into the next round automatically. Do NOT stop to ask the user. The 3 rounds are GPT ↔ Opus reasoning back and forth.

**Round 3 only — present to user:**
After round 3, present the final synthesized result and ask:
```
[BRAINSTORM] 3 rounds complete. Options:
  1. Looks good — finalize into plan
  2. Edit before finalizing
  3. Start over with different direction
```

- If **1**: go to Step 3 (finalize)
- If **2**: let user edit, then finalize
- If **3**: reset and restart from Step 1

### Round Narrowing

- **Round 1:** Broad — explore approaches, generate options
- **Round 2:** Focused — GPT refines based on Opus's critique, Opus sharpens further
- **Round 3:** Final — converge on concrete epics and tasks, resolve disagreements

## Step 3: Finalize

After the user approves, produce a draft plan:

```markdown
## Epic <N>: <name>
- [ ] <task — easiest first>
- [ ] <task>
- [ ] <task>

## Epic <N+1>: <name>
- [ ] <task>
...
```

Rules:
- Sort tasks within each epic by ease of implementation (easiest first)
- Keep tasks small — one branch, one PR each
- No task should take more than one session

Present the draft:
```
[BRAINSTORM] Draft plan ready. <N> epics, <M> tasks.
```

Then ask:
```
[BRAINSTORM] Options:
  1. Write to .tat/plan.md and start /tat
  2. Edit the plan first
  3. Save as draft only (.tat/brainstorm-draft.md)
```

If **1**: write to `plan.md` (append if epics already exist) and suggest starting `/tat`.
If **2**: let user edit, then write.
If **3**: save as draft for later.

---

## Important Rules

1. **GPT goes first in round 1.** Never send Opus's opinion to GPT in round 1. After that, GPT gets Opus's critique to refine — this is collaborative reasoning, not groupthink.
2. **Max 3 rounds, hard stop.** No exceptions. User must decide after round 3.
3. **Output is markdown.** No structured schemas, no JSON. Just epics and tasks.
4. **Easiest first.** Sort by implementation ease, not importance.
5. **Small tasks.** Each task = one branch = one PR = one session.
6. **User is final authority.** GPT and Opus advise. User decides.
7. **Don't plan during brainstorm.** This skill produces a draft plan. Execution starts in `/tat`.
