---
title: "I Built a Tiny AI Team — Because Autonomous AI Kept Losing Control of My Project"
date: 2026-03-30
platform: linkedin
type: article
tags: [AI, software engineering, autonomous coding, developer tools, AI workflow]
cover: ../cover/cover.png
---

# I Built a Tiny AI Team — Because Autonomous AI Kept Losing Control of My Project

Every week there's a new demo.

*"This AI agent just built an entire app."*
*"Vibe coding is the future."*
*"Just give it a task and walk away."*

I watched these videos. I read the posts. And I felt the pressure — if I'm not using autonomous AI to code, I'm falling behind.

So I tried it. For real, on real projects.

I tried Cline. I tried LangChain-style autonomous agents. I tried coding loops that promised to handle entire features end to end.

And at first, it was impressive. The AI would generate code fast, scaffold projects, wire things together.

But then I'd look at what it actually built.

It changed files I didn't ask it to change. I asked for a config option — it refactored the entire settings module, renamed three files, and broke two tests. It made architectural decisions without asking. It went in directions that made sense technically but not for the product. And the worst part — it forgot why we made certain decisions last session. Every new conversation started from zero.

The more I used these tools, the more frustrated I got. Not because they were bad — but because I was losing control of my own project.

It felt less like working with a team and more like managing a very fast junior developer who never sleeps and never remembers yesterday's meeting.

That's when something clicked:

**The problem isn't intelligence. Autonomous coding has no structure, no memory, and no roles.**

And software has never been built like that.

---

## Software Is Not Written by a Brain — It's Built by a Team

In real software teams:

- Someone writes the spec
- Someone designs the architecture
- Someone implements
- Someone reviews
- Someone decides what *not* to build
- Decisions are written down
- Work is broken into tasks
- Nothing gets merged without review

But with most AI coding tools today, we throw one AI at everything. One session. One brain. Architect, developer, reviewer, and product manager all at once.

**That's not a team. That's chaos with good autocomplete.**

---

## So I Started Something Simple

I stopped chasing full autonomy. I wanted something I could control. Something I could watch behave and understand why it made each decision.

A weekend project. Version 1.

I call it **TAT — Tiny AI Team**.

The idea is simple: don't use AI like a solo developer. Use AI like a team with roles.

---

## The Roles

- **Planner AI** — Writes the spec, designs architecture, breaks work into tasks
- **Builder AI** — Implements one task at a time, small focused work
- **Reviewer AI** — Reviews plans and code diffs, flags bugs and drift
- **Me (Human)** — Final decisions, priorities, direction — always in the loop

Human in the loop is not a weakness. It's the steering wheel.

---

## The Workflow

**Spec → Tasks → Branch → Code → Review → Merge → Repeat**

Everything is written into the repository as markdown:

- **spec.md** — what we're building and why
- **plan.md** — epics and tasks, checked off as we go
- **decisions.md** — why we chose X over Y
- **backlog.md** — ideas captured, not forgotten

The AI reads these before it acts. It doesn't guess from the current prompt — it knows the history. The repo becomes the source of truth, so context survives across sessions.

The project gets something most AI coding tools don't have: **memory**.

---

## But The Most Important Part Is This

This was just a weekend project — version 1.

But the real idea is not the scripts or the markdown files.

The real idea is this:

Every time I learn something — a mistake, a better practice, a rule, a workflow improvement — **I add it to the system.**

So next time, the machines follow that rule automatically.

Nothing slips.
Nothing gets forgotten.
Every lesson becomes part of the process.

Over time, this Tiny AI Team becomes a reflection of how I work and what I've learned.

**It's like turning experience into software.**

---

## Final Thought

I don't think the future is one autonomous AI that does everything.

I think the future looks more like this:

- AI planner
- AI builder
- AI reviewer
- Human product owner
- Repo as memory
- Workflow as guardrails

Not AI replacing the team. **AI becoming the team — with a human leading it.**

I stopped chasing full autonomy. I built something small, understandable, and under control.

A Tiny AI Team.

And this small weekend project taught me more about building software with AI than all the autonomous demos I watched online.

**Because the real problem was never intelligence.**

**It was always process.**

---

TAT is open source. You can check it out, try it, or just read the code:
[github.com/farshi/tinyaiteam](https://github.com/farshi/tinyaiteam)

If you've been experimenting with AI coding workflows, I'd love to hear what's working for you and what isn't. Drop a comment or open an issue on the repo.

This is version 1. It'll get better with every lesson learned — that's kind of the whole point.
