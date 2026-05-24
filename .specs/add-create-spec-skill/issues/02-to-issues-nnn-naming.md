# 02 - `to-issues` NNN-NN Naming

## What to Build

Update `to-issues` SKILL.md in both `.claude/skills/to-issues/SKILL.md` and
`templates-claude/skills/to-issues/SKILL.md` so that all output uses
globally-unique IDs:

- Spec folders: `NNN-slug` (e.g. `003-add-create-spec-skill`)
- Issue files inside: `NNN-NN-slug.md` (e.g. `003-01-create-spec-skill.md`)
- `NNN` is auto-derived by counting existing `NNN-*` directories under
  `.specs/` and incrementing by one. When no numbered dirs exist, `NNN = 001`.
- `INDEX.md` references and status-table rows use `NNN-NN` IDs throughout.
- Legacy spec folders already present in `.specs/` without a `NNN-` prefix are
  not renamed or otherwise touched.

## Acceptance Criteria

- [x] Running `/to-issues` on a new feature creates a `NNN-slug/` folder with
      `NNN` correctly auto-derived from the count of numbered dirs in `.specs/`.
- [x] Issue files inside are named `NNN-NN-slug.md`.
- [x] `INDEX.md` uses `NNN-NN` IDs in the dependency graph and status table.
- [x] Running `/to-issues` when zero numbered dirs exist in `.specs/` produces
      `001-slug/` and `001-01-...md` files.
- [x] Existing legacy spec folders (`add-cascade-adapter`,
      `refactor-entire-harness-to-sdd+ddd+tdd`, `refactor-templates-naming`,
      `add-create-spec-skill`) are untouched.
- [x] Both `.claude/skills/to-issues/SKILL.md` and
      `templates-claude/skills/to-issues/SKILL.md` are updated identically.

## Blocked By

None - can start immediately.

## Type

AFK

## User Stories Covered

- US4: globally unique `NNN-NN` IDs for cross-spec references
- US6: legacy specs not renamed
