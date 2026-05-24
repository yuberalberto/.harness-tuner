# 04 - templates/skills/ (migrate 9 existing + .specs/ rename + inline testing)

## What to Build

Create `templates/skills/` populated with the 9 existing skills migrated from the legacy `claude-code/skills/` location, with these in-place edits:

1. **Rename across skills**: change every `.scratch/<feature>/` reference to `.specs/<feature>/` in:
   - `templates/skills/to-prd/SKILL.md`
   - `templates/skills/to-issues/SKILL.md`
   - `templates/skills/tdd-cycle/SKILL.md`

2. **Inline testing content** into `templates/skills/tdd-cycle/SKILL.md`: copy the contents of the legacy `testing.md` rule (test naming convention `<subject>__should_<behavior>__when_<context>`, test class naming `Test<Subject><Theme>`) into the relevant TDD step of the skill body. The standalone rule file is then deleted (per issue 03).

3. **No content changes** to the remaining 6 skills (`grill-with-docs`, `zoom-out`, `improve-codebase-architecture`, `audit`, `review`, `git-flow`) beyond the file move.

## Acceptance Criteria

- [ ] `templates/skills/` contains exactly 9 directories (the existing skills).
- [ ] `grep -r '\.scratch/' templates/skills/` returns no matches.
- [ ] `templates/skills/tdd-cycle/SKILL.md` includes the test naming convention inline.
- [ ] `templates/skills/grill-with-docs/SKILL.md` retains its DDD/ADR behavior (it remains the SDD entry point).
- [ ] After `ht init`, the 9 skill dirs appear in `.claude/skills/` of the target project.

## Blocked By

None — independent of all other slices.

## Type

AFK

## User Stories Covered

- US 5 (SDD pipeline skills)
