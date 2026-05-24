# 08 - Hook: engram-session-start

## What to Build

Create `templates/hooks/engram-session-start.ps1` — a PowerShell script invoked by Claude Code on the SessionStart event. The hook calls the engram MCP tool `mem_context` to load prior session memory for the current project.

The hook receives Claude Code's event payload via stdin (JSON), parses it if needed, and emits any output/instructions back to Claude Code in the format Claude Code expects.

Include a Pester test in `tests/hooks/engram-session-start.Tests.ps1` that:
- Pipes a mock SessionStart event payload to the script.
- Asserts the script exits 0 and produces the expected mem_context invocation marker (or whatever output contract Claude Code expects from a SessionStart hook).

## Acceptance Criteria

- [ ] `templates/hooks/engram-session-start.ps1` exists, parses Claude Code's SessionStart payload, invokes `mem_context`.
- [ ] Script handles the case where the engram MCP server is not available (graceful degradation, no crash).
- [ ] Pester test passes against a mock payload.
- [ ] After bootstrap into a project, the hook fires on SessionStart and prior memory loads (verified manually in issue 18).

## Blocked By

None — independent of all other slices.

## Type

AFK

## User Stories Covered

- US 3 (hooks for engram + formatters)
