---
name: run-tests
description: Run the project test suite with coverage reporting and summarize results
---

# Run Tests

Runs the test suite with coverage reporting and summarizes results.

## Trigger

Usage: `/run-tests [scope: all | unit | integration | e2e | specific-file]`

## Process

1. **Detect test framework**: Look for pytest.ini, jest.config, vitest.config, etc.
2. **Determine scope**: Based on user input, run all tests or a subset
3. **Execute tests with coverage**:
   - Python: `pytest --cov=src --cov-report=term-missing [scope]`
   - Node: `npx jest --coverage [scope]` or `npx vitest --coverage [scope]`
4. **Summarize results**:
   - Total tests: X
   - Passing: X (✅)
   - Failing: X (❌)
   - Skipped: X (⏭️)
   - Coverage: X%
5. **Highlight issues**: If any tests fail, show the failure details

## Coverage Thresholds

- Overall: ≥ 80% (warn if below)
- Critical paths: ≥ 95% (auth, payments, data mutation)

## Output Format

```
## Test Results

✅ 42/45 tests passing | ❌ 2 failing | ⏭️ 1 skipped
📊 Coverage: 83% (threshold: 80%)

### Failures
1. test_create_task_empty_title — AssertionError: expected ValidationError
2. test_api_auth_expired_token — 401 expected, got 200

### Coverage Gaps
- src/services/notification.py: lines 45-52 (error handling branch)
```

## Notes

- Always run tests from the project root
- Respect existing test configuration files
- Do not modify tests — only report results
