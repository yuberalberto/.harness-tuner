# Testing Standards

All code MUST be test-driven. Tests are **living documentation** — they are the
permanent, executable specification of what the system does. A product owner MUST
be able to understand what the system does by reading test titles alone.

## TDD Process

1. **Red**: Write a failing test that defines the expected behavior
2. **Green**: Write the minimum code to make it pass
3. **Refactor**: Clean up while keeping tests green
4. Repeat. Never write production code without a failing test first.

## Naming Convention

Test names MUST tell a story: `<subject>__should_<behavior>__when_<context>`

- **Subject**: domain concept (NOT a class/function name)
- **Behavior**: observable outcome in business language
- **Context**: precondition or trigger (`when_` MAY be omitted for happy path)

Group related tests in classes: `Test<Subject><Theme>`

## Test Structure

Every test MUST follow Given-When-Then (Arrange-Act-Assert) with one primary assertion theme.

## Acceptance Criteria Mapping

- Every AC MUST produce ≥ 1 test with a traceable title
- Complex ACs MUST split into scenarios varying the `when` clause
- Docstrings SHOULD reference criterion IDs (e.g., `"Validates AC-003"`)

## Test Categories and Tagging

| Category    | Budget    | Dependencies        |
|-------------|-----------|---------------------|
| Unit        | ≤ 50 ms   | None (mocked)       |
| Integration | ≤ 500 ms  | Real or stubbed I/O |
| E2E / UI    | ≤ 5 s     | Full system         |

Every test MUST be tagged with its category. CI SHOULD filter by tag.

## Test Organization

Structure tests **by domain → feature**. Key rules:
- No orphan test files in root — every test MUST live inside a domain folder
- Integration tests MUST live in a dedicated `integration/` subfolder
- Test files > 200 lines MUST be split by theme
- Test data MUST live under `tests/fixtures/` with semantic names
- Shared fixtures MUST be centralized, not duplicated per file
- No duplicate coverage across files

## Quality Rules

- **Independence**: no shared mutable state; runnable in any order; deterministic
- **Assertions**: assert specific values, not just truthiness; use messages for complex comparisons
- **Mocking**: mock external deps only; heavy mocking signals coupling issues
- **Coverage**: minimum 80%; critical paths 95%+
- **Scope**: test happy path, edge cases, errors, security — skip framework internals and trivial accessors
