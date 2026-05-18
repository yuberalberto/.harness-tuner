---
name: create-spec
description: Create a new SDD spec directory with a single spec.md. If the feature description is brief or fuzzy, grills the user first to resolve design decisions before writing the spec. Use when starting a new feature or when user says "create spec" or "create-spec".
---

# Create Spec

Creates `specs/[feature-name]/spec.md`. If the input is under-specified, grills first.

## Trigger

Usage: `@create-spec [feature-name]: [description]`

## Process

### Step 1 — Assess input clarity

Read the description. If **Problem + Approach are already clear**, skip to Step 3.

If the description is brief, vague, or missing key design decisions, proceed to Step 2.

### Step 2 — Grill (if needed)

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answers. For each question:
- Ask **one question at a time**, waiting for the answer before continuing
- If a question can be answered by exploring the codebase, explore it instead of asking

Focus questions on:
1. **Problem** — What root problem does this solve? (not the solution)
2. **Scope** — What is explicitly out of scope?
3. **Approach** — Which modules/files are involved? Any new dependencies?
4. **Tasks** — What are the ordered steps? What are the testable acceptance criteria?

Stop when Problem, What, How, and at least one Task with criteria are resolved.

### Step 3 — Create spec

1. Create directory: `specs/[feature-name]/`
2. Create `spec.md` pre-filled with resolved answers:

```markdown
# [Feature Name]

## 1. Problem
[one sentence: root problem, not solution]

## 2. What
[one paragraph: feature description and purpose]

## 3. How
[high-level approach: modules/files, data shapes, dependencies]

## 4. Tasks

### TASK-001: [short title]
**Goal:** [one line]
**Files:** [list of files to create/modify]
**Message template:** [exact output the user/system will see — only when the
task produces visible output. Omit for internal-only tasks.]
**Hints:** [1-2 concise lines — API to use, where to hook in, key gotcha.
Not pseudo-code. Omit for straightforward tasks.]
**Acceptance criteria:**
- [ ] Criterion 1 (testable)
- [ ] Criterion 2 (testable)
**Depends on:** none
```

3. Show the created file to the user.

## Output

```
specs/[feature-name]/
└── spec.md      — Pre-filled from grilling session or direct input
```
