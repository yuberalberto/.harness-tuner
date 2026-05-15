<#
.SYNOPSIS
    Bootstrap or update a project with the init-ai methodology.

.DESCRIPTION
    Without flags   — Bootstraps a new project. Aborts if .windsurf/ already exists.
    --update        — Interactive diff: shows changes per file, prompts accept/reject/skip.

.EXAMPLE
    # From inside your project directory:
    & "$env:USERPROFILE\init-ai\init-ai.ps1"
    & "$env:USERPROFILE\init-ai\init-ai.ps1" --update
#>

param(
    [switch]$update
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$INIT_AI_HOME = $PSScriptRoot
$METHODOLOGY  = Join-Path $INIT_AI_HOME "methodology"
$TARGET       = Get-Location | Select-Object -ExpandProperty Path

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Header([string]$msg) {
    Write-Host ""
    Write-Host "=== $msg ===" -ForegroundColor Cyan
}

function Write-Ok([string]$msg)   { Write-Host "  [OK] $msg"   -ForegroundColor Green }
function Write-Skip([string]$msg) { Write-Host "  [--] $msg"   -ForegroundColor DarkGray }
function Write-Warn([string]$msg) { Write-Host "  [!!] $msg"   -ForegroundColor Yellow }
function Write-Err([string]$msg)  { Write-Host "  [XX] $msg"   -ForegroundColor Red }

function Prompt-YesNo([string]$question) {
    $response = Read-Host "$question [y/n]"
    return $response -match "^[yY]"
}

function Show-Diff([string]$srcFile, [string]$dstFile) {
    if (-not (Test-Path $dstFile)) {
        Write-Host "  [NEW FILE] $(Split-Path $srcFile -Leaf)" -ForegroundColor Yellow
        return
    }
    $srcLines = Get-Content $srcFile
    $dstLines = Get-Content $dstFile

    $srcHash = ($srcLines | Out-String).GetHashCode()
    $dstHash = ($dstLines | Out-String).GetHashCode()

    if ($srcHash -eq $dstHash) {
        Write-Host "  [IDENTICAL]" -ForegroundColor DarkGray
        return
    }

    # Try git diff if available; fallback to simple line count diff
    $gitAvailable = Get-Command git -ErrorAction SilentlyContinue
    if ($gitAvailable) {
        git diff --no-index --color=always $dstFile $srcFile 2>&1 | Select-Object -First 60 | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Host "  Source: $($srcLines.Count) lines  |  Current: $($dstLines.Count) lines" -ForegroundColor DarkYellow
        Write-Host "  (Install git for a proper diff view)"
    }
}

function Copy-MethodologyTree([string]$srcDir, [string]$dstDir) {
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    Get-ChildItem -Recurse -File $srcDir | ForEach-Object {
        $rel = $_.FullName.Substring($srcDir.Length).TrimStart('\', '/')
        $dst = Join-Path $dstDir $rel
        New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
        Copy-Item -Force $_.FullName $dst
        Write-Ok "Copied $rel"
    }
}

# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------

function Invoke-Bootstrap {
    $windsurfDir = Join-Path $TARGET ".windsurf"
    if (Test-Path $windsurfDir) {
        Write-Err "Project already initialized (.windsurf/ exists)."
        Write-Host "  Use --update to pull in methodology changes." -ForegroundColor Yellow
        exit 1
    }

    Write-Header "Bootstrapping $TARGET"

    # 1. Copy methodology
    Write-Host ""
    Write-Host "Copying methodology files..." -ForegroundColor Cyan
    Copy-MethodologyTree (Join-Path $METHODOLOGY "rules")     (Join-Path $windsurfDir "rules")
    Copy-MethodologyTree (Join-Path $METHODOLOGY "workflows") (Join-Path $windsurfDir "workflows")
    Copy-MethodologyTree (Join-Path $METHODOLOGY "skills")    (Join-Path $windsurfDir "skills")

    # 2. Create specs/ directory
    $specsDir = Join-Path $TARGET "specs"
    New-Item -ItemType Directory -Force -Path $specsDir | Out-Null
    Write-Ok "Created specs/"

    # 3. Add scratch/ to .gitignore
    $gitignorePath = Join-Path $TARGET ".gitignore"
    $scratchEntry  = "scratch/"
    if (Test-Path $gitignorePath) {
        $existing = Get-Content $gitignorePath -Raw
        if ($existing -notmatch [regex]::Escape($scratchEntry)) {
            Add-Content $gitignorePath "`n# AI exploration area`n$scratchEntry"
            Write-Ok "Added scratch/ to .gitignore"
        } else {
            Write-Skip "scratch/ already in .gitignore"
        }
    } else {
        Set-Content $gitignorePath "# AI exploration area`n$scratchEntry`n"
        Write-Ok "Created .gitignore with scratch/"
    }

    # 4. Generate CLAUDE.md
    $claudeDir  = Join-Path $TARGET ".claude"
    $claudeMd   = Join-Path $claudeDir "CLAUDE.md"
    New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

    $projectName  = Read-Host "Project name (for CLAUDE.md)"
    $userLanguage = Read-Host "User chat language (e.g. Spanish, English)"

    $template = Get-Content (Join-Path $INIT_AI_HOME "adapters\claude-code\CLAUDE.md.template") -Raw
    $compiled = $template -replace "{{PROJECT_NAME}}", $projectName
    $compiled = $compiled -replace "{{USER_LANGUAGE}}", $userLanguage

    Set-Content -Path $claudeMd -Value $compiled -Encoding UTF8
    Write-Ok "Generated .claude/CLAUDE.md"

    Write-Header "Bootstrap complete"
    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor White
    Write-Host "  1. Edit .claude/CLAUDE.md — fill in the PROJECT-SPECIFIC section at the bottom"
    Write-Host "  2. Run install.ps1 (once per PC) to set up Claude Code skill shortcuts"
    Write-Host "  3. Commit the scaffolding: git add .windsurf specs .gitignore .claude && git commit -m 'chore: init ai methodology'"
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Update
# ---------------------------------------------------------------------------

function Invoke-Update {
    $windsurfDir = Join-Path $TARGET ".windsurf"
    if (-not (Test-Path $windsurfDir)) {
        Write-Err "Project not yet initialized (.windsurf/ not found). Run without --update first."
        exit 1
    }

    Write-Header "Updating $TARGET"

    $accepted = 0
    $skipped  = 0
    $rejected = 0

    $methodologyFiles = Get-ChildItem -Recurse -File $METHODOLOGY
    foreach ($srcFile in $methodologyFiles) {
        $rel     = $srcFile.FullName.Substring($METHODOLOGY.Length).TrimStart('\', '/')
        $dstFile = Join-Path $windsurfDir $rel

        Write-Host ""
        Write-Host "--- $rel ---" -ForegroundColor White

        if (Test-Path $dstFile) {
            $srcHash = (Get-FileHash $srcFile.FullName -Algorithm MD5).Hash
            $dstHash = (Get-FileHash $dstFile -Algorithm MD5).Hash
            if ($srcHash -eq $dstHash) {
                Write-Skip "Identical — skipping"
                continue
            }
            Show-Diff $srcFile.FullName $dstFile
        } else {
            Write-Host "  [NEW FILE] Will be added." -ForegroundColor Yellow
        }

        $choice = Read-Host "  Accept (a), Reject (r), Skip (s)? [a/r/s]"
        switch ($choice.ToLower()) {
            "a" {
                New-Item -ItemType Directory -Force -Path (Split-Path $dstFile) | Out-Null
                Copy-Item -Force $srcFile.FullName $dstFile
                Write-Ok "Accepted"
                $accepted++
            }
            "r" {
                Write-Host "  Rejected." -ForegroundColor Red
                $rejected++
            }
            default {
                Write-Skip "Skipped"
                $skipped++
            }
        }
    }

    Write-Header "Update complete"
    Write-Host "  Accepted: $accepted  |  Rejected: $rejected  |  Skipped: $skipped"
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if ($update) {
    Invoke-Update
} else {
    Invoke-Bootstrap
}
