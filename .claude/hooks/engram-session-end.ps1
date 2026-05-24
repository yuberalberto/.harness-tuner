<#
.SYNOPSIS
Hook invoked on Claude Code Stop event (session end).

Reads the Stop event payload from stdin and signals Claude Code to call
mem_session_summary to persist a session summary before context is lost.

.DESCRIPTION
This hook integrates with the Engram MCP server to ensure session summaries
are saved at the end of each Claude Code session. If a summary was already
saved during the session (idempotency), the hook becomes a no-op.

The hook outputs a directive in hookSpecificOutput to instruct Claude Code
to invoke the mem_session_summary MCP tool.

Handles graceful degradation if the engram MCP server is not available.
#>

$ErrorActionPreference = 'SilentlyContinue'

# Read Stop event payload from stdin
$payload = @{}
$input | ForEach-Object {
  if ($_) {
    try {
      $payload = $_ | ConvertFrom-Json -ErrorAction SilentlyContinue
    }
    catch {
      $payload = @{}
    }
  }
}

# Check for idempotency: if session already saved mem_session_summary, skip.
# This prevents double-calling the MCP tool in the same session.
$shouldSaveSummary = $true
if ($payload -is [object] -and $payload.sessionContext) {
  if ($payload.sessionContext.mem_session_summary_called -eq $true) {
    $shouldSaveSummary = $false
  }
}

# If summary was already saved, exit silently (no-op).
if (-not $shouldSaveSummary) {
  exit 0
}

# Output directive to Claude Code to invoke mem_session_summary.
# Claude Code interprets hookSpecificOutput to trigger MCP tool calls.
$output = @{
  hookSpecificOutput = @{
    additionalContext = 'Session end detected. Invoke mem_session_summary to persist session summary.'
    requestMcpCall    = @{
      tool  = 'engram'
      call  = 'mem_session_summary'
      notes = 'Captures session goal, discoveries, accomplished work, and relevant files.'
    }
  }
}

$output | ConvertTo-Json -Depth 10
exit 0
