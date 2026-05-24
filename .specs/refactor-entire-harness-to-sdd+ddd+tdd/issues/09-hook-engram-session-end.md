# 09 - Hook: engram-session-end

## What to Build

Create `templates/hooks/engram-session-end.ps1` — a PowerShell script invoked by Claude Code on the Stop event (session end). The hook calls the engram MCP tool `mem_session_summary` to persist a summary of the session before context is lost.

The hook receives the Stop event payload via stdin and invokes the summary tool. If a summary is already in-flight (the agent called it manually), the hook should not double-invoke.

Include a Pester test in `tests/hooks/engram-session-end.Tests.ps1` that:
- Pipes a mock Stop event payload to the script.
- Asserts the script exits 0 and produces the expected mem_session_summary invocation.

## Acceptance Criteria

- [ ] `templates/hooks/engram-session-end.ps1` exists, parses Claude Code's Stop payload, invokes `mem_session_summary`.
- [ ] Idempotency: if the summary was already saved in the session, the hook skips with a no-op.
- [ ] Script handles engram MCP unavailable gracefully.
- [ ] Pester test passes against a mock payload.

## Blocked By

None — independent of all other slices.

## Type

AFK

## User Stories Covered

- US 3 (hooks for engram + formatters)
