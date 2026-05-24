# 03 - `sdd-process.md` Routing Update

## What to Build

Update `.claude/rules/sdd-process.md` and `templates-claude/rules/sdd-process.md`
so the workflow router table directs new features to `/create-spec` instead of
the manual chain. Individual skills remain listed as standalone options so
developers can still invoke them independently.

## Acceptance Criteria

- [x] The "New feature, API change, data model change" row lists `/create-spec`
      as the primary skill.
- [x] `/grill-with-docs`, `/to-prd`, and `/to-issues` remain present in the
      table as standalone options (e.g. in a separate "Standalone / escape hatch"
      section or with a note).
- [x] Both `.claude/rules/sdd-process.md` and
      `templates-claude/rules/sdd-process.md` are updated identically.

## Implementation Notes

Added a "## Standalone / Escape Hatches" section below the router table listing
the three individual skills. The "Exploration / prototype" row was also updated
to reference `create-spec` instead of `grill-with-docs` for re-entry.

## Blocked By

- Issue 01 (`create-spec` SKILL.md must exist before being referenced)
- Issue 02 (NNN-NN naming is part of the complete feature)

## Type

AFK

## User Stories Covered

- US1: single skill guides the SDD workflow
- US7: individual skills remain usable standalone
