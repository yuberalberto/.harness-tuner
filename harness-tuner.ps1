# harness-tuner.ps1 — main CLI entry point for the harness-tuner framework.
# Encoding: UTF-8 with BOM (avoids PowerShell 5.1 em-dash / special-char parser issues).
#
# Usage:
#   ht                   Show help
#   ht init              Bootstrap current project
#   ht update            Interactive diff/merge against templates/
#   ht self-update       git pull inside $HARNESS_TUNER_HOME
#   ht --version         Print framework version
#   ht --changelog       Print CHANGELOG.md
#   ht --help            Show detailed help

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "",

    [string]$Language = "",

    [switch]$Version,
    [switch]$Changelog,
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Core variables
# ---------------------------------------------------------------------------

$HARNESS_TUNER_HOME = $PSScriptRoot
$TARGET             = (Get-Location).Path
$VERSION_STAMP      = Join-Path (Join-Path $TARGET ".claude") ".harness-tuner-version"

function Get-FrameworkVersion {
    $vFile = Join-Path $HARNESS_TUNER_HOME "VERSION"
    if (Test-Path $vFile) {
        return (Get-Content $vFile -Raw).Trim()
    }
    return "0.0.0"
}

$FRAMEWORK_VERSION = Get-FrameworkVersion

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

function Write-Header([string]$Msg) {
    Write-Host ""
    Write-Host "=== $Msg ===" -ForegroundColor Cyan
}

function Write-Ok([string]$Msg)   { Write-Host "  [OK] $Msg" -ForegroundColor Green    }
function Write-Skip([string]$Msg) { Write-Host "  [--] $Msg" -ForegroundColor DarkGray }
function Write-Warn([string]$Msg) { Write-Host "  [!!] $Msg" -ForegroundColor Yellow   }
function Write-Err([string]$Msg)  { Write-Host "  [XX] $Msg" -ForegroundColor Red      }

# ---------------------------------------------------------------------------
# Help text
# ---------------------------------------------------------------------------

function Show-Help([bool]$Detailed = $false) {
    Write-Host ""
    Write-Host "harness-tuner v$FRAMEWORK_VERSION" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor White
    Write-Host "  ht                     Show this help summary"
    Write-Host "  ht init                Bootstrap current project (.claude/ setup)"
    Write-Host "  ht update              Interactive diff/merge templates/ -> .claude/"
    Write-Host "  ht self-update         git pull inside HARNESS_TUNER_HOME"
    Write-Host "  ht --version           Print framework version"
    Write-Host "  ht --changelog         Print CHANGELOG.md"
    Write-Host "  ht --help              Show detailed help"
    Write-Host ""

    if ($Detailed) {
        Write-Host "SUBCOMMAND DETAILS:" -ForegroundColor White
        Write-Host ""
        Write-Host "  init  [-Language <lang>]" -ForegroundColor White
        Write-Host "      Copies templates/rules/, templates/skills/, templates/hooks/ to"
        Write-Host "      .claude/ and merges templates/settings.json into .claude/settings.json."
        Write-Host "      Interpolates {{USER_LANGUAGE}} in identity.md."
        Write-Host "      Aborts if .claude/.harness-tuner-version already exists."
        Write-Host "      Prompts per-file if a foreign .claude/ (no version marker) is detected."
        Write-Host ""
        Write-Host "  update" -ForegroundColor White
        Write-Host "      For each file under templates/, compares with the project counterpart."
        Write-Host "      Shows diff. Prompts: Accept (a) / Reject (r) / Skip (s) / Diff (d)."
        Write-Host "      Stamps .harness-tuner-version if any accepts were made."
        Write-Host ""
        Write-Host "  self-update" -ForegroundColor White
        Write-Host "      Runs 'git pull origin main' inside HARNESS_TUNER_HOME."
        Write-Host "      Does NOT update existing projects — run 'ht update' per project."
        Write-Host ""
        Write-Host "VARIABLES:" -ForegroundColor White
        Write-Host "  HARNESS_TUNER_HOME = $HARNESS_TUNER_HOME"
        Write-Host "  TARGET             = $TARGET"
        Write-Host ""
    }
}

