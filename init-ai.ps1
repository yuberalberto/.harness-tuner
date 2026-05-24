<#
.SYNOPSIS
    Bootstrap or update a project with init-ai (Claude Code + Cascade rules and skills).

.DESCRIPTION
    Without flags   — Bootstraps a new project. Aborts if .windsurf/ already exists.
                      Deploys claude-code/ -> .claude/ and cascade/ -> .windsurf/.
                      Never generates or touches CLAUDE.md.
    --update        — Interactive diff: shows changes per file, prompts accept/reject/skip.

.PARAMETER Language
    (Optional) User chat language interpolated into the identity rule (e.g. Spanish).
    Skips the interactive prompt.

.EXAMPLE
    # From inside your project directory:
    & "$env:USERPROFILE\init-ai\init-ai.ps1"
    & "$env:USERPROFILE\init-ai\init-ai.ps1" --update
    & "$env:USERPROFILE\init-ai\init-ai.ps1" -Language Spanish
#>

param(
    [switch]$update,
    [switch]$version,
    [switch]$changelog,
    [switch]$help,
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
$CLAUDE_CODE  = Join-Path $INIT_AI_HOME "claude-code"
$CASCADE      = Join-Path $INIT_AI_HOME "cascade"
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
        if ($fromVersion) {
            Write-Host "Changes since v${fromVersion}:" -ForegroundColor Cyan
        } else {
            Write-Host "Full changelog (no prior version stamp found):" -ForegroundColor Cyan
        }
        Write-Host ""
        foreach ($l in $output) {
            Write-Host "  $l" -ForegroundColor DarkYellow
        }
        Write-Host ""
    }
}

function Show-DiffSummary([string]$srcFile, [string]$dstFile) {
    $gitAvailable = Get-Command git -ErrorAction SilentlyContinue
    if ($gitAvailable) {
        $stat = git diff --no-index --shortstat $dstFile $srcFile 2>&1 | Select-Object -Last 1
        Write-Host "  $($stat.Trim())" -ForegroundColor DarkYellow
    } else {
        $added   = (Get-Content $srcFile).Count
        $removed = (Get-Content $dstFile).Count
        Write-Host "  $added lines (new) vs $removed lines (current)" -ForegroundColor DarkYellow
    }
}

function Show-DiffFull([string]$srcFile, [string]$dstFile) {
    $gitAvailable = Get-Command git -ErrorAction SilentlyContinue
    if ($gitAvailable) {
        git diff --no-index --color=always $dstFile $srcFile 2>&1 | Select-Object -First 80 | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Host "  (Install git to see the full diff)" -ForegroundColor DarkGray
    }
}

