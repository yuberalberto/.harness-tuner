# 01 - Remove context7 and Apply Verb-First Naming

## What to Build

Remove all references to the `context7` MCP server from the project (it was never used and was added by mistake). Also commit the already-applied change to `to-prd/SKILL.md` that introduces the verb-first spec folder naming convention.

Files to clean:
- `templates/settings.json` — remove context7 block from mcpServers
- `README.md` — remove context7 line from MCP section
- `CHANGELOG.md` — remove context7 from v1.0.0 MCP declaration entry
- `templates/skills/to-prd/SKILL.md` — already edited (commit only)

## Acceptance Criteria

- [x] `context7` does not appear in `templates/settings.json`
- [x] `context7` does not appear in `README.md`
- [x] `context7` does not appear in `CHANGELOG.md`
- [x] `to-prd/SKILL.md` verb-first naming convention is committed

## Implementation Notes

- Simple cleanup task adapted to TDD workflow as atomic verifiable changes
- All context7 references successfully removed from 3 files
- Verb-first naming convention was already applied to to-prd/SKILL.md but not committed; now committed with semantic commit message

## Blocked By

None — can start immediately.

## Type

AFK

## User Stories Covered

- US5: As any developer, I want context7 absent from all generated harness configs
