# Code Standards

These standards apply to all code written or modified in any project.

## Function Design

- Functions MUST be ≤ 30 lines of logic (excluding docstrings, blank lines, and decorators)
- Each function MUST do exactly one thing — if you need "and" to describe it, split it
- Maximum 4 parameters per function; use an options/config object for more
- Prefer pure functions over side-effecting ones

## Naming

- Variables and functions: descriptive, intention-revealing names
- Boolean variables: prefix with `is_`, `has_`, `can_`, `should_`
- Constants: `UPPER_SNAKE_CASE`
- Classes: `PascalCase`
- Private members: prefix with `_`

## Documentation

- Every public function/method MUST have a docstring explaining:
  - What it does (one line)
  - Parameters and their types
  - Return value and type
  - Exceptions raised (if any)
- Comment the **Why**, never the What — code should be self-explanatory

## Structure

- One class per file (with small helper/exception classes as exceptions)
- Imports grouped: stdlib → third-party → local, separated by blank lines
- No circular imports — if you need one, your architecture is wrong
- Maximum file length: 300 lines (excluding tests)

## Error Handling

- Never catch generic exceptions silently (`except: pass` is forbidden)
- Use specific exception types
- Fail fast — validate inputs at boundaries, not deep in the stack
- Provide actionable error messages that include context

## Dependency Review

- Before adding any new dependency:
  1. Check if the stdlib or existing dependencies already solve the problem
  2. Verify the package is actively maintained (last release < 6 months)
  3. Check for known vulnerabilities
  4. Evaluate the dependency tree (avoid packages that pull in dozens of transitive deps)

## Code Smells to Reject

- God objects (classes doing too many things)
- Deeply nested conditionals (> 3 levels)
- Magic numbers/strings (extract to named constants)
- Copy-paste code (extract to shared function)
- Mutable global state
