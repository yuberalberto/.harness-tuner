<#
.SYNOPSIS
Hook invoked on Cascade pre_run_command event for the Bash tool.

Reads the pre_run_command payload from stdin, extracts the command string
from tool_info.command_line, and blocks dangerous git operations by writing
plain text to stdout and exiting with code 2.

.DESCRIPTION
Blocked patterns (exit 2 + plain text output):
  - git push --force / git push -f / git push --force-with-lease=*
  - git push <remote> main / git push <remote> master  (unless ALLOW_PROTECTED=1)
  - git reset --hard
  - git clean -f / -fd / -fdx
  - git checkout .  /  git restore .
  - git branch -D
  - git commit --no-verify / --no-gpg-sign / -c commit.gpgsign=false

All other commands pass through (exit 0, no output).

.NOTES
Cascade pre_run_command payload shape (relevant fields only):
{
  "tool_info": {
    "command_line": "<command string>"
  }
}

Block format: plain text to stdout + exit 2 (NOT JSON like Claude Code)
#>

param()

$ErrorActionPreference = 'Continue'

# ---------------------------------------------------------------------------
# Read pre_run_command payload from stdin
# ---------------------------------------------------------------------------
$rawInput = $null
try {
    $lines = [System.Collections.Generic.List[string]]::new()
    while ($true) {
        $line = [Console]::ReadLine()
        if ($null -eq $line) { break }
        $lines.Add($line)
    }
    $rawInput = $lines -join "`n"
}
catch {
    # stdin not available — allow (this hook shouldn't break normal usage)
    exit 0
}

if ([string]::IsNullOrWhiteSpace($rawInput)) {
    exit 0
}

# Parse JSON payload
$payload = $null
try {
    $payload = $rawInput | ConvertFrom-Json -ErrorAction Stop
}
catch {
    # Malformed JSON — allow to avoid blocking legitimate tool use
    exit 0
}

# Extract command string from tool_info.command_line (Cascade format)
$command = $null
try {
    $command = $payload.tool_info.command_line
}
catch { }

if ([string]::IsNullOrWhiteSpace($command)) {
    exit 0
}

# ---------------------------------------------------------------------------
# Helper: write a block message and exit 2 (plain text, NOT JSON)
# ---------------------------------------------------------------------------
function Block-Command {
    param([string]$Reason)

    Write-Output $Reason
    exit 2
}

# ---------------------------------------------------------------------------
# Pattern detection helpers
#
# Strategy: regex matching on the full command string.
# Each check targets a semantic danger independently so that argument ordering
# does not matter (e.g. "git push origin main --force" is caught by the
# force-push check AND the protected-branch check).
# ---------------------------------------------------------------------------

# Normalise whitespace for reliable matching
$cmd = $command -replace '\s+', ' '

# Only inspect git commands — fast-path everything else
if ($cmd -notmatch '^\s*git\s') {
    exit 0
}

# ---- 1. Force push (any variant) ------------------------------------------
# Covers: --force, -f, --force-with-lease, --force-with-lease=<refname>
if ($cmd -match '\bgit\s+push\b' -and $cmd -match '(--force\b|--force-with-lease\b|--force-with-lease=|-f(\s|$))') {
    Block-Command "BLOCKED: force-push detected in: '$command'. Force pushes can destroy remote history. Get explicit user approval before retrying."
}

# ---- 2. Push to protected branches (main / master) -------------------------
# Match main/master only as a whitespace-delimited token, NOT as a substring of
# a branch path like feature/main-refactor (which the simpler \b check would catch).
# Applies unless ALLOW_PROTECTED env var is set (any non-empty value).
if ($cmd -match '\bgit\s+push\b' -and $cmd -match '(^|\s)(main|master)(\s|$)') {
    if (-not $env:ALLOW_PROTECTED) {
        Block-Command "BLOCKED: push to protected branch detected in: '$command'. Set ALLOW_PROTECTED=1 to permit this operation."
    }
}

# ---- 3. Hard reset ----------------------------------------------------------
if ($cmd -match '\bgit\s+reset\b' -and $cmd -match '--hard\b') {
    Block-Command "BLOCKED: 'git reset --hard' detected in: '$command'. This discards all uncommitted changes. Get explicit user approval before retrying."
}

# ---- 4. Force-clean (working tree destruction) ------------------------------
# Covers: -f, -fd, -fdx, -fxd, and combinations like -f -d
if ($cmd -match '\bgit\s+clean\b' -and $cmd -match '\s-[fdxX]*f[fdxX]*\b') {
    Block-Command "BLOCKED: 'git clean -f' (or variant) detected in: '$command'. This permanently deletes untracked files. Get explicit user approval before retrying."
}

# ---- 5. Mass discard of working tree (checkout . / restore .) ---------------
if ($cmd -match '\bgit\s+(checkout|restore)\s+\.') {
    Block-Command "BLOCKED: mass working-tree discard detected in: '$command'. 'git checkout .' and 'git restore .' discard all unstaged changes. Get explicit user approval before retrying."
}

# ---- 6. Force branch deletion -----------------------------------------------
# Use -cmatch (case-sensitive) to distinguish -D (force-delete) from -d (safe delete).
# PowerShell -match is case-insensitive by default, which would cause false positives.
if ($cmd -match '\bgit\s+branch\b' -and $cmd -cmatch '\s-[a-zA-Z]*D[a-zA-Z]*(\s|$)') {
    Block-Command "BLOCKED: 'git branch -D' (force-delete) detected in: '$command'. Get explicit user approval before retrying."
}

# ---- 7. Bypass hooks / signing in commits ------------------------------------
if ($cmd -match '\bgit\s+commit\b' -and $cmd -match '(--no-verify\b|--no-gpg-sign\b|-c\s+commit\.gpgsign\s*=\s*false)') {
    Block-Command "BLOCKED: commit with bypassed hooks or signing detected in: '$command'. '--no-verify', '--no-gpg-sign', and '-c commit.gpgsign=false' are not permitted."
}

# ---------------------------------------------------------------------------
# All checks passed — allow the command
# ---------------------------------------------------------------------------
exit 0
