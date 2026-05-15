---
name: validate-spec
description: Validate that an SDD spec is complete and well-formed before implementation
---

# Validate Spec

Validates that a spec.md is complete and well-formed before starting implementation.

## Trigger

Usage: `/validate-spec [feature-name]`

## Process

1. **Locate spec**: Find `specs/[feature-name]/spec.md`
2. **Validate sections**:
   - [ ] **Problem** — present, one sentence, describes root problem (not a solution)
   - [ ] **What** — present, describes feature and purpose
   - [ ] **How** — present, mentions modules/files and approach
   - [ ] **Tasks** — at least one task defined
3. **Validate each task**:
   - [ ] Has a unique ID (TASK-XXX)
   - [ ] Has a Goal line
   - [ ] Has at least one testable acceptance criterion
   - [ ] Dependencies declared (even if "none")
4. **Coherence check**:
   - [ ] Problem and What are aligned (the feature solves the stated problem)
   - [ ] How references real modules/files in the codebase
   - [ ] Tasks cover the scope described in What (no orphan scope)

## Output Format

```
## Spec Validation: [feature-name]

### Status: ✅ Ready | ⚠️ Issues Found

### Checklist
- ✅ Problem: clear, one sentence
- ✅ What: describes feature
- ⚠️ How: references module that doesn't exist yet (confirm if intentional)
- ✅ Tasks: 4 defined, all have ACs

### Issues (must fix)
1. TASK-003 has no acceptance criteria

### Warnings (recommended)
1. How mentions `src/new_module/` — confirm this will be created
```

## Notes

- Run this BEFORE starting TDD implementation
- All issues must be resolved before proceeding
- Warnings are recommended but non-blocking
