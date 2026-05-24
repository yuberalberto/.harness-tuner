---
name: to-issues
description: >
  Break a plan, spec, or PRD into independently-grabbable issues using tracer-bullet
  vertical slices. Outputs to `.specs/<NNN>-<feature>/issues/` and generates `.specs/<NNN>-<feature>/INDEX.md`
  with dependency graph and status table.
allowed-tools: Read Glob Grep Bash Write Edit
effort: high
---

# To Issues

Break a plan into independently-grabbable issues using vertical slices (tracer
bullets).

## Process

### 1. Gather Context

Work from whatever is already in the conversation context. If the user passes an
issue reference (issue number, URL, or path) as an argument, fetch it from the
issue tracker and read its full body and comments.

### 2. Explore the Codebase (Optional)

If you have not already explored the codebase, do so to understand the current
state of the code. Issue titles and descriptions should use the project's domain
glossary vocabulary, and respect ADRs in the area you're touching.

### 3. Draft Vertical Slices

Break the plan into **tracer bullet** issues. Each issue is a thin vertical slice
that cuts through ALL integration layers end-to-end, NOT a horizontal slice of
one layer.

Slices may be 'HITL' or 'AFK':

- **HITL** (Human In The Loop) — requires human interaction, such as an
  architectural decision or a design review.
- **AFK** (Away From Keyboard) — can be implemented and merged without human
  interaction. Prefer AFK over HITL where possible.

#### Vertical Slice Rules

- Each slice delivers a narrow but COMPLETE path through every layer (schema, API,
  UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones

### 4. Quiz the User

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories this addresses (if the source
  material has them)

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?

Iterate until the user approves the breakdown.

### 5. Publish Issues and Generate INDEX.md

First, determine the spec folder's `NNN` prefix:
- List directories under `.specs/` that match the pattern `NNN-*` (three-digit
  numeric prefix followed by a hyphen, e.g. `001-my-feature`)
- Count them; the new spec's `NNN` = count + 1, zero-padded to 3 digits
- If no numbered directories exist, `NNN = 001`

Name the spec folder `.specs/<NNN>-<feature>/` where `<feature>` is the
kebab-case slug of the feature name.

For each approved slice, create a markdown file in `.specs/<NNN>-<feature>/issues/`
with the filename pattern: `<NNN>-<NN>-<slug>.md` where `<NNN>` matches the
spec folder prefix, `<NN>` is a zero-padded two-digit sequence number, and
`<slug>` is the kebab-case slug of the issue title.

Use the issue body template below.

After all issues are published, generate `.specs/<NNN>-<feature>/INDEX.md` containing:

1. **Dependency Graph** — ASCII-art representation of issue dependencies
2. **Status Table** — list all issues with status column (values: `ready`,
   `blocked`, `in-progress`, `done`)

#### Issue File Template

```
# <NNN>-<NN> - <Issue Title>

## What to Build

A concise description of this vertical slice. Describe the end-to-end behavior,
not layer-by-layer implementation.

Avoid specific file paths or code snippets — they go stale fast. Exception: if a
prototype produced a snippet that encodes a decision more precisely than prose
can (state machine, reducer, schema, type shape), inline it here and note
briefly that it came from a prototype. Trim to the decision-rich parts — not a
working demo, just the important bits.

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked By

- Issue reference (if any)

Or "None - can start immediately" if no blockers.

## Type

HITL or AFK

## User Stories Covered

- User story reference (if applicable)
```

#### INDEX.md Template

```
# <Feature> Issues

## Dependency Graph

ASCII representation of issue dependencies. Example:

┌──────────┐
│ NNN-01   │
└──────────┘
  │
  ├─→ ┌──────────┐
  │   │ NNN-02   │
  │   └──────────┘
  │     │
  │     └─→ ┌──────────┐
  │         │ NNN-03   │
  │         └──────────┘
  │
  └─→ ┌──────────┐
      │ NNN-04   │
      └──────────┘

## Status Table

| Issue  | Title | Type | Status | Blocked By |
|--------|-------|------|--------|-----------|
| NNN-01 | Initial setup | AFK | ready | - |
| NNN-02 | Core logic | AFK | blocked | NNN-01 |
| NNN-03 | Integration | HITL | blocked | NNN-02 |
| NNN-04 | UI component | AFK | blocked | NNN-01 |
```

### 6. Confirm with User

Present the issues breakdown and INDEX.md to the user for approval before
publishing to `.specs/`.
