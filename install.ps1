<#
.SYNOPSIS
    One-time PC setup: create Claude Code skill junctions for all init-ai workflows.

.DESCRIPTION
    Creates directory junctions in ~/.claude/skills/ pointing to:
    - ~/init-ai/adapters/claude-code/skills/[workflow]/  (for workflow wrappers + init-ai meta)
    - ~/init-ai/methodology/skills/[skill]/              (for SDD skills: create-spec, run-tests, validate-spec)

    Run once per machine. Run again to add new skills after updating init-ai.

.EXAMPLE
    & "$env:USERPROFILE\init-ai\install.ps1"
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$INIT_AI_HOME  = $PSScriptRoot
$CLAUDE_SKILLS = Join-Path $env:USERPROFILE ".claude\skills"

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
# Workflow skill wrappers (adapters/claude-code/skills/)
# ---------------------------------------------------------------------------
$adapterSkills = Join-Path $INIT_AI_HOME "adapters\claude-code\skills"
Get-ChildItem -Directory $adapterSkills | ForEach-Object {
    New-Junction (Join-Path $CLAUDE_SKILLS $_.Name) $_.FullName
}

# ---------------------------------------------------------------------------
# SDD skills (methodology/skills/) — create-spec, run-tests, validate-spec
# ---------------------------------------------------------------------------
$methodologySkills = Join-Path $INIT_AI_HOME "methodology\skills"
Get-ChildItem -Directory $methodologySkills | ForEach-Object {
    $linkPath = Join-Path $CLAUDE_SKILLS $_.Name
    # Prefer adapter version if it exists; otherwise point to methodology directly
    if (-not (Test-Path $linkPath)) {
        New-Junction $linkPath $_.FullName
    } else {
        Write-Skip "Already linked: $($_.Name)"
    }
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
Write-Host "  You can now use these slash commands in Claude Code:"
Get-ChildItem -Directory $CLAUDE_SKILLS | ForEach-Object { Write-Host "    /$($_.Name)" }
Write-Host ""
