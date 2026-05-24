# 02 - Create templates-cascade/rules/

## What to Build

Create three rule files in `templates-cascade/rules/` — one per existing template rule — adding the YAML frontmatter required by Cascade (`trigger: always_on`, `description`). Content is identical to `templates/rules/` counterparts.

Files to create:
- `templates-cascade/rules/identity.md`
- `templates-cascade/rules/engram.md`
- `templates-cascade/rules/sdd-process.md`

Each file format:
```
---
trigger: always_on
description: <one-line summary>
---
<same content as templates/rules/<file>>
```

## Acceptance Criteria

- [x] All 3 rule files exist in `templates-cascade/rules/`
- [x] Each file has valid YAML frontmatter with `trigger: always_on` and `description`
- [x] Content body matches the corresponding `templates/rules/` file

## Blocked By

None — can start immediately.

## Type

AFK

## User Stories Covered

- US1: As a Windsurf/Cascade developer, I want to run `ht init -Agent cascade` to deploy rules into `.windsurf/`

## Implementation Notes

- Created `templates-cascade/rules/` directory
- Copied content from `templates/rules/` counterparts unchanged
- Added YAML frontmatter with `trigger: always_on` and one-line `description` for each file
- Descriptions: "Identity & Language rules for Cascade", "Engram memory protocol for Cascade", "SDD process workflow router for Cascade"
