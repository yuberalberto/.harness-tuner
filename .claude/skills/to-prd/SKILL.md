---
name: to-prd
description: >
  Synthesize the current conversation context and codebase understanding into a
  PRD. Outputs to `.specs/<feature>/PRD.md` for local markdown-based tracking.
allowed-tools: Read Glob Grep Bash Write Edit
effort: high
---

# To PRD

Turn the current conversation context into a PRD and publish it to `.specs/<feature>/PRD.md`.

Do NOT interview the user — just synthesize what you already know.

## Process

### 1. Explore the Codebase

Understand the current state of the codebase, if you haven't already. Use the
project's domain glossary vocabulary throughout the PRD, and respect any ADRs in
the area you're touching.

### 2. Sketch Modules

Sketch out the major modules you will need to build or modify to complete the
implementation. Actively look for opportunities to extract deep modules (small
interface, lots of implementation).

**Deep module** = encapsulates a lot of functionality in a simple, testable
interface which rarely changes.

Check with the user that these modules match their expectations. Check with the
user which modules they want tests written for.

### 3. Write the PRD

Write the PRD using the template below, then publish it to `.specs/<feature>/PRD.md`.

#### PRD Template

```
## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A comprehensive numbered list of user stories. Each in the format:

1. As an <actor>, I want a <feature>, so that <benefit>

Example:
1. As a mobile bank customer, I want to see balance on my accounts, so that I can
   make better informed decisions about my spending

Cover all aspects of the feature with extensive user stories.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being
outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more
precisely than prose can (state machine, reducer, schema, type shape), inline it
within the relevant decision and note briefly that it came from a prototype.
Trim to the decision-rich parts — not a working demo, just the important bits.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not
  implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this PRD.

## Further Notes

Any further notes about the feature.
```

### 4. Confirm with User

Before publishing, present the PRD to the user for approval. Make sure the
modules, user stories, and decisions align with their intent.

### 5. Publish

Create `.specs/<feature>/` if needed, then write `.specs/<feature>/PRD.md`
with the approved PRD.

**Folder naming convention** — use a verb-first slug that describes the action:
- `add-<what>` — new feature or capability
- `fix-<what>` — bug fix or UX improvement
- `remove-<what>` — deletion or cleanup
- `refactor-<what>` — structural change without behavior change
- `improve-<what>` — enhancement to existing behavior

Examples: `add-cascade-support`, `fix-update-prompts`, `remove-context7`
