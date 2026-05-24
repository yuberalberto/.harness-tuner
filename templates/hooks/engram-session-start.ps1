<#
.SYNOPSIS
    SessionStart hook — loads prior session memory from Engram.

.DESCRIPTION
    Claude Code invokes this script on SessionStart events to initialize engram
    memory context. The hook reads the SessionStart event payload from stdin,
    detects the current project, and instructs Claude Code to call mem_context
    to load prior memory for the session.

    If engram MCP server is unavailable, the hook gracefully degrades (warns
    but does not crash) and exits 0.

.NOTES
    Claude Code SessionStart payload shape (relevant fields):
    {
      "session_id": "<uuid>",
      "cwd": "<current-working-directory>",
      "user": { "email": "..." }
    }

    This script outputs instructional text to stdout. Claude Code treats this
    as additionalContext and will invoke mem_context to load prior session
    memory for the project in the current working directory.
#>

#Requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# ---------------------------------------------------------------------------
# 1. Read and parse stdin payload
# ---------------------------------------------------------------------------
$rawPayload = @($input) | Out-String
$payload = @{}

if (-not [string]::IsNullOrWhiteSpace($rawPayload)) {
    try {
        $payload = $rawPayload | ConvertFrom-Json -ErrorAction SilentlyContinue
    } catch {
        # Payload parse error — continue without it
    }
}

# ---------------------------------------------------------------------------
# 2. Extract session context from payload
# ---------------------------------------------------------------------------
$cwd = $payload.cwd
$sessionId = $payload.session_id

# If no cwd in payload, use current directory
if ([string]::IsNullOrWhiteSpace($cwd)) {
    $cwd = Get-Location | Select-Object -ExpandProperty Path
}

# ---------------------------------------------------------------------------
# 3. Detect project name from the working directory
# ---------------------------------------------------------------------------
# Simple heuristic: use the directory name as the project identifier.
# (A more sophisticated version would check for .git, package.json, etc.)
$projectName = if ($cwd) {
    Split-Path -Leaf $cwd
} else {
    'unnamed-project'
}

# ---------------------------------------------------------------------------
# 4. Output instruction to Claude Code
# ---------------------------------------------------------------------------
# The hook outputs text that Claude Code treats as additionalContext.
# This signals the agent to call mem_context to load prior session memory.

Write-Output @"
## Engram Memory Protocol — Session Started

A new Claude Code session has started. Loading prior session context from Engram persistent memory...

**Instruction to Claude**: If you have access to the engram MCP tools, call mem_context now to load prior session memory and context for this project.

### Memory Context
The current working directory is: $cwd
Session ID: $sessionId
Project: $projectName

This memory context will help you understand what was accomplished in prior sessions and any decisions or patterns that were established.
"@

exit 0
