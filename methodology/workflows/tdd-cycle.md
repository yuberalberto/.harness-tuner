---
description: Red-Green-Refactor TDD cycle for implementing a single task
---

# TDD Cycle — Red-Green-Refactor

This workflow guides through the TDD red-green-refactor cycle for a single task.

## Trigger

Invoke this workflow when implementing a specific task from a spec, or adding a single piece of functionality. Usage: `/tdd-cycle [TASK-ID or description]`

## Steps

### Step 1: Understand the Task

- Read the task definition (from `spec.md` or user description)
- Identify acceptance criteria
- Understand dependencies and preconditions
- **Output**: clear understanding of what "done" looks like

### Step 2: Write Failing Tests (Red)

- For each acceptance criterion, write a test:
  - Use a descriptive name following the project's test naming convention
  - Follow AAA pattern (Arrange-Act-Assert)
  - Test the public interface, not implementation details
- Run tests — they MUST all fail (if any pass, the test is wrong or the feature already exists)
- **Output**: failing test suite that defines expected behavior

### Step 3: Make Tests Pass (Green)

- Write the MINIMUM code to make each test pass
- Do not optimize, do not refactor, do not add extras
- Focus only on making the red tests green
- Run tests after each small change
- **Output**: all tests passing with minimal implementation

### Step 4: Refactor

- Improve code quality while keeping tests green:
  - Extract functions if any are too long for the project's standards
  - Remove duplication
  - Improve naming
  - Simplify conditionals
- Run tests after each refactor step — they MUST stay green
- **Output**: clean code with all tests still passing

### Step 5: Edge Cases

- Add tests for edge cases not covered by acceptance criteria:
  - Empty/null inputs
  - Boundary values
  - Error conditions
  - Concurrent access (if applicable)
- Implement fixes for any new failing tests
- **Output**: robust implementation handling edge cases

### Step 6: Save Observation (MANDATORY)

Call `mem_save` to capture what was learned. This step is part of the workflow,
not a proactive suggestion — it must be executed before considering the task done.

Choose type based on the nature of the work:
- `pattern` — a reusable implementation technique applied
- `bugfix` — a bug was identified and its root cause is worth remembering
- `decision` — a non-obvious technical choice was made (e.g., picking algorithm A over B)

Minimum content:
- **What**: 1-2 sentences on what was implemented
- **Why**: the reason for the chosen approach (avoid stating the obvious)
- **Where**: file paths touched

Skip allowed only when the task was purely mechanical (e.g., renaming a parameter,
formatting). When skipping, state the skip explicitly to the user: "Skipping mem_save:
purely mechanical task with no learning to capture."

### Step 7: Document in Spec

If this task came from a `spec.md`, update the spec to reflect completion:

1. **Mark acceptance criteria** — check all criteria as `[x]` in the task section.

2. **Add implementation notes** — append an `**Implementation notes:**` block
   immediately after the acceptance criteria. Keep it scoped to THIS task only.
   Include:
   - What was done (brief, 2-4 lines)
   - Files touched and key changes per file
   - Non-obvious decisions or gotchas discovered during implementation
   - Compatibility fixes or deviations from the original plan (if any)

   Do NOT document other tasks or general project context.

3. **Update the Dependency Graph** — in the `## Dependency Graph & Execution Order`
   section at the top of the spec, mark this task as `✅`. Leave other tasks
   unchanged.

   Graph format example:
   ```
   TASK-001 (short label) ✅ ──┐
   TASK-002 (short label) ✅ ──┼──> TASK-004 (short label)
   TASK-003 (short label)    ──┘
   ```

This step replaces a separate "mark complete" step — the checked criteria and
`✅` in the graph are how `/spec-to-code` knows the task is done.

## Output

At completion:
- All acceptance criteria verified by passing tests
- Edge cases covered
- Code is clean and follows standards
- An Engram observation was saved (or the skip was justified)
- Spec updated: criteria checked, implementation notes added, dependency graph current
