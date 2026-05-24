# 01 - `create-spec` SKILL.md

## What to Build

A new skill at `.claude/skills/create-spec/SKILL.md` (and mirror in
`templates-claude/skills/create-spec/SKILL.md`) that orchestrates the full SDD
flow end-to-end. The same agent handles both stages without handoff or
intermediate artifact:

- **Stage 1**: Invoke `grill-with-docs` inline → present a `[Y/n]` HITL
  checkpoint → invoke `to-prd` → write `PRD.md`.
- **Stage 2**: Present a `[Y/n]` HITL checkpoint → invoke `to-issues` →
  write `issues/` + `INDEX.md` → suggest `/tdd-cycle NNN-01` without
  executing it.

## Acceptance Criteria

- [x] Invoking `/create-spec` runs `grill-with-docs` without requiring the
      user to invoke it separately.
- [x] A `[Y/n]` checkpoint appears after grilling; answering `n` aborts
      before `PRD.md` is written.
- [x] A `[Y/n]` checkpoint appears after `PRD.md` is written; answering `n`
      stops before issues are created.
- [x] `/tdd-cycle NNN-01` is suggested at the end but not executed.
- [x] Invoking `/grill-with-docs`, `/to-prd`, or `/to-issues` standalone
      produces the same result as before (no regression).
- [x] Both `.claude/skills/create-spec/SKILL.md` and
      `templates-claude/skills/create-spec/SKILL.md` are created.

## Implementation Notes

- Skill reuses the `[Y/n]` checkpoint pattern at both stage transitions rather
  than defining separate mechanisms — described once in Checkpoint A/B sections.
- Both `.claude/` and `templates-claude/` copies are identical; no templating
  logic needed since the skill is IDE-agnostic prose.

## Blocked By

None - can start immediately.

## Type

AFK

## User Stories Covered

- US1: single skill guides from grilling to issues
- US2: explicit HITL confirmation at each stage transition
- US3: same agent handles grilling and PRD (no handoff)
- US5: `/tdd-cycle` suggested but not executed
