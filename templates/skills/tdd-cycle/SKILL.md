---
name: tdd-cycle
description: >
  Test-driven development with vertical slicing, Engram saves, and spec documentation.
  One test → one implementation → repeat. Planning confirms interface + behaviors.
  Engram saves at approval and completion. Document in Spec updates criteria and graph.
allowed-tools: Read Glob Grep Bash Write Edit
effort: high
---

# TDD Cycle

Test-driven development with red-green-refactor loop. Vertical slicing approach.
Includes planning step, Engram saves, and spec documentation.

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not
implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through
public APIs. They describe _what_ the system does, not _how_ it does it. A good
test reads like a specification — "user can checkout with valid cart" tells you
exactly what capability exists. These tests survive refactors because they don't
care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators,
test private methods, or verify through external means (like querying a database
directly instead of using the interface). The warning sign: your test breaks when
you refactor, but behavior hasn't changed. If you rename an internal function and
tests fail, those tests were testing implementation, not behavior.

See the support files for examples and detailed guidance:

- `tests.md` — good vs bad test examples
- `mocking.md` — when and how to mock (system boundaries only)
- `deep-modules.md` — small interface, lots of implementation
- `interface-design.md` — design for testability
- `refactoring.md` — refactor candidates after TDD cycle

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal
slicing" — treating RED as "write all tests" and GREEN as "write all code."

This produces **crap tests**:

- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things (data structures, function signatures)
  rather than user-facing behavior
- Tests become insensitive to real changes — they pass when behavior breaks, fail
  when behavior is fine
- You outrun your headlights, committing to test structure before understanding
  the implementation

**Correct approach**: Vertical slices via tracer bullets. One test → one
implementation → repeat. Each test responds to what you learned from the
previous cycle. Because you just wrote the code, you know exactly what behavior
matters and how to verify it.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

## Workflow

### Step 1 — Planning

When exploring the codebase, use the project's domain glossary so that test
names and interface vocabulary match the project's language, and respect ADRs in
the area you're touching.

Before writing any code, confirm with the user:

- [ ] What interface changes are needed?
- [ ] Which behaviors to test (prioritize)?
- [ ] Identify opportunities for deep modules (small interface, deep
      implementation)?
- [ ] Design interfaces for testability?
- [ ] List the behaviors to test (not implementation steps)?

Ask: "What should the public interface look like? Which behaviors are most
important to test?"

**You can't test everything.** Confirm with the user exactly which behaviors
matter most. Focus testing effort on critical paths and complex logic, not every
possible edge case.

Get explicit user approval on the plan before proceeding.

### Step 2 — Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

This is your tracer bullet — proves the path works end-to-end.

### Step 3 — Incremental Loop

For each remaining behavior:

```
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules:

- One test at a time
- Only enough code to pass current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

### Step 4 — Refactor

After all tests pass, look for refactor candidates:

- [ ] Extract duplication
- [ ] Deepen modules (move complexity behind simple interfaces)
- [ ] Apply SOLID principles where natural
- [ ] Consider what new code reveals about existing code
- [ ] Run tests after each refactor step

**Never refactor while RED.** Get to GREEN first.

Invoke `/code-standards` to evaluate the diff against naming conventions, comment
style, function size, error handling, and dead code. Apply suggested refactors
before proceeding to Step 5.

### Step 5 — Cycle Checklist

```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
```

### Step 5.5 — Test Naming Conventions

Test names MUST tell a story using this format:

```
<subject>__should_<behavior>__when_<context>
```

- **Subject**: domain concept (not a class/function name)
- **Behavior**: observable outcome in business language
- **Context**: precondition or trigger (`when_` may be omitted for happy path)

#### Examples

```
JwtValidator__should_accept_token__when_signature_valid
JwtValidator__should_reject_expired_token

LoginForm__should_submit_credentials__when_user_clicks_button
LoginForm__should_show_error__when_password_invalid
```

#### Test Classes

Group related tests in classes: `Test<Subject><Theme>`

Example:
```
TestJwtValidatorSignature
TestJwtValidatorExpiry
TestLoginFormSubmission
TestLoginFormValidation
```

### Step 6 — Engram Saves

Save to Engram at two key moments:

**Approval Save** — After the user approves the plan:

```
title: "TDD approval: <task name>"
type: decision
content:
  **What**: Planning phase approved for <task>
  **Why**: User confirmed interface + behaviors
  **Where**: <spec-file-or-feature>
  **Learned**: Key behaviors prioritized, deep modules identified
```

**Completion Save** — After all tests pass and refactoring is done:

```
title: "TDD complete: <task name>"
type: architecture
content:
  **What**: Implemented <feature/behavior>
  **Why**: Vertical slice with <N> test cycles
  **Where**: <files changed>
  **Learned**: <gotchas, patterns, or new insights>
```

### Step 7 — Document in Spec

After completion, update the spec file (if using a SDD spec):

1. Mark the acceptance criteria for this task as complete `[x]`
2. Add an "Implementation notes" section scoped to this task only — brief notes
   about key decisions made during implementation
3. Update the Dependency Graph at the top of the spec with a ✅ mark next to
   this task
4. Update `.specs/<feature>/INDEX.md` (if it exists) — change this issue's
   status from `in-progress` to `done`

This ensures each task completion self-documents and tracks progress visually.
