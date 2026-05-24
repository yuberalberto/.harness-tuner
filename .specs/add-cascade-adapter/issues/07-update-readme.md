# 07 - Update README for Cascade Support

## What to Build

Update `README.md` to document the Cascade adapter. Add a "Supported agents" section that covers both Claude Code and Windsurf/Cascade, including the new `--agent` parameter usage and what gets deployed to `.windsurf/`.

Changes:
- Update the "Supported agents" section (currently says "Claude Code only")
- Add `ht init -Agent cascade` and `ht update -Agent cascade` to Quick Start examples
- Document what each layer deploys to in Cascade (rules → .windsurf/rules/, skills → .windsurf/skills/, hooks → .windsurf/hooks.json, MCP → global mcp_config.json)
- Note that session hooks are not available in Cascade

## Acceptance Criteria

- [x] README no longer says "Claude Code only"
- [x] `ht init -Agent cascade` documented with example
- [x] `ht update -Agent cascade` documented
- [x] Layer deployment destinations for Cascade documented
- [x] Note about session hooks (engram-session-start/end) not available in Cascade
- [x] `--force` flag for `ht update` documented

## Implementation Notes

- README was manually updated with Cascade documentation
- Added "For Cascade (Windsurf)" section to Quick Start with `ht init -Agent cascade` example
- Added "For Cascade (Windsurf)" section to Updating with `ht update -Agent cascade` and `--force` examples
- Updated "Supported agents" section to document both Claude Code and Cascade
- Documented layer mappings for Cascade (rules → .windsurf/rules/, skills → .windsurf/skills/, hooks → .windsurf/hooks.json, MCP → global mcp_config.json)
- Added note about session hooks not being available in Cascade due to platform limitations

## Blocked By

- Issue 04 (bootstrap must be implemented before documenting it)
- Issue 05 (update must be implemented before documenting it)

## Type

AFK

## User Stories Covered

- US1, US2: Documents the cascade init and update commands
