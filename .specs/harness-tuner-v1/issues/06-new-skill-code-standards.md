# 06 - New skill: code-standards

## What to Build

Create `templates/skills/code-standards/SKILL.md` — a skill encapsulating language-agnostic style and naming conventions. Invoked in two contexts:

1. **Step 4 (Refactor) of `tdd-cycle`** — after RED/GREEN, before commit. `tdd-cycle/SKILL.md` should be updated to reference `/code-standards` at this step.
2. **Standalone** — for cleaning up legacy code outside the TDD flow.

Content (markdown body):
- Naming: descriptive identifiers, no abbreviations unless universal.
- Comments: WHY-only, no WHAT comments, no historic references (no "added for issue #123", no "removed X" tombstones).
- Function size: single responsibility, no nested side effects.
- Error handling: validate at boundaries (user input, external APIs); trust internal code.
- Dead code: remove rather than comment out.

Skill body should walk the agent through evaluating the current diff against these standards and proposing a refactor.

## Acceptance Criteria

- [ ] `templates/skills/code-standards/SKILL.md` exists with valid frontmatter.
- [ ] `templates/skills/tdd-cycle/SKILL.md` references `/code-standards` in its Refactor step.
- [ ] Skill works standalone (does not assume tdd-cycle context).
- [ ] Invoking `/code-standards` after RED/GREEN produces an evaluation report + refactor suggestions for the current diff.

## Blocked By

- 04 (`templates/skills/` and migrated `tdd-cycle` must exist).

## Type

AFK

## User Stories Covered

- US 11 (code-standards at TDD refactor step)
