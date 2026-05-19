<#
.SYNOPSIS
    Bootstrap or update a project with the init-ai methodology.

.DESCRIPTION
    Without flags   — Bootstraps a new project. Aborts if .windsurf/ already exists.
    --update        — Interactive diff: shows changes per file, prompts accept/reject/skip.

.PARAMETER ProjectName
    (Optional) Project name written into CLAUDE.md. Skips the interactive prompt.

.PARAMETER Language
    (Optional) User chat language written into CLAUDE.md (e.g. Spanish). Skips the interactive prompt.

.EXAMPLE
    # From inside your project directory:
    & "$env:USERPROFILE\init-ai\init-ai.ps1"
    & "$env:USERPROFILE\init-ai\init-ai.ps1" --update
    & "$env:USERPROFILE\init-ai\init-ai.ps1" -ProjectName my-app -Language Spanish
#>

param(
    [switch]$update,
    [switch]$version,
    [switch]$changelog,
    [switch]$help,
    [string]$ProjectName = "",
    [string]$Language    = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Normalize --flag style (double-dash) to PowerShell switches
if ($args -contains '--update')    { $update    = $true }
if ($args -contains '--version')   { $version   = $true }
if ($args -contains '--changelog') { $changelog = $true }
if ($args -contains '--help')      { $help      = $true }

$INIT_AI_HOME = $PSScriptRoot
$METHODOLOGY  = Join-Path $INIT_AI_HOME "methodology"
$TARGET       = Get-Location | Select-Object -ExpandProperty Path
$FRAMEWORK_VERSION = (Get-Content (Join-Path $INIT_AI_HOME "VERSION") -Raw).Trim()
$VERSION_STAMP     = Join-Path $TARGET ".windsurf" ".init-ai-version"

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

function Get-TemplateHash {
    $templatePath = Join-Path $INIT_AI_HOME "adapters\claude-code\CLAUDE.md.template"
    return (Get-FileHash $templatePath -Algorithm MD5).Hash.ToLower().Substring(0, 8)
}

function Get-ClaudeMdMarkerHash([string]$claudeMdPath) {
    if (-not (Test-Path $claudeMdPath)) { return $null }
    $content = Get-Content $claudeMdPath -Raw
    if ($content -match '<!-- init-ai:([a-f0-9]+) -->') { return $Matches[1] }
    return $null
}

function Get-ProjectContextSection([string]$templateHash) {
    return @"

## Project Context
<!-- init-ai:$templateHash -->

<!-- Add project-specific context here:
     - Runtime constraints (e.g., target OS, Python version, browser support)
     - Compatibility requirements
     - Build/run commands
     - Key architectural decisions
     - Team conventions not covered by the standards above
-->
"@
}
function Write-Err([string]$msg)  { Write-Host "  [XX] $msg"   -ForegroundColor Red }

function Prompt-YesNo([string]$question) {
    $response = Read-Host "$question [y/n]"
    return $response -match "^[yY]"
}

function Get-ProjectVersion {
    if (Test-Path $VERSION_STAMP) {
        return (Get-Content $VERSION_STAMP -Raw).Trim()
    }
    return $null
}

function Write-VersionStamp {
    New-Item -ItemType Directory -Force -Path (Split-Path $VERSION_STAMP) | Out-Null
    Set-Content -Path $VERSION_STAMP -Value $FRAMEWORK_VERSION -Encoding UTF8
}

function Show-ChangelogSince([string]$fromVersion) {
    $changelogPath = Join-Path $INIT_AI_HOME "CHANGELOG.md"
    if (-not (Test-Path $changelogPath)) { return }

    $lines    = Get-Content $changelogPath
    $printing = $false
    $output   = @()

    foreach ($line in $lines) {
        if ($line -match '^\#\# \[(.+?)\]') {
            $sectionVer = $Matches[1]
            if ($fromVersion -and $sectionVer -eq $fromVersion) {
                break
            }
            $printing = $true
        }
        if ($printing) {
            $output += $line
        }
    }

    if ($output.Count -gt 0) {
        Write-Host ""
        Write-Host "Changes since v${fromVersion}:" -ForegroundColor Cyan
        Write-Host ""
        foreach ($l in $output) {
            Write-Host "  $l" -ForegroundColor DarkYellow
        }
        Write-Host ""
    }
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

    $defaultName  = Split-Path $TARGET -Leaf
    $projectName  = if ($ProjectName) { $ProjectName } else {
        $input = Read-Host "Project name [$defaultName]"
        if ($input) { $input } else { $defaultName }
    }
    $userLanguage = if ($Language)     { $Language }     else { Read-Host "User chat language (e.g. Spanish, English)" }

    $templateHash = Get-TemplateHash
    $template = Get-Content (Join-Path $INIT_AI_HOME "adapters\claude-code\CLAUDE.md.template") -Raw
    $compiled = $template -replace "{{PROJECT_NAME}}", $projectName
    $compiled = $compiled -replace "{{USER_LANGUAGE}}", $userLanguage
    $compiled = $compiled -replace "{{TEMPLATE_HASH}}", $templateHash

    $markerHash = Get-ClaudeMdMarkerHash $claudeMd
    if (-not (Test-Path $claudeMd)) {
        Set-Content -Path $claudeMd -Value $compiled -Encoding UTF8
        Write-Ok "Generated .claude/CLAUDE.md"
    } elseif ($markerHash) {
        Write-Skip ".claude/CLAUDE.md already managed by init-ai"
    } else {
        Add-Content -Path $claudeMd -Value (Get-ProjectContextSection $templateHash) -Encoding UTF8
        Write-Ok "Appended Project Context to .claude/CLAUDE.md"
    }

    # 5. Stamp version
    Write-VersionStamp
    Write-Ok "Stamped version $FRAMEWORK_VERSION"

    Write-Header "Bootstrap complete (v$FRAMEWORK_VERSION)"
    Write-Host ""
    Write-Host "  1. Fill in .claude/CLAUDE.md (PROJECT-SPECIFIC section at the bottom)" -ForegroundColor White
    Write-Host "  2. git add .windsurf specs .gitignore .claude && git commit -m 'chore: init ai'" -ForegroundColor White
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

    $projectVersion = Get-ProjectVersion
    if ($projectVersion) {
        Write-Host "  Project version: v$projectVersion" -ForegroundColor White
    } else {
        Write-Host "  Project version: unknown (installed before v0.3.0 — no version stamp found)" -ForegroundColor Yellow
    }
    Write-Host "  Latest version:  v$FRAMEWORK_VERSION" -ForegroundColor White

    if ($projectVersion -eq $FRAMEWORK_VERSION) {
        Write-Host ""
        Write-Host "  Already up to date." -ForegroundColor Green
        Write-Host ""
        return
    }

    Show-ChangelogSince $projectVersion

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

    # Check CLAUDE.md template hash
    $claudeMd    = Join-Path $TARGET ".claude\CLAUDE.md"
    $templateHash = Get-TemplateHash
    $markerHash   = Get-ClaudeMdMarkerHash $claudeMd

    Write-Host ""
    Write-Host "--- .claude/CLAUDE.md ---" -ForegroundColor White
    if (-not (Test-Path $claudeMd)) {
        Write-Skip "No .claude/CLAUDE.md found — skipping"
    } elseif (-not $markerHash) {
        Add-Content -Path $claudeMd -Value (Get-ProjectContextSection $templateHash) -Encoding UTF8
        Write-Ok "Appended Project Context section"
    } elseif ($markerHash -eq $templateHash) {
        Write-Skip "Project Context up to date"
    } else {
        Write-Warn "Project Context template changed — review .claude/CLAUDE.md manually."
    }

    # Stamp new version
    if ($accepted -gt 0) {
        Write-VersionStamp
        Write-Ok "Stamped version $FRAMEWORK_VERSION"
    }

    Write-Header "Update complete (v$FRAMEWORK_VERSION)"
    Write-Host "  Accepted: $accepted  |  Rejected: $rejected  |  Skipped: $skipped"
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if ($help) {
    Write-Host ""
    Write-Host "init-ai v$FRAMEWORK_VERSION" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  init-ai                                    Bootstrap a new project"
    Write-Host "  init-ai -ProjectName foo -Language English  Bootstrap (non-interactive)"
    Write-Host "  init-ai --update                           Update an existing project"
    Write-Host "  init-ai --version                          Show framework version"
    Write-Host "  init-ai --changelog                        Show full changelog"
    Write-Host "  init-ai --help                             Show this help"
    Write-Host ""
} elseif ($version) {
    Write-Host "init-ai v$FRAMEWORK_VERSION"
} elseif ($changelog) {
    $changelogPath = Join-Path $INIT_AI_HOME "CHANGELOG.md"
    if (Test-Path $changelogPath) {
        Get-Content $changelogPath | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "CHANGELOG.md not found." -ForegroundColor Red
    }
} elseif ($update) {
    Invoke-Update
} else {
    Invoke-Bootstrap
}
