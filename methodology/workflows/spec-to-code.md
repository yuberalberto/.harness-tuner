---
description: Lightweight SDD+TDD pipeline — from feature idea to tested code
---

# Spec-to-Code — Simplified SDD+TDD Pipeline

This workflow guides through a lightweight Spec-Driven Development pipeline
combined with Test-Driven Development. One spec file per feature, ephemeral,
backed by Engram for decision capture.

## Trigger

Invoke this workflow when starting a new feature, API/data model change,
or architectural change. Usage: `/spec-to-code [feature-name]: [brief description]`

For bug fixes or single testable improvements, use `/tdd-cycle` directly instead.
For trivial changes (typos, renames, formatting), no workflow is needed.

## Steps

### Step 1: Write the Spec

Create `specs/[feature-name]/spec.md` with these sections:

**1. Problem** — one sentence describing the root problem (not the solution).

**2. What** — one paragraph describing the feature and its purpose.

**3. How** — high-level approach. Mention modules/files involved, key data
shapes, and external dependencies. No diagrams or formal contracts unless the
feature is genuinely complex.

**4. Tasks** — ordered, numbered list. Each task must:
- Be implementable in ≤ 2 hours
- Have explicit acceptance criteria (these become tests)
- Declare dependencies on prior tasks (if any)

Task format:
```
### TASK-001: [short title]
**Goal:** [one line]
**Acceptance criteria:**
- [ ] Criterion 1 (testable)
- [ ] Criterion 2 (testable)
**Depends on:** none | TASK-XXX
```

### Step 2: Get User Approval

Show the spec to the user. Wait for explicit approval before coding.
If the user requests changes, edit `spec.md` and re-confirm.

### Step 3: Save Approval to Engram (MANDATORY)

Immediately after approval, call `mem_save`:
- `title`: "Spec approved: [feature-name]"
- `type`: "decision"
- `content`: brief What + Why summary from the spec (3-5 lines)

This step is part of the workflow, not optional. It guarantees the decision
to build this feature is captured even if Engram saves get forgotten elsewhere.

### Step 4: Implement Each Task with TDD

For each task in order:
1. Invoke `/tdd-cycle TASK-XXX`
2. The TDD cycle handles red → green → refactor → edge cases → mem_save → mark `[x]`
3. Move to next task only when current is fully green and marked `[x]`

### Step 5: Save Completion to Engram (MANDATORY)

When all tasks are `[x]`, before archiving the spec, call `mem_save`:
- `title`: "Completed: [feature-name]"
- `type`: "decision"
- `content`: what was built (1-2 lines) + key technical decisions made during
  implementation + any gotchas discovered

This is the second mandatory save. It complements the per-task saves from
`/tdd-cycle` by providing a feature-level summary.

### Step 6: Archive the Spec

Move `specs/[feature-name]/` to `specs/archived/[feature-name]/`.
Tests are the executable spec for current behavior; the archived spec
preserves original intent, decisions, and trade-offs for future reference.

## Output

At completion:
- Source code implementing the feature
- Test suite covering all acceptance criteria
- Two top-level Engram observations (approval + completion) plus per-task observations
- Spec archived in `specs/archived/[feature-name]/`
