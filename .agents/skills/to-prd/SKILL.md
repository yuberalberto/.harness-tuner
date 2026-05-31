---
name: to-prd
description: >
  Synthesize the current conversation context and codebase understanding into a
  PRD. Outputs to `.specs/<NNN>-<feature>/PRD.md` for local markdown-based tracking.
allowed-tools: Read Glob Grep Bash Write Edit
effort: high
---

# To PRD

Turn the current conversation context into a PRD and publish it to `.specs/<NNN>-<feature>/PRD.md`.

The PRD is the canonical artifact consumed by `/to-issues`. It must be self-contained — any agent can produce issues from it without seeing the grilling conversation.

Do NOT interview the user — synthesize what you already know.

## Process

### 1. Explore the Codebase

Read `CONTEXT.md` and `docs/adr/` if they exist. Understand the current state and use the project's domain vocabulary throughout the PRD.

### 2. Write the PRD

Draft the PRD using the template below.

**Behaviors must describe observable outcomes, not internals.** What the system does, not how. Each Behavior must be independently testable and map to at least one User Story.

**Append-only rule (for PRD edits)**: Never renumber existing IDs. Deleted entries leave a gap. New entries always get max(existing IDs) + 1.

#### PRD Template

```markdown
## Problem

[1–3 sentences. What hurts and why it matters now.]

## User Stories

- **US1 — [semantic name]**: As a [actor], I want [feature], so that [benefit].
- **US2 — [semantic name]**: As a [actor], I want [feature], so that [benefit].

## Behaviors

[Observable behaviors the system must exhibit. Each is testable and maps to one or more User Stories.]

### B1 — [semantic name]

[Observable outcome. Not "the function calls X" — "when Y happens, Z is the result."]

*Covers: US1*

### B2 — [semantic name]

[...]

*Covers: US1, US2*

## Constraints

[What cannot change: backward-compat requirements, platform limits, scope fences, dependencies that must not break.]

## Out of Scope

[What is explicitly excluded.]
```

### 3. Confirm with User

Present the PRD draft before publishing. Verify:
- Problem captures the real pain
- User Stories cover all actors and intents
- Behaviors are complete, independently testable, and at the right granularity
- Constraints and Out of Scope reflect real boundaries

### 4. Publish

Determine the `NNN` prefix:
- List directories under `.specs/` matching the pattern `NNN-*` (three-digit prefix + hyphen, e.g. `001-my-feature`)
- `NNN` = count of matches + 1, zero-padded to 3 digits
- If no numbered directories exist, `NNN = 001`
- If the spec folder already exists (e.g. created by a prior grilling session), use its existing `NNN`

Write to `.specs/<NNN>-<feature>/PRD.md`, creating the folder if needed.

**Folder naming convention** — verb-first slug:
- `add-<what>` — new feature or capability
- `fix-<what>` — bug fix or UX improvement
- `remove-<what>` — deletion or cleanup
- `refactor-<what>` — structural change without behavior change
- `improve-<what>` — enhancement to existing behavior