# ---------------------------------------------------------------------------
# Utility: version stamp
# ---------------------------------------------------------------------------

function Write-VersionStamp {
    $dir = Split-Path $VERSION_STAMP
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Set-Content -Path $VERSION_STAMP -Value $FRAMEWORK_VERSION -Encoding UTF8
}

function Get-ProjectVersion {
    if (Test-Path $VERSION_STAMP) {
        return (Get-Content $VERSION_STAMP -Raw).Trim()
    }
    return $null
}

# ---------------------------------------------------------------------------
# Utility: diff display
# ---------------------------------------------------------------------------

function Show-DiffSummary([string]$SrcFile, [string]$DstFile) {
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $stat = git diff --no-index --shortstat $DstFile $SrcFile 2>&1 | Select-Object -Last 1
        if ($stat) {
            Write-Host "  $($stat.ToString().Trim())" -ForegroundColor DarkYellow
        }
    }
    else {
        $srcLines = (Get-Content $SrcFile -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
        $dstLines = (Get-Content $DstFile -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
        Write-Host "  Template: $srcLines lines | Project: $dstLines lines" -ForegroundColor DarkYellow
    }
}

function Show-DiffFull([string]$SrcFile, [string]$DstFile) {
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        git diff --no-index --color=always $DstFile $SrcFile 2>&1 |
            Select-Object -First 100 |
            ForEach-Object { Write-Host "  $_" }
    }
    else {
        Write-Host "  (Install git to see the full diff)" -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------------------------
# Utility: settings.json additive merge
# ---------------------------------------------------------------------------

function Merge-SettingsJson([string]$SrcPath, [string]$DstPath) {
    # Load source (template) JSON
    if (-not (Test-Path $SrcPath)) { return }

    $srcRaw = Get-Content $SrcPath -Raw -Encoding UTF8
    try {
        $src = $srcRaw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Warn "templates/settings.json is not valid JSON — skipping merge."
        return
    }

    # Load or create destination JSON
    if (Test-Path $DstPath) {
        $dstRaw = Get-Content $DstPath -Raw -Encoding UTF8
        try {
            $dst = $dstRaw | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Warn ".claude/settings.json is not valid JSON — creating backup and replacing."
            Copy-Item $DstPath "$DstPath.bak" -Force
            $dst = [PSCustomObject]@{}
        }
    }
    else {
        $dst = [PSCustomObject]@{}
    }

    # --- Merge hooks (additive) ---
    if ($src.PSObject.Properties['hooks']) {
        if (-not $dst.PSObject.Properties['hooks']) {
            $dst | Add-Member -MemberType NoteProperty -Name hooks -Value @()
        }

        $existingTriggers = @{}
        foreach ($h in $dst.hooks) {
            if ($h.PSObject.Properties['trigger']) {
                $existingTriggers[$h.trigger] = $true
            }
        }

        foreach ($h in $src.hooks) {
            if ($h.PSObject.Properties['trigger'] -and $existingTriggers.ContainsKey($h.trigger)) {
                Write-Warn "Hook trigger '$($h.trigger)' already exists — skipping (manual review needed)."
            }
            else {
                $dst.hooks += $h
            }
        }
    }

    # --- Merge mcpServers (additive) ---
    if ($src.PSObject.Properties['mcpServers']) {
        if (-not $dst.PSObject.Properties['mcpServers']) {
            $dst | Add-Member -MemberType NoteProperty -Name mcpServers -Value ([PSCustomObject]@{})
        }

        foreach ($prop in $src.mcpServers.PSObject.Properties) {
            if ($dst.mcpServers.PSObject.Properties[$prop.Name]) {
                Write-Warn "MCP server '$($prop.Name)' already declared — skipping."
            }
            else {
                $dst.mcpServers | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value
            }
        }
    }

    # --- Merge permissions (union of allowedTools arrays) ---
    if ($src.PSObject.Properties['permissions']) {
        if (-not $dst.PSObject.Properties['permissions']) {
            $dst | Add-Member -MemberType NoteProperty -Name permissions -Value ([PSCustomObject]@{})
        }

        if ($src.permissions.PSObject.Properties['allowedTools']) {
            if (-not $dst.permissions.PSObject.Properties['allowedTools']) {
                $dst.permissions | Add-Member -MemberType NoteProperty -Name allowedTools -Value @()
            }

            $existing = [System.Collections.Generic.HashSet[string]]($dst.permissions.allowedTools)
            foreach ($tool in $src.permissions.allowedTools) {
                if (-not $existing.Contains($tool)) {
                    $dst.permissions.allowedTools += $tool
                }
            }
        }
    }

    # Write merged result
    $dir = Split-Path $DstPath
    if ($dir) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $dst | ConvertTo-Json -Depth 10 | Set-Content -Path $DstPath -Encoding UTF8
    Write-Ok "Merged settings.json"
}

# ---------------------------------------------------------------------------
# Utility: copy a single template file, interpolating USER_LANGUAGE in identity.md
# ---------------------------------------------------------------------------

function Copy-TemplateFile([string]$SrcFile, [string]$DstFile, [string]$UserLanguage) {
    New-Item -ItemType Directory -Force -Path (Split-Path $DstFile) | Out-Null
    $fileName = Split-Path $SrcFile -Leaf

    if ($fileName -eq "identity.md" -and $UserLanguage) {
        $content  = Get-Content $SrcFile -Raw -Encoding UTF8
        $compiled = $content -replace [regex]::Escape("{{USER_LANGUAGE}}"), $UserLanguage
        Set-Content -Path $DstFile -Value $compiled -Encoding UTF8
        Write-Ok "Copied $fileName (interpolated USER_LANGUAGE='$UserLanguage')"
    }
    else {
        Copy-Item -Force $SrcFile $DstFile
        Write-Ok "Copied $fileName"
    }
}

# ---------------------------------------------------------------------------
# Utility: prompt per-file collision (foreign .claude/ scenario)
# ---------------------------------------------------------------------------

function Invoke-CollisionPrompt([string]$SrcFile, [string]$DstFile, [string]$Label) {
    Write-Host ""
    Write-Host "  COLLISION: $Label" -ForegroundColor Yellow
    if (Test-Path $DstFile) {
        Show-DiffSummary $SrcFile $DstFile
    }
    else {
        Write-Host "  [NEW FILE]" -ForegroundColor DarkGray
    }

    do {
        $choice = Read-Host "  Accept (a), Reject (r), Diff (d)? [a/r/d]"
        if ($choice -eq "d" -or $choice -eq "D") {
            if (Test-Path $DstFile) {
                Show-DiffFull $SrcFile $DstFile
            }
            else {
                Write-Host "  (No existing file to diff against)" -ForegroundColor DarkGray
            }
        }
    } while ($choice -eq "d" -or $choice -eq "D")

    return ($choice -eq "a" -or $choice -eq "A")
}

# ---------------------------------------------------------------------------
# Subcommand: init
# ---------------------------------------------------------------------------

function Invoke-Bootstrap {
    $claudeDir    = Join-Path $TARGET ".claude"
    $templatesDir = Join-Path $HARNESS_TUNER_HOME "templates"

    # Guard: already installed
    if (Test-Path $VERSION_STAMP) {
        Write-Err "Already installed (v$(Get-ProjectVersion))."
        Write-Host "  Run 'ht update' to apply template changes." -ForegroundColor Yellow
        exit 1
    }

    $isForeign = (Test-Path $claudeDir) -and (-not (Test-Path $VERSION_STAMP))

    if ($isForeign) {
        Write-Warn "Foreign .claude/ detected (no harness-tuner marker)."
        Write-Host "  Files that collide with templates will require your approval." -ForegroundColor Yellow
    }

    Write-Header "Bootstrapping $TARGET"

    # Resolve user language
    $userLanguage = $Language
    if (-not $userLanguage) {
        $userLanguage = Read-Host "User chat language (e.g. Spanish, English)"
    }

    if (-not (Test-Path $templatesDir)) {
        Write-Err "templates/ directory not found at: $templatesDir"
        exit 1
    }

    $anyAccepted  = $true   # for clean bootstrap, all files are auto-accepted
    $collisions   = 0

    # Collect all template files (excludes settings.json — handled separately)
    $templateFiles = Get-ChildItem -Recurse -File $templatesDir |
        Where-Object { $_.Name -ne "settings.json" }

    foreach ($srcItem in $templateFiles) {
        $rel     = $srcItem.FullName.Substring($templatesDir.Length).TrimStart('\', '/')
        $dstFile = Join-Path $claudeDir $rel

        if ($isForeign -and (Test-Path $dstFile)) {
            $collisions++
            $accepted = Invoke-CollisionPrompt $srcItem.FullName $dstFile $rel
            if ($accepted) {
                Copy-TemplateFile $srcItem.FullName $dstFile $userLanguage
            }
            else {
                Write-Skip "Rejected: $rel"
                $anyAccepted = $false   # any rejection is tracked, but we still stamp on partial accept
            }
        }
        else {
            Copy-TemplateFile $srcItem.FullName $dstFile $userLanguage
        }
    }

    # Merge settings.json
    $srcSettings = Join-Path $templatesDir "settings.json"
    $dstSettings = Join-Path $claudeDir "settings.json"

    if ($isForeign -and (Test-Path $dstSettings)) {
        # Always prompt for settings.json collision too
        $collisions++
        $acceptSettings = Invoke-CollisionPrompt $srcSettings $dstSettings "settings.json (will be merged)"
        if ($acceptSettings) {
            Merge-SettingsJson $srcSettings $dstSettings
        }
        else {
            Write-Skip "Rejected: settings.json"
        }
    }
    elseif (Test-Path $srcSettings) {
        Merge-SettingsJson $srcSettings $dstSettings
    }

    # Stamp version
    Write-VersionStamp
    Write-Ok "Stamped version $FRAMEWORK_VERSION"

    if ($isForeign) {
        Write-Header "Bootstrap complete (v$FRAMEWORK_VERSION) — $collisions collision(s) reviewed"
    }
    else {
        Write-Header "Bootstrap complete (v$FRAMEWORK_VERSION)"
    }

    Write-Host ""
    Write-Host "  Suggested next step:" -ForegroundColor White
    Write-Host "  git add .claude && git commit -m 'chore: init harness-tuner'" -ForegroundColor DarkGray
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Subcommand: update
# ---------------------------------------------------------------------------

function Invoke-Update {
    $claudeDir    = Join-Path $TARGET ".claude"
    $templatesDir = Join-Path $HARNESS_TUNER_HOME "templates"

    if (-not (Test-Path $claudeDir)) {
        Write-Err "Project not initialized (.claude/ not found). Run 'ht init' first."
        exit 1
    }

    $projectVersion = Get-ProjectVersion
    if ($projectVersion) {
        Write-Host "  Project version : v$projectVersion" -ForegroundColor White
    }
    else {
        Write-Warn "No version stamp found. Project may have been bootstrapped before harness-tuner."
    }
    Write-Host "  Framework version: v$FRAMEWORK_VERSION" -ForegroundColor White

    Write-Header "Updating $TARGET"

    $accepted = 0
    $rejected = 0
    $skipped  = 0

    $templateFiles = Get-ChildItem -Recurse -File $templatesDir |
        Where-Object { $_.Name -ne "settings.json" }

    foreach ($srcItem in $templateFiles) {
        $rel     = $srcItem.FullName.Substring($templatesDir.Length).TrimStart('\', '/')
        $dstFile = Join-Path $claudeDir $rel

        Write-Host ""
        Write-Host "--- $rel ---" -ForegroundColor White

        if (Test-Path $dstFile) {
            $srcHash = (Get-FileHash $srcItem.FullName -Algorithm MD5).Hash
            $dstHash = (Get-FileHash $dstFile -Algorithm MD5).Hash
            if ($srcHash -eq $dstHash) {
                Write-Skip "Identical — skipping"
                continue
            }
            Show-DiffSummary $srcItem.FullName $dstFile
        }
        else {
            Write-Host "  [NEW FILE]" -ForegroundColor Yellow
        }

        do {
            $choice = Read-Host "  Accept (a), Reject (r), Skip (s), Diff (d)? [a/r/s/d]"
            if ($choice -eq "d" -or $choice -eq "D") {
                Show-DiffFull $srcItem.FullName $dstFile
            }
        } while ($choice -eq "d" -or $choice -eq "D")

        switch ($choice.ToLower()) {
            "a" {
                New-Item -ItemType Directory -Force -Path (Split-Path $dstFile) | Out-Null
                Copy-Item -Force $srcItem.FullName $dstFile
                Write-Ok "Accepted: $rel"
                $accepted++
            }
            "r" {
                Write-Err "Rejected: $rel"
                $rejected++
            }
            default {
                Write-Skip "Skipped: $rel"
                $skipped++
            }
        }
    }

    # Handle settings.json separately
    $srcSettings = Join-Path $templatesDir "settings.json"
    $dstSettings = Join-Path $claudeDir "settings.json"
    if (Test-Path $srcSettings) {
        Write-Host ""
        Write-Host "--- settings.json (additive merge) ---" -ForegroundColor White
        do {
            $choice = Read-Host "  Merge template settings.json into project? Accept (a), Skip (s)? [a/s]"
        } while ($choice -ne "a" -and $choice -ne "A" -and $choice -ne "s" -and $choice -ne "S")

        if ($choice -eq "a" -or $choice -eq "A") {
            Merge-SettingsJson $srcSettings $dstSettings
            $accepted++
        }
        else {
            Write-Skip "Skipped: settings.json"
            $skipped++
        }
    }

    if ($accepted -gt 0) {
        Write-VersionStamp
        Write-Ok "Stamped version $FRAMEWORK_VERSION"
    }

    Write-Header "Update complete (v$FRAMEWORK_VERSION)"
    Write-Host "  Accepted: $accepted  |  Rejected: $rejected  |  Skipped: $skipped"
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Subcommand: self-update
# ---------------------------------------------------------------------------

function Invoke-SelfUpdate {
    Write-Header "Self-update: pulling latest harness-tuner from origin/main"
    Write-Host "  HARNESS_TUNER_HOME = $HARNESS_TUNER_HOME" -ForegroundColor DarkGray
    Write-Host ""

    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        Write-Err "git is not installed or not in PATH."
        exit 1
    }

    Push-Location $HARNESS_TUNER_HOME
    try {
        $output = git pull origin main 2>&1
        foreach ($line in $output) {
            Write-Host "  $line"
        }
    }
    finally {
        Pop-Location
    }

    Write-Host ""
    Write-Ok "Self-update complete. Run 'ht update' in each project to apply changes."
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Entry point: route subcommand or flag
# ---------------------------------------------------------------------------

# Support double-dash flag style passed as positional $Command
if ($Command -eq "--version")   { $Version   = $true; $Command = "" }
if ($Command -eq "--changelog") { $Changelog = $true; $Command = "" }
if ($Command -eq "--help")      { $Help      = $true; $Command = "" }

if ($Version) {
    Write-Host "harness-tuner v$FRAMEWORK_VERSION"
}
elseif ($Changelog) {
    $changelogPath = Join-Path $HARNESS_TUNER_HOME "CHANGELOG.md"
    if (Test-Path $changelogPath) {
        Get-Content $changelogPath | ForEach-Object { Write-Host $_ }
    }
    else {
        Write-Warn "CHANGELOG.md not found."
    }
}
elseif ($Help) {
    Show-Help -Detailed $true
}
elseif ($Command -eq "init") {
    Invoke-Bootstrap
}
elseif ($Command -eq "update") {
    Invoke-Update
}
elseif ($Command -eq "self-update") {
    Invoke-SelfUpdate
}
elseif ($Command -eq "") {
    Show-Help -Detailed $false
}
else {
    Write-Err "Unknown subcommand: '$Command'"
    Show-Help -Detailed $false
    exit 1
}
