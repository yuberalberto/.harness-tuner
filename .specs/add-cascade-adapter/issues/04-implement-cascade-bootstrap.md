# 04 - Implement `ht init -Agent cascade`

## What to Build

Add `--agent` parameter to the CLI and implement `Invoke-BootstrapCascade` plus the two merge helpers needed for Cascade-specific config files.

New parameter:
```powershell
[string]$Agent = "claude-code"   # claude-code | cascade
```

New functions in `harness-tuner.ps1`:
- `Invoke-BootstrapCascade` — copies templates-cascade/rules/ → .windsurf/rules/, templates/skills/<n>/ → .windsurf/skills/<n>/, templates-cascade/hooks/ → .windsurf/hooks/, merges hooks.json and mcp_config.json, stamps .windsurf/.harness-tuner-version. Same isForeign/collision logic as Invoke-Bootstrap.
- `Merge-HooksJson` — additive merge for .windsurf/hooks.json (format: `{ hooks: { event: [...] } }`)
- `Merge-McpConfigJson` — additive merge for ~/.codeium/windsurf/mcp_config.json (format: `{ mcpServers: {} }`), adds engram entry only

Routing update in entry point:
```
ht init                  → Invoke-Bootstrap      (unchanged)
ht init -Agent cascade   → Invoke-BootstrapCascade
```

## Acceptance Criteria

- [x] `ht init -Agent cascade` creates `.windsurf/rules/` with 3 rule files
- [x] `.windsurf/skills/<name>/` directories created for all 12 skills with all support files
- [x] `.windsurf/hooks/` contains both adapted scripts
- [x] `.windsurf/hooks.json` created/merged with correct event mappings
- [x] `~/.codeium/windsurf/mcp_config.json` has engram entry after init
- [x] `.windsurf/.harness-tuner-version` stamped
- [x] Existing files trigger collision prompt (isForeign logic)
- [x] `ht init` (no --agent) still works exactly as before

## Blocked By

- Issue 02 (rules templates must exist)
- Issue 03 (hooks templates must exist)

## Type

AFK

## User Stories Covered

- US1: Deploy harness to .windsurf/ via `ht init -Agent cascade`
- US5: context7 absent from all generated output

## Implementation Notes

- Added `[string]$Agent = "claude-code"` parameter to harness-tuner.ps1
- Implemented `Merge-HooksJson` for additive merge of `{ hooks: { event: [...] } }` format
- Implemented `Merge-McpConfigJson` for additive merge of `{ mcpServers: {} }` format
- Implemented `Invoke-BootstrapCascade` which:
  - Copies rules from templates-cascade/rules/ to .windsurf/rules/
  - Copies skills from templates/skills/ to .windsurf/skills/
  - Copies hooks from templates-cascade/hooks/ to .windsurf/hooks/
  - Merges hooks.json and mcp_config.json
  - Stamps .windsurf/.harness-tuner-version
  - Uses same isForeign/collision logic as Invoke-Bootstrap
- Created templates-cascade/mcp_config.json with engram MCP server entry
- Fixed PowerShell HashSet.Contains issue by using `-notin` operator instead
- Fixed hooks directory creation by adding explicit New-Item before Copy-Item
- Updated routing logic: `ht init -Agent cascade` → Invoke-BootstrapCascade