function Copy-FrameworkTree([string]$srcDir, [string]$dstDir, [string]$userLanguage = "") {
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    Get-ChildItem -Recurse -File $srcDir | ForEach-Object {
        $rel = $_.FullName.Substring($srcDir.Length).TrimStart('\', '/')
        $dst = Join-Path $dstDir $rel
        New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null

        # For identity.md files, interpolate {{USER_LANGUAGE}}
        if ($_.Name -eq "identity.md" -and $userLanguage) {
            $content = Get-Content $_.FullName -Raw
            $compiled = $content -replace "{{USER_LANGUAGE}}", $userLanguage
            Set-Content -Path $dst -Value $compiled -Encoding UTF8
            Write-Ok "Copied $rel (interpolated USER_LANGUAGE)"
        } else {
            Copy-Item -Force $_.FullName $dst
            Write-Ok "Copied $rel"
        }
    }
}

# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------

function Invoke-Bootstrap {
    $windsurfDir = Join-Path $TARGET ".windsurf"
    $claudeDir   = Join-Path $TARGET ".claude"

    if (Test-Path $windsurfDir) {
        Write-Err "Project already initialized (.windsurf/ exists)."
        Write-Host "  Use --update to pull in framework changes." -ForegroundColor Yellow
        exit 1
    }

    Write-Header "Bootstrapping $TARGET"

    # Get user language for interpolation
    $userLanguage = if ($Language) { $Language } else { Read-Host "User chat language (e.g. Spanish, English)" }

    # 1. Copy claude-code/ → .claude/
    Write-Host ""
    Write-Host "Copying claude-code framework..." -ForegroundColor Cyan
    Copy-FrameworkTree (Join-Path $CLAUDE_CODE "rules") (Join-Path $claudeDir "rules") $userLanguage
    Copy-FrameworkTree (Join-Path $CLAUDE_CODE "skills") (Join-Path $claudeDir "skills") $userLanguage

    # 2. Copy cascade/ → .windsurf/
    Write-Host ""
    Write-Host "Copying cascade framework..." -ForegroundColor Cyan
    Copy-FrameworkTree (Join-Path $CASCADE "rules") (Join-Path $windsurfDir "rules") $userLanguage
    Copy-FrameworkTree (Join-Path $CASCADE "skills") (Join-Path $windsurfDir "skills") $userLanguage

    # 3. Add scratch/ to .gitignore
    Write-Host ""
    Write-Host "Configuring .gitignore..." -ForegroundColor Cyan
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

    # 4. Stamp version
    Write-Host ""
    Write-VersionStamp
    Write-Ok "Stamped version $FRAMEWORK_VERSION"

    Write-Header "Bootstrap complete (v$FRAMEWORK_VERSION)"
    Write-Host ""
    Write-Host "  git add .claude .windsurf .gitignore && git commit -m 'chore: init ai'" -ForegroundColor White
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Update
# ---------------------------------------------------------------------------

function Invoke-Update {
    $windsurfDir = Join-Path $TARGET ".windsurf"
    $claudeDir   = Join-Path $TARGET ".claude"

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

    # Collect all framework files from both claude-code and cascade
    $sourceFiles = @()
    $sourceFiles += @{ src = $CLAUDE_CODE; dst = $claudeDir; agent = "claude-code" }
    $sourceFiles += @{ src = $CASCADE; dst = $windsurfDir; agent = "cascade" }

    foreach ($sourcePair in $sourceFiles) {
        $srcRoot = $sourcePair.src
        $dstRoot = $sourcePair.dst
        $agent   = $sourcePair.agent

        $frameworkFiles = Get-ChildItem -Recurse -File $srcRoot
        foreach ($srcFile in $frameworkFiles) {
            $rel     = $srcFile.FullName.Substring($srcRoot.Length).TrimStart('\', '/')
            $dstFile = Join-Path $dstRoot $rel

            Write-Host ""
            Write-Host "--- [$agent] $rel ---" -ForegroundColor White

            if (Test-Path $dstFile) {
                $srcContent = Get-Content $srcFile.FullName -Raw
                $dstContent = Get-Content $dstFile -Raw

                # For identity.md, compare without USER_LANGUAGE placeholder differences
                if ($srcFile.Name -eq "identity.md") {
                    # Normalize both by removing the placeholder for comparison
                    $srcNorm = $srcContent -replace "{{USER_LANGUAGE}}", "(user-language)"
                    $dstNorm = $dstContent -replace "[^{{]{{USER_LANGUAGE}}[^}}]|[^\w][\w]+[^\w]", "(user-language)"
                    if ($srcNorm -eq $dstNorm) {
                        Write-Skip "Identical (excluding USER_LANGUAGE) — skipping"
                        continue
                    }
                } else {
                    $srcHash = (Get-FileHash $srcFile.FullName -Algorithm MD5).Hash
                    $dstHash = (Get-FileHash $dstFile -Algorithm MD5).Hash
                    if ($srcHash -eq $dstHash) {
                        Write-Skip "Identical — skipping"
                        continue
                    }
                }
                Show-DiffSummary $srcFile.FullName $dstFile
            } else {
                Write-Host "  [NEW FILE]" -ForegroundColor Yellow
            }

            do {
                $choice = Read-Host "  Accept (a), Reject (r), Skip (s), Diff (d)? [a/r/s/d]"
                if ($choice.ToLower() -eq "d") {
                    Show-DiffFull $srcFile.FullName $dstFile
                }
            } while ($choice.ToLower() -eq "d")

            switch ($choice.ToLower()) {
                "a" {
                    New-Item -ItemType Directory -Force -Path (Split-Path $dstFile) | Out-Null
                    # For identity.md, don't interpolate during update (preserve existing user language choice)
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
    }

    # Stamp new version if any changes were accepted
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
    Write-Host "  init-ai -Language English                  Bootstrap (non-interactive language)"
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
