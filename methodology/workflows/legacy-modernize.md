---
description: Context-capture and rebuild workflow for modernizing legacy applications
---

# Legacy Modernize — Context-Capture and Rebuild

This workflow guides through modernizing a legacy application using context-capture and rebuild strategy.

## Trigger

Invoke this workflow when migrating or modernizing an existing legacy system. Usage: `/legacy-modernize [system or module to modernize]`

## Steps

### Step 1: Discovery and Context Capture

- Scan the codebase: languages, frameworks, structure, entry points
- Document business logic (the rules the system enforces)
- Map data models and their relationships
- Inventory APIs and interfaces (internal and external)
- Identify dependencies and their versions
- Document known issues, tech debt, and pain points
- **Output**: Comprehensive context document of the legacy system

### Step 2: Gap Analysis

Categorize everything into four buckets:
- **Preserve**: Features that must work exactly the same
- **Improve**: Features to enhance during migration
- **Remove**: Features no longer needed
- **Add**: New capabilities required

Also identify:
- Security requirements that have changed since original build
- Performance requirements (current vs. expected)
- Compliance/regulatory changes
- **Output**: Gap analysis document

### Step 3: Generate Modern Spec

- Write requirements derived from legacy behavior + new needs
- Design using modern patterns (clean architecture, API-first)
- Plan data migration as a first-class task
- Break into tasks ordered for incremental delivery
- **Output**: Complete SDD spec for the modern system

### Step 4: Build with TDD

- Implement tasks using the TDD cycle workflow
- Use legacy behavior as the test oracle where applicable:
  ```
  test_modern_output_matches_legacy(input):
      legacy_result = legacy_system.process(input)
      modern_result = modern_system.process(input)
      assert modern_result == legacy_result
  ```
- **Output**: Working modern system with test coverage

### Step 5: Parallel Validation

- Run both systems in parallel with the same inputs
- Compare outputs for discrepancies
- Document any intentional behavioral differences
- Fix any unintentional discrepancies
- **Output**: Validated modern system matching legacy behavior

### Step 6: Migration Execution

- Plan cutover strategy (big bang vs. incremental)
- Migrate data
- Switch traffic
- Monitor for issues
- Decommission legacy system
- **Output**: Completed migration

## Output

At completion:
- Context document of legacy system
- Gap analysis
- Complete SDD spec for modern system
- Modern implementation with tests
- Migration execution plan/results
- Legacy system decommissioned
