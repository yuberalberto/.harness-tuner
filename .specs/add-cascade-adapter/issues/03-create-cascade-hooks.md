# 03 - Create templates-cascade/hooks/

## What to Build

Create two hook scripts adapted for the Cascade payload format, plus the `hooks.json` configuration file that wires them to the correct Cascade hook events.

Key payload differences from Claude Code:
- Path field: `tool_input.file_path` → `tool_info.file_path`
- Command field: `tool_input.command` → `tool_info.command_line`
- Block response: JSON `{"decision":"block","reason":"..."}` → plain text + exit 2

Files to create:
- `templates-cascade/hooks/format-post-edit.ps1` — adapted from `templates/hooks/format-post-edit.ps1`
- `templates-cascade/hooks/git-guardrails.ps1` — adapted from `templates/hooks/git-guardrails-pre-bash.ps1`
- `templates-cascade/hooks.json` — wires `post_write_code` → format script, `pre_run_command` → guardrails script

`hooks.json` structure:
```json
{
  "hooks": {
    "post_write_code": [
      { "powershell": "pwsh -File .windsurf/hooks/format-post-edit.ps1", "show_output": false }
    ],
    "pre_run_command": [
      { "powershell": "pwsh -File .windsurf/hooks/git-guardrails.ps1", "show_output": true }
    ]
  }
}
```

Session hooks (`engram-session-start`, `engram-session-end`) have no Cascade equivalent and are omitted.

## Acceptance Criteria

- [x] `format-post-edit.ps1` reads file path from `$payload.tool_info.file_path`
- [x] `git-guardrails.ps1` reads command from `$payload.tool_info.command_line`
- [x] `git-guardrails.ps1` blocks with plain text output + exit 2 (no JSON wrapper)
- [x] `hooks.json` maps both hook events correctly
- [x] Both scripts exit 0 silently on allowed actions (no output)

## Implementation Notes

- Adapted `format-post-edit.ps1` from Claude Code version by changing payload field from `tool_input.file_path` to `tool_info.file_path`
- Adapted `git-guardrails.ps1` from Claude Code version by changing payload field from `tool_input.command` to `tool_info.command_line` and replacing JSON block response with plain text + exit 2
- Created `hooks.json` with correct Cascade event mappings: `post_write_code` → format script, `pre_run_command` → guardrails script

## Blocked By

None — can start immediately.

## Type

AFK

## User Stories Covered

- US1: As a Windsurf/Cascade developer, I want hooks deployed to `.windsurf/hooks/`
