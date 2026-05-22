<#
.SYNOPSIS
    One-time PC setup: create Claude Code skill junctions for all init-ai skills.

.DESCRIPTION
    Creates directory junctions in ~/.claude/skills/ pointing to:
    - ~/init-ai/claude-code/skills/[skill]/   (the init-ai skills in Claude Code native format)

    Run once per machine. Use --force to reinstall.

.EXAMPLE
    & "$env:USERPROFILE\init-ai\install.ps1"
    & "$env:USERPROFILE\init-ai\install.ps1" --force
#>

param(
    [switch]$force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$INIT_AI_HOME  = $PSScriptRoot
$CLAUDE_SKILLS = Join-Path $env:USERPROFILE ".claude\skills"
$VERSION       = (Get-Content (Join-Path $INIT_AI_HOME "VERSION") -Raw).Trim()

# ---------------------------------------------------------------------------
# Already-installed check
# ---------------------------------------------------------------------------

function Test-AlreadyInstalled {
    $hasJunctions = (Test-Path $CLAUDE_SKILLS) -and
        ((Get-ChildItem -Directory $CLAUDE_SKILLS -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)

    $hasAlias = $false
    $profilePath = $PROFILE.CurrentUserAllHosts
    if (Test-Path $profilePath) {
        $hasAlias = (Get-Content $profilePath -Raw) -match 'function init-ai'
    }

    return ($hasJunctions -and $hasAlias)
}

if (-not $force -and (Test-AlreadyInstalled)) {
    Write-Host ""
    Write-Host "init-ai is already installed (v$VERSION)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  To update a project:  init-ai --update" -ForegroundColor White
    Write-Host "  To reinstall:         & `"$env:USERPROFILE\init-ai\install.ps1`" --force" -ForegroundColor White
    Write-Host ""
    exit 0
}

function Write-Ok([string]$msg)   { Write-Host "  [OK] $msg"   -ForegroundColor Green }
function Write-Skip([string]$msg) { Write-Host "  [--] $msg"   -ForegroundColor DarkGray }
function Write-Warn([string]$msg) { Write-Host "  [!!] $msg"   -ForegroundColor Yellow }

function New-Junction([string]$linkPath, [string]$targetPath) {
    if (-not (Test-Path $targetPath)) {
        Write-Warn "Target not found, skipping: $targetPath"
        return
    }
    if (Test-Path $linkPath) {
        $item = Get-Item $linkPath -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Write-Skip "Junction already exists: $(Split-Path $linkPath -Leaf)"
        } else {
            Write-Warn "Path exists but is not a junction: $linkPath"
        }
        return
    }
    New-Item -ItemType Junction -Path $linkPath -Target $targetPath | Out-Null
    Write-Ok "Created junction: $(Split-Path $linkPath -Leaf)"
}

# ---------------------------------------------------------------------------
# Ensure ~/.claude/skills/ exists
# ---------------------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $CLAUDE_SKILLS | Out-Null
Write-Host ""
Write-Host "=== Installing init-ai Claude Code skills ===" -ForegroundColor Cyan
Write-Host "  Target: $CLAUDE_SKILLS"
Write-Host ""

# ---------------------------------------------------------------------------
# init-ai skills (claude-code/skills/)
# ---------------------------------------------------------------------------
$claudeCodeSkills = Join-Path $INIT_AI_HOME "claude-code\skills"
Get-ChildItem -Directory $claudeCodeSkills | ForEach-Object {
    New-Junction (Join-Path $CLAUDE_SKILLS $_.Name) $_.FullName
}

# ---------------------------------------------------------------------------
# Shell alias — add `init-ai` function to PowerShell profile
# ---------------------------------------------------------------------------

$profilePath = $PROFILE.CurrentUserAllHosts
$aliasBlock  = @'

# init-ai — bootstrap & update AI methodology
function init-ai { & "$env:USERPROFILE\init-ai\init-ai.ps1" @args }
'@

$aliasInstalled = $false
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw
    if ($profileContent -match 'function init-ai') {
        Write-Skip "Shell alias 'init-ai' already in profile"
        $aliasInstalled = $true
    }
}

if (-not $aliasInstalled) {
    if (-not (Test-Path (Split-Path $profilePath))) {
        New-Item -ItemType Directory -Force -Path (Split-Path $profilePath) | Out-Null
    }
    Add-Content -Path $profilePath -Value $aliasBlock -Encoding UTF8
    Write-Ok "Added 'init-ai' alias to $profilePath"
    Write-Host "    Reload with: . `$PROFILE" -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Installation complete ===" -ForegroundColor Green
Write-Host ""
$count = (Get-ChildItem -Directory $CLAUDE_SKILLS | Measure-Object).Count
Write-Host "  Skills installed: $count"
Write-Host "  Location: $CLAUDE_SKILLS"
Write-Host ""
Write-Host "  Usage:" -ForegroundColor White
Write-Host "    init-ai                  # bootstrap a project"
Write-Host "    init-ai --update         # update an existing project"
Write-Host ""
Write-Host "  Slash commands available in Claude Code:"
Get-ChildItem -Directory $CLAUDE_SKILLS | ForEach-Object { Write-Host "    /$($_.Name)" }
Write-Host ""
