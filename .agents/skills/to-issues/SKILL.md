---
name: to-issues
description: >
  Break a PRD into independently-grabbable issues using tracer-bullet vertical slices.
  Reads `.specs/<NNN>-<feature>/PRD.md` as its canonical input. Outputs to
  `.specs/<NNN>-<feature>/issues/` and generates `.specs/<NNN>-<feature>/INDEX.md`.
allowed-tools: Read Glob Grep Bash Write Edit
effort: high
---

# To Issues

Break a PRD into independently-grabbable issues using vertical slices (tracer bullets).

## Process

### 1. Read the PRD

Load the PRD as the primary input. In order of precedence:

1. Path passed as argument (e.g. `/to-issues .specs/003-add-auth/PRD.md`)
2. PRD written earlier in the current conversation context
3. Most recently modified `PRD.md` under `.specs/`

The PRD's `Behaviors` section is the source of Acceptance Criteria for all issues. The `User Stories` section provides coverage mapping. `Constraints` and `Out of Scope` bound what each issue may touch.

If no PRD exists, raise the issue and suggest running `/to-prd` first (or `/create-spec` for the full flow).

### 2. Explore the Codebase (Optional)

If you have not already explored the codebase, do so to understand the current state. Issue titles and descriptions should use the project's domain glossary and respect ADRs in the area being touched.

### 3. Draft Vertical Slices

Break the PRD's Behaviors into **tracer bullet** issues. Each issue is a thin vertical slice that cuts through ALL integration layers end-to-end — not a horizontal layer slice.

Each issue must cover one or more Behaviors completely. A Behavior should not be split across multiple issues.

Slices are **HITL** (requires human interaction) or **AFK** (can be completed without interruption). Prefer AFK.

#### Vertical Slice Rules

- Delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- Demoable or verifiable on its own when done
- Prefer many thin slices over few thick ones

### 4. Quiz the User

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Behaviors covered**: which BN IDs from the PRD
- **Type**: HITL / AFK
- **Blocked by**: which other slices (if any)
- **User Stories covered**: which USN IDs

Ask:
- Does the granularity feel right?
- Are the dependency relationships correct?
- Should any slices be merged or split?
- Are HITL/AFK assignments correct?

Iterate until the user approves.

### 5. Publish Issues and INDEX.md

Use the spec folder from the PRD path (e.g. `.specs/003-add-auth/`). Do not create a new NNN prefix — it was established when the PRD was written.

If running standalone without an existing NNN folder, determine NNN by counting directories under `.specs/` matching `NNN-*` (count + 1, zero-padded to 3 digits). If no numbered directories exist, `NNN = 001`.

For each approved slice, write `.specs/<NNN>-<feature>/issues/<NNN>-<NN>-<slug>.md` using the template below.

Then write `.specs/<NNN>-<feature>/INDEX.md`.

#### Issue File Template

```markdown
# <NNN>-<NN> — <Issue Title>

## What to Build

[Concise end-to-end description of this slice. Behavior-first: what the system does, not how.
Do not reference specific file paths or implementation details — describe the observable outcome.]

## Acceptance Criteria

- [ ] <Transcribed verbatim from B1 in the PRD>
      <sub>Source: [PRD.md#b1](../PRD.md#b1--semantic-slug)</sub>
- [ ] <Transcribed verbatim from B3 in the PRD>
      <sub>Source: [PRD.md#b3](../PRD.md#b3--semantic-slug)</sub>

## Behaviors Covered

B1, B3

## User Stories Covered

US1, US2

## Blocked By

- <Issue reference> or "None — can start immediately"

## Type

HITL or AFK
```

#### INDEX.md Template

```markdown
# <Feature> — Issues

## Dependency Graph

[ASCII-art representation of issue dependencies]

## Status Table

| Issue  | Title | Type | Status | Blocked By |
|--------|-------|------|--------|-----------|
| NNN-01 | ... | AFK | ready | — |
| NNN-02 | ... | AFK | blocked | NNN-01 |
```

### 6. Confirm with User

Present the issues and INDEX.md before publishing to `.specs/`.
