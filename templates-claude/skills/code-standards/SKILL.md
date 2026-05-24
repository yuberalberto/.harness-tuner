---
name: code-standards
description: >
  Evaluate code style and naming conventions. Covers descriptive naming,
  WHY-only comments, single-responsibility functions, boundary validation,
  and dead code removal. Works standalone or invoked from tdd-cycle Refactor step.
allowed-tools: Read Glob Grep Bash
effort: medium
---

# Code Standards

Evaluate the current diff against language-agnostic style and naming conventions.
This skill works standalone for legacy cleanup or invoked as part of TDD Refactor.

## Principles

**1. Naming: Descriptive, No Unnecessary Abbreviations**

Use clear, intention-revealing names. Avoid abbreviations unless they are
universal and universally understood:

- ❌ `usr`, `acct`, `req` — unclear without context
- ✅ `user`, `account`, `request` — immediately clear
- ✅ `http`, `url`, `jwt` — universal abbreviations, acceptable

Variable names should expose intent. A reader should know what the variable
represents without reading surrounding code.

**2. Comments: WHY Only**

Comments should explain _why_ a decision was made, not _what_ the code does.
The code itself documents the "what."

- ❌ "Convert the user object to JSON" — the code already shows this
- ❌ "Added for issue #456" — historical noise, not actionable
- ❌ "TODO: fix this later" — commit the fix or remove the code
- ✅ "Cache this result because the API call is expensive"
- ✅ "Special case: handle null IDs in batch operations due to legacy data"

Never use "tombstone" comments (removed code left as comments). Use git history
to track what was deleted.

**3. Single Responsibility**

Each function should have one reason to change. If it does two things, split it.

- ❌ Function that fetches data, validates it, and saves it
- ✅ Separate: fetch → validate → save with clear interfaces

Functions should be small enough that their purpose is obvious from the name
and signature. Avoid nested callbacks or deeply indented side effects.

**4. Error Handling: Validate at Boundaries, Trust Internal Code**

Validation belongs at the edge — user input, external APIs, file I/O.

- ❌ Validate the same data in every internal function
- ✅ Validate once at the boundary, trust it within the module

Internal functions can assume preconditions. If they need to check, the boundary
validation is incomplete.

**5. Dead Code: Remove Rather Than Comment**

If code is not used, delete it. Git history preserves it. Comments claiming
"this might be useful later" create cruft.

- ❌ Old function commented out with "backup" comment
- ❌ Unused parameter "kept for backwards compatibility"
- ✅ Delete it; use git blame/log to recover if needed

## Workflow

### Step 1: Examine the Current Diff

Display the changes made since the last commit (or since tdd-cycle GREEN):

```
git diff HEAD
```

If the codebase is unchanged, inform the user and stop.

### Step 2: Evaluate Against Each Standard

For each file in the diff, assess:

**Naming**
- Are variable, function, and class names descriptive?
- Are abbreviations limited to universal terms (http, url, jwt)?
- Could a reader infer intent from the name alone?

**Comments**
- Do comments explain _why_ (design decisions, tradeoffs)?
- Are there WHAT comments (describing the code itself)?
- Are there tombstone comments (removed code or historical notes)?

**Function Size**
- Does each function do one thing?
- Are there nested side effects or callback chains?
- Would the code benefit from extraction?

**Error Handling**
- Where are inputs validated (user input, API responses, files)?
- Is validation duplicated in internal functions?

**Dead Code**
- Are there commented-out blocks?
- Are there unused variables, parameters, or functions?

### Step 3: Propose Refactors

For each issue found, suggest a concrete refactor. Be specific:

- Rename `usr` → `user` with exact files and lines
- Remove comment at line X; replace with explanation of _why_ (if needed)
- Extract function Y from lines A–B into separate function Z
- Delete commented-out code at lines M–N
- Move validation from internal function to boundary (entry point)

### Step 4: Interactive Review

Present each refactor suggestion to the user:

1. Show the current code (few lines of context)
2. Show the proposed change
3. Ask: "Proceed with this refactor? (yes/no/skip/edit)"

For each:
- **yes**: Apply the refactor
- **no**: Skip this suggestion
- **edit**: Ask user to provide alternative text/approach
- **skip**: Continue to next suggestion

### Step 5: Run Tests

After applying refactors:

```
[language-specific test command]
```

If tests pass, proceed to Step 6. If tests fail, revert the refactor and
inform the user.

### Step 6: Summary

Report:

- Number of issues found
- Refactors applied
- Refactors skipped
- Any test failures or follow-up actions

If invoked from tdd-cycle, the user can now proceed to commit (Step 5 → Step 7
in tdd-cycle).

## Context

This skill is most effective when:

- Changes are fresh (just completed GREEN in TDD cycle)
- The codebase is small enough to review in one pass
- The user is open to refactoring suggestions

For large diffs or legacy code, consider running this skill in multiple passes
(one file or module at a time).
