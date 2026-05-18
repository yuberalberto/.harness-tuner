---
name: spec-to-code
description: Run the full SDD+TDD pipeline for a new feature. Writes a single spec.md, gets user approval, implements each task via /tdd-cycle, and forces mem_save calls at approval and completion. Use for new features, API changes, data model changes.
disable-model-invocation: true
---

# /spec-to-code

Full SDD+TDD pipeline. The workflow definition lives in the project at
`.windsurf/workflows/spec-to-code.md` (so Cascade uses the same file).

Load the workflow content and follow it exactly:

!`cat .windsurf/workflows/spec-to-code.md`

## Task Format (applies to all projects)

Each task in the spec must include:

```
### TASK-001: [short title]
**Goal:** [one line]
**Files:** [list of files to create/modify]
**Message template:** [exact output the user/system will see — only when the
task produces visible output like CLI messages, bot responses, notifications,
emails, etc. Omit for internal-only tasks.]
**Hints:** [1-2 concise lines pointing the implementer in the right direction
— API to use, where to hook in, key gotcha. Not pseudo-code. Omit for
straightforward tasks.]
**Acceptance criteria:**
- [ ] Criterion 1 (testable)
- [ ] Criterion 2 (testable)
**Depends on:** none | TASK-XXX
```

The goal is that a junior engineer can pick up any task and know **what** to
build, **how it looks** when done, and **where to start** — without needing
the code spelled out.

## Grill the User (before approval)

Before finalizing the spec, identify design gaps, ambiguities, or decisions
that could go either way. Ask the user **one question at a time** using the
`AskUserQuestion` tool — never dump all questions in a single message.

Guidelines:
- Each question should have 2-4 concrete options with descriptions.
- Use `preview` for questions where the user needs to compare visual output
  (message formats, UI layouts, etc.).
- Group related decisions into a single multi-select question when choices
  are not mutually exclusive.
- If the user asks for your recommendation, give it with reasoning, then
  confirm with a follow-up `AskUserQuestion`.
- After all decisions are collected, update `spec.md` with the answers
  before moving to approval.

Skip this step if the spec was provided by the user with all decisions
already made, or if the feature is straightforward enough that no design
questions exist.

## Important

- If the workflow file (`.windsurf/workflows/spec-to-code.md`) is missing,
  this project has not been bootstrapped. Tell the user to run `/init-sdd` first.
- Do not skip the mandatory `mem_save` steps. They are part of the workflow,
  not proactive suggestions.
- For bug fixes or small testable changes, suggest `/tdd-cycle` instead.
- For trivial changes (typos, renames, formatting), suggest direct edits with
  the standard Permission Protocol.