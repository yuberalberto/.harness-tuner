# harness-tuner.ps1 — main CLI entry point for the harness-tuner framework.
# Encoding: UTF-8 with BOM (avoids PowerShell 5.1 em-dash / special-char parser issues).
#
# Usage:
#   ht                   Show help
#   ht init              Bootstrap current project
#   ht update            Update harness-tuner framework (git pull)
#   ht update-init       Interactive diff/merge templates into current project
#   ht --version         Print framework version
#   ht --changelog       Print CHANGELOG.md
#   ht --help            Show detailed help

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "",

    [string]$Language = "",
    [string]$Agent = "claude-code",

    [switch]$Version,
    [switch]$Changelog,
    [switch]$Help,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Core variables
# ---------------------------------------------------------------------------

$HARNESS_TUNER_HOME = $PSScriptRoot
$TARGET             = (Get-Location).Path
$VERSION_STAMP      = Join-Path (Join-Path $TARGET ".claude") ".harness-tuner-version"
$VERSION_STAMP_CASCADE = Join-Path (Join-Path $TARGET ".windsurf") ".harness-tuner-version"
$VERSION_STAMP_CODEX = Join-Path (Join-Path $TARGET ".codex") ".harness-tuner-version"

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
    Write-Host "  ht init -Agent codex   Bootstrap current project (.codex/ setup)"
    Write-Host "  ht update              Update framework (git pull in HARNESS_TUNER_HOME)"
    Write-Host "  ht update-init         Update current project from latest templates"
    Write-Host "  ht --version           Print framework version"
    Write-Host "  ht --changelog         Print CHANGELOG.md"
    Write-Host "  ht --help              Show detailed help"
    Write-Host ""

    if ($Detailed) {
        Write-Host "SUBCOMMAND DETAILS:" -ForegroundColor White
        Write-Host ""
        Write-Host "  init  [-Language <lang>]" -ForegroundColor White
        Write-Host "      Copies templates-claude/rules/, templates-claude/skills/, templates-claude/hooks/ to"
        Write-Host "      .claude/ and merges templates-claude/settings.json into .claude/settings.json."
        Write-Host "      Interpolates {{USER_LANGUAGE}} in identity.md."
        Write-Host "      Aborts if .claude/.harness-tuner-version already exists."
        Write-Host "      Prompts per-file if a foreign .claude/ (no version marker) is detected."
        Write-Host ""
        Write-Host "  init -Agent codex [-Language <lang>]" -ForegroundColor White
        Write-Host "      Copies templates-codex/rules/ and settings.json to .codex/."
        Write-Host "      Copies templates-claude/skills/ to .codex/skills/ with Codex wording."
        Write-Host "      Copies templates-codex/agents/ into project .agents/."
        Write-Host "      Aborts if .codex/.harness-tuner-version already exists."
        Write-Host ""
        Write-Host "  update [alias: self-update]" -ForegroundColor White
        Write-Host "      Updates harness-tuner framework by running 'git pull origin main'."
        Write-Host "      Does NOT update existing projects — run 'ht update-init' per project."
        Write-Host ""
        Write-Host "  update-init [--force]" -ForegroundColor White
        Write-Host "      Compares templates-claude/ with project .claude/ and shows summary table."
        Write-Host "      Prompts once: Apply all changes? [Y/n/review]."
        Write-Host "      Y/Enter applies all, n aborts, review enters per-file diff flow."
        Write-Host "      --force skips all prompts and applies all changes."
        Write-Host "      Stamps .harness-tuner-version if any accepts were made."
        Write-Host ""
        Write-Host "  self-update [deprecated alias]" -ForegroundColor White
        Write-Host "      Same as 'ht update' (framework update)."
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
# Utility: hooks.json additive merge (Cascade)
# ---------------------------------------------------------------------------

function Merge-HooksJson([string]$SrcPath, [string]$DstPath) {
    if (-not (Test-Path $SrcPath)) { return }

    $srcRaw = Get-Content $SrcPath -Raw -Encoding UTF8
    try {
        $src = $srcRaw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Warn "Source hooks.json is not valid JSON — skipping merge."
        return
    }

    if (Test-Path $DstPath) {
        $dstRaw = Get-Content $DstPath -Raw -Encoding UTF8
        try {
            $dst = $dstRaw | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Warn "Destination hooks.json is not valid JSON — creating backup and replacing."
            Copy-Item $DstPath "$DstPath.bak" -Force
            $dst = [PSCustomObject]@{}
        }
    }
    else {
        $dst = [PSCustomObject]@{}
    }

    if ($src.PSObject.Properties['hooks']) {
        if (-not $dst.PSObject.Properties['hooks']) {
            $dst | Add-Member -MemberType NoteProperty -Name hooks -Value ([PSCustomObject]@{})
        }

        foreach ($eventProp in $src.hooks.PSObject.Properties) {
            if (-not $dst.hooks.PSObject.Properties[$eventProp.Name]) {
                $dst.hooks | Add-Member -MemberType NoteProperty -Name $eventProp.Name -Value @()
            }

            foreach ($handler in $src.hooks.($eventProp.Name)) {
                if ($handler -notin $dst.hooks.($eventProp.Name)) {
                    $dst.hooks.($eventProp.Name) += $handler
                }
            }
        }
    }

    $dir = Split-Path $DstPath
    if ($dir) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $dst | ConvertTo-Json -Depth 10 | Set-Content -Path $DstPath -Encoding UTF8
    Write-Ok "Merged hooks.json"
}

# ---------------------------------------------------------------------------
# Utility: mcp_config.json additive merge (Cascade)
# ---------------------------------------------------------------------------

function Merge-McpConfigJson([string]$SrcPath, [string]$DstPath) {
    if (-not (Test-Path $SrcPath)) { return }

    $srcRaw = Get-Content $SrcPath -Raw -Encoding UTF8
    try {
        $src = $srcRaw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Warn "Source mcp_config.json is not valid JSON — skipping merge."
        return
    }

    if (Test-Path $DstPath) {
        $dstRaw = Get-Content $DstPath -Raw -Encoding UTF8
        try {
            $dst = $dstRaw | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Warn "Destination mcp_config.json is not valid JSON — creating backup and replacing."
            Copy-Item $DstPath "$DstPath.bak" -Force
            $dst = [PSCustomObject]@{}
        }
    }
    else {
        $dst = [PSCustomObject]@{}
    }

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

    $dir = Split-Path $DstPath
    if ($dir) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $dst | ConvertTo-Json -Depth 10 | Set-Content -Path $DstPath -Encoding UTF8
    Write-Ok "Merged mcp_config.json"
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
        Write-Warn "templates-claude/settings.json is not valid JSON — skipping merge."
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

    if ($UserLanguage) {
        $content  = Get-Content $SrcFile -Raw -Encoding UTF8
        $compiled = $content -replace [regex]::Escape("{{USER_LANGUAGE}}"), $UserLanguage
        if ($content -ne $compiled) {
            Set-Content -Path $DstFile -Value $compiled -Encoding UTF8 -NoNewline
            Write-Ok "Copied $fileName (interpolated USER_LANGUAGE='$UserLanguage')"
        }
        else {
            Copy-Item -Force $SrcFile $DstFile
            Write-Ok "Copied $fileName"
        }
    }
    else {
        Copy-Item -Force $SrcFile $DstFile
        Write-Ok "Copied $fileName"
    }
}

function Copy-CodexTemplateFile([string]$SrcFile, [string]$DstFile, [string]$UserLanguage) {
    New-Item -ItemType Directory -Force -Path (Split-Path $DstFile) | Out-Null
    $fileName = Split-Path $SrcFile -Leaf
    $compiled = Get-CompiledCodexSkillContent $SrcFile $UserLanguage
    Set-Content -Path $DstFile -Value $compiled -Encoding UTF8 -NoNewline
    Write-Ok "Copied $fileName"
}

function Copy-RawTemplateFile([string]$SrcFile, [string]$DstFile) {
    New-Item -ItemType Directory -Force -Path (Split-Path $DstFile) | Out-Null
    Copy-Item -Force $SrcFile $DstFile
    Write-Ok "Copied $(Split-Path $SrcFile -Leaf)"
}

function Get-CodexInstalledLanguage([string]$CodexDir) {
    $identityPath = Join-Path $CodexDir "rules\identity.md"
    if (-not (Test-Path $identityPath)) {
        return ""
    }

    $content = Get-Content $identityPath -Raw -Encoding UTF8
    if ($content -match "Chat with the user in ([^.\r\n]+)") {
        return $matches[1].Trim()
    }
    if ($content -match "Language:\s*([^\r\n]+)") {
        return $matches[1].Trim()
    }
    return ""
}

function Get-CompiledTemplateContent([string]$SrcFile, [string]$UserLanguage) {
    $content = Get-Content $SrcFile -Raw -Encoding UTF8
    if ($UserLanguage) {
        return ($content -replace [regex]::Escape("{{USER_LANGUAGE}}"), $UserLanguage)
    }
    return $content
}

function Get-CompiledCodexSkillContent([string]$SrcFile, [string]$UserLanguage) {
    $compiled = Get-CompiledTemplateContent $SrcFile $UserLanguage
    return ($compiled `
        -creplace "Claude Code", "Codex" `
        -creplace "Claude", "Codex" `
        -creplace "\.claude", ".codex")
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
    $templatesDir = Join-Path $HARNESS_TUNER_HOME "templates-claude"

    # Guard: already installed
    if (Test-Path $VERSION_STAMP) {
        Write-Err "Already installed (v$(Get-ProjectVersion))."
        Write-Host "  Run 'ht update-init' to apply template changes." -ForegroundColor Yellow
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
        Write-Err "templates-claude/ directory not found at: $templatesDir"
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
# Subcommand: init (Cascade)
# ---------------------------------------------------------------------------

function Invoke-BootstrapCascade {
    $windsurfDir   = Join-Path $TARGET ".windsurf"
    $templatesDir  = Join-Path $HARNESS_TUNER_HOME "templates-cascade"
    $skillsDir     = Join-Path $HARNESS_TUNER_HOME "templates-claude\skills"

    # Guard: already installed
    if (Test-Path $VERSION_STAMP_CASCADE) {
        Write-Err "Already installed (v$(Get-Content $VERSION_STAMP_CASCADE -Raw).Trim())."
        Write-Host "  Run 'ht update-init' to apply template changes." -ForegroundColor Yellow
        exit 1
    }

    $isForeign = (Test-Path $windsurfDir) -and (-not (Test-Path $VERSION_STAMP_CASCADE))

    if ($isForeign) {
        Write-Warn "Foreign .windsurf/ detected (no harness-tuner marker)."
        Write-Host "  Files that collide with templates will require your approval." -ForegroundColor Yellow
    }

    Write-Header "Bootstrapping $TARGET for Cascade"

    # Resolve user language
    $userLanguage = $Language
    if (-not $userLanguage) {
        $userLanguage = Read-Host "User chat language (e.g. Spanish, English)"
    }

    if (-not (Test-Path $templatesDir)) {
        Write-Err "templates-cascade/ directory not found at: $templatesDir"
        exit 1
    }

    if (-not (Test-Path $skillsDir)) {
        Write-Err "templates-claude/skills/ directory not found at: $skillsDir"
        exit 1
    }

    $anyAccepted  = $true
    $collisions   = 0

    # Copy rules from templates-cascade/rules/
    $rulesSrc = Join-Path $templatesDir "rules"
    if (Test-Path $rulesSrc) {
        $ruleFiles = Get-ChildItem -Recurse -File $rulesSrc
        foreach ($srcItem in $ruleFiles) {
            $rel     = $srcItem.FullName.Substring($rulesSrc.Length).TrimStart('\', '/')
            $dstFile = Join-Path $windsurfDir "rules\$rel"

            if ($isForeign -and (Test-Path $dstFile)) {
                $collisions++
                $accepted = Invoke-CollisionPrompt $srcItem.FullName $dstFile "rules/$rel"
                if ($accepted) {
                    Copy-TemplateFile $srcItem.FullName $dstFile $userLanguage
                }
                else {
                    Write-Skip "Rejected: rules/$rel"
                    $anyAccepted = $false
                }
            }
            else {
                Copy-TemplateFile $srcItem.FullName $dstFile $userLanguage
            }
        }
    }

    # Copy skills from templates/skills/
    if (Test-Path $skillsDir) {
        $skillDirs = Get-ChildItem -Directory $skillsDir
        foreach ($skillDir in $skillDirs) {
            $skillSrc = $skillDir.FullName
            $skillDst = Join-Path $windsurfDir "skills\$($skillDir.Name)"

            $skillFiles = Get-ChildItem -Recurse -File $skillSrc
            foreach ($srcItem in $skillFiles) {
                $rel     = $srcItem.FullName.Substring($skillSrc.Length).TrimStart('\', '/')
                $dstFile = Join-Path $skillDst $rel

                if ($isForeign -and (Test-Path $dstFile)) {
                    $collisions++
                    $accepted = Invoke-CollisionPrompt $srcItem.FullName $dstFile "skills/$($skillDir.Name)/$rel"
                    if ($accepted) {
                        Copy-TemplateFile $srcItem.FullName $dstFile $userLanguage
                    }
                    else {
                        Write-Skip "Rejected: skills/$($skillDir.Name)/$rel"
                        $anyAccepted = $false
                    }
                }
                else {
                    Copy-TemplateFile $srcItem.FullName $dstFile $userLanguage
                }
            }
        }
    }

    # Copy hooks from templates-cascade/hooks/
    $hooksSrc = Join-Path $templatesDir "hooks"
    if (Test-Path $hooksSrc) {
        $hookFiles = Get-ChildItem -Recurse -File $hooksSrc
        foreach ($srcItem in $hookFiles) {
            $rel     = $srcItem.FullName.Substring($hooksSrc.Length).TrimStart('\', '/')
            $dstFile = Join-Path $windsurfDir "hooks\$rel"

            # Ensure directory exists
            New-Item -ItemType Directory -Force -Path (Split-Path $dstFile) | Out-Null

            if ($isForeign -and (Test-Path $dstFile)) {
                $collisions++
                $accepted = Invoke-CollisionPrompt $srcItem.FullName $dstFile "hooks/$rel"
                if ($accepted) {
                    Copy-Item -Force $srcItem.FullName $dstFile
                    Write-Ok "Copied hooks/$rel"
                }
                else {
                    Write-Skip "Rejected: hooks/$rel"
                    $anyAccepted = $false
                }
            }
            else {
                Copy-Item -Force $srcItem.FullName $dstFile
                Write-Ok "Copied hooks/$rel"
            }
        }
    }

    # Merge hooks.json
    $srcHooks = Join-Path $templatesDir "hooks.json"
    $dstHooks = Join-Path $windsurfDir "hooks.json"

    if ($isForeign -and (Test-Path $dstHooks)) {
        $collisions++
        $acceptHooks = Invoke-CollisionPrompt $srcHooks $dstHooks "hooks.json (will be merged)"
        if ($acceptHooks) {
            Merge-HooksJson $srcHooks $dstHooks
        }
        else {
            Write-Skip "Rejected: hooks.json"
        }
    }
    elseif (Test-Path $srcHooks) {
        Merge-HooksJson $srcHooks $dstHooks
    }

    # Merge mcp_config.json (add engram entry)
    $codeiumDir = Join-Path $env:USERPROFILE ".codeium"
    $windsurfConfigDir = Join-Path $codeiumDir "windsurf"
    $srcMcp = Join-Path $templatesDir "mcp_config.json"
    $dstMcp = Join-Path $windsurfConfigDir "mcp_config.json"

    if (Test-Path $srcMcp) {
        if ($isForeign -and (Test-Path $dstMcp)) {
            $collisions++
            $acceptMcp = Invoke-CollisionPrompt $srcMcp $dstMcp "mcp_config.json (will be merged)"
            if ($acceptMcp) {
                Merge-McpConfigJson $srcMcp $dstMcp
            }
            else {
                Write-Skip "Rejected: mcp_config.json"
            }
        }
        else {
            Merge-McpConfigJson $srcMcp $dstMcp
        }
    }

    # Stamp version
    $dir = Split-Path $VERSION_STAMP_CASCADE
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Set-Content -Path $VERSION_STAMP_CASCADE -Value $FRAMEWORK_VERSION -Encoding UTF8
    Write-Ok "Stamped version $FRAMEWORK_VERSION"

    if ($isForeign) {
        Write-Header "Bootstrap complete (v$FRAMEWORK_VERSION) — $collisions collision(s) reviewed"
    }
    else {
        Write-Header "Bootstrap complete (v$FRAMEWORK_VERSION)"
    }

    Write-Host ""
    Write-Host "  Suggested next step:" -ForegroundColor White
    Write-Host "  git add .windsurf && git commit -m 'chore: init harness-tuner for Cascade'" -ForegroundColor DarkGray
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Subcommand: init (Codex)
# ---------------------------------------------------------------------------

function Invoke-BootstrapCodex {
    $codexDir     = Join-Path $TARGET ".codex"
    $templatesDir = Join-Path $HARNESS_TUNER_HOME "templates-codex"
    $skillsDir    = Join-Path $HARNESS_TUNER_HOME "templates-claude\skills"
    $agentsDir    = Join-Path $templatesDir "agents"

    if (Test-Path $VERSION_STAMP_CODEX) {
        Write-Err "Already installed (v$(Get-Content $VERSION_STAMP_CODEX -Raw).Trim())."
        Write-Host "  Run 'ht update-init -Agent codex' to apply template changes." -ForegroundColor Yellow
        exit 1
    }

    $isForeign = (Test-Path $codexDir) -and (-not (Test-Path $VERSION_STAMP_CODEX))

    if ($isForeign) {
        Write-Warn "Foreign .codex/ detected (no harness-tuner marker)."
        Write-Host "  Files that collide with templates will require your approval." -ForegroundColor Yellow
    }

    Write-Header "Bootstrapping $TARGET for Codex"

    $userLanguage = $Language
    if (-not $userLanguage) {
        $userLanguage = Read-Host "User chat language (e.g. Spanish, English)"
    }

    if (-not (Test-Path $templatesDir)) {
        Write-Err "templates-codex/ directory not found at: $templatesDir"
        exit 1
    }

    if (-not (Test-Path $skillsDir)) {
        Write-Err "templates-claude/skills/ directory not found at: $skillsDir"
        exit 1
    }

    $collisions = 0

    $templateFiles = Get-ChildItem -Recurse -File $templatesDir
    foreach ($srcItem in $templateFiles) {
        $rel     = $srcItem.FullName.Substring($templatesDir.Length).TrimStart('\', '/')
        $dstFile = Join-Path $codexDir $rel

        if ($isForeign -and (Test-Path $dstFile)) {
            $collisions++
            $accepted = Invoke-CollisionPrompt $srcItem.FullName $dstFile $rel
            if ($accepted) {
                Copy-TemplateFile $srcItem.FullName $dstFile $userLanguage
            }
            else {
                Write-Skip "Rejected: $rel"
            }
        }
        else {
            Copy-TemplateFile $srcItem.FullName $dstFile $userLanguage
        }
    }

    $skillDirs = Get-ChildItem -Directory $skillsDir
    foreach ($skillDir in $skillDirs) {
        $skillSrc = $skillDir.FullName
        $skillDst = Join-Path $codexDir "skills\$($skillDir.Name)"

        $skillFiles = Get-ChildItem -Recurse -File $skillSrc
        foreach ($srcItem in $skillFiles) {
            $rel     = $srcItem.FullName.Substring($skillSrc.Length).TrimStart('\', '/')
            $dstFile = Join-Path $skillDst $rel

            if ($isForeign -and (Test-Path $dstFile)) {
                $collisions++
                $accepted = Invoke-CollisionPrompt $srcItem.FullName $dstFile "skills/$($skillDir.Name)/$rel"
                if ($accepted) {
                    Copy-CodexTemplateFile $srcItem.FullName $dstFile $userLanguage
                }
                else {
                    Write-Skip "Rejected: skills/$($skillDir.Name)/$rel"
                }
            }
            else {
                Copy-CodexTemplateFile $srcItem.FullName $dstFile $userLanguage
            }
        }
    }

    if (Test-Path $agentsDir) {
        $agentFiles = Get-ChildItem -Recurse -File $agentsDir
        foreach ($srcItem in $agentFiles) {
            $rel     = $srcItem.FullName.Substring($agentsDir.Length).TrimStart('\', '/')
            $dstFile = Join-Path $TARGET ".agents\$rel"

            if ($isForeign -and (Test-Path $dstFile)) {
                $collisions++
                $accepted = Invoke-CollisionPrompt $srcItem.FullName $dstFile ".agents/$rel"
                if ($accepted) {
                    Copy-RawTemplateFile $srcItem.FullName $dstFile
                }
                else {
                    Write-Skip "Rejected: .agents/$rel"
                }
            }
            else {
                Copy-RawTemplateFile $srcItem.FullName $dstFile
            }
        }
    }

    $dir = Split-Path $VERSION_STAMP_CODEX
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Set-Content -Path $VERSION_STAMP_CODEX -Value $FRAMEWORK_VERSION -Encoding UTF8
    Write-Ok "Stamped version $FRAMEWORK_VERSION"

    if ($isForeign) {
        Write-Header "Bootstrap complete (v$FRAMEWORK_VERSION) — $collisions collision(s) reviewed"
    }
    else {
        Write-Header "Bootstrap complete (v$FRAMEWORK_VERSION)"
    }

    Write-Host ""
    Write-Host "  Suggested next step:" -ForegroundColor White
    Write-Host "  git add .codex && git commit -m 'chore: init harness-tuner for Codex'" -ForegroundColor DarkGray
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Subcommand: update-init
# ---------------------------------------------------------------------------

function Get-ChangeSummary {
    param(
        [string]$SrcFile,
        [string]$DstFile
    )

    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $stat = git diff --no-index --shortstat $DstFile $SrcFile 2>&1 | Select-Object -Last 1
        if ($stat) {
            # Parse "1 file changed, 3 insertions(+), 2 deletions(-)"
            if ($stat -match "(\d+) insertion") {
                $added = [int]$matches[1]
            } else {
                $added = 0
            }
            if ($stat -match "(\d+) deletion") {
                $removed = [int]$matches[1]
            } else {
                $removed = 0
            }
            return @{ Added = $added; Removed = $removed }
        }
    }

    # Fallback: count lines
    $srcLines = (Get-Content $SrcFile -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
    $dstLines = (Get-Content $DstFile -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
    $added = [math]::Max(0, $srcLines - $dstLines)
    $removed = [math]::Max(0, $dstLines - $srcLines)
    return @{ Added = $added; Removed = $removed }
}

function Show-ChangeSummaryTable {
    param(
        [array]$Changes
    )

    if ($Changes.Count -eq 0) {
        Write-Host "  No changes detected." -ForegroundColor Green
        return
    }

    Write-Host ""
    Write-Host "  File                          Action    +lines  -lines" -ForegroundColor White
    Write-Host "  ─────────────────────────────────────────────────────" -ForegroundColor DarkGray

    foreach ($change in $Changes) {
        $fileDisplay = if ($change.File.Length -gt 30) { $change.File.Substring(0, 27) + "..." } else { $change.File }
        Write-Host ("  {0,-30} {1,-9} {2,7}  {3,7}" -f $fileDisplay, $change.Action, $change.Added, $change.Removed)
    }
    Write-Host ""
}

function Invoke-Update {
    param(
        [switch]$Force
    )

    $claudeDir    = Join-Path $TARGET ".claude"
    $templatesDir = Join-Path $HARNESS_TUNER_HOME "templates-claude"

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

    # Phase 1: Collect all pending changes silently
    $pendingChanges = @()
    $templateFiles = Get-ChildItem -Recurse -File $templatesDir |
        Where-Object { $_.Name -ne "settings.json" }

    foreach ($srcItem in $templateFiles) {
        $rel     = $srcItem.FullName.Substring($templatesDir.Length).TrimStart('\', '/')
        $dstFile = Join-Path $claudeDir $rel

        if (Test-Path $dstFile) {
            $srcHash = (Get-FileHash $srcItem.FullName -Algorithm MD5).Hash
            $dstHash = (Get-FileHash $dstFile -Algorithm MD5).Hash
            if ($srcHash -eq $dstHash) {
                continue  # Identical, skip
            }
            $summary = Get-ChangeSummary $srcItem.FullName $dstFile
            $pendingChanges += @{
                File = $rel
                Action = "update"
                Added = $summary.Added
                Removed = $summary.Removed
                SrcFile = $srcItem.FullName
                DstFile = $dstFile
                IsSettings = $false
            }
        }
        else {
            $srcLines = (Get-Content $srcItem.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
            $pendingChanges += @{
                File = $rel
                Action = "new"
                Added = $srcLines
                Removed = 0
                SrcFile = $srcItem.FullName
                DstFile = $dstFile
                IsSettings = $false
            }
        }
    }

    # Check settings.json separately
    $srcSettings = Join-Path $templatesDir "settings.json"
    $dstSettings = Join-Path $claudeDir "settings.json"
    if (Test-Path $srcSettings) {
        $pendingChanges += @{
            File = "settings.json"
            Action = "merge"
            Added = 0
            Removed = 0
            SrcFile = $srcSettings
            DstFile = $dstSettings
            IsSettings = $true
        }
    }

    # Phase 2: Display summary table
    Show-ChangeSummaryTable $pendingChanges

    if ($pendingChanges.Count -eq 0) {
        Write-Ok "No changes to apply."
        return
    }

    # Phase 3: Single confirmation prompt (unless --force)
    $applyAll = $false
    if ($Force) {
        $applyAll = $true
    }
    else {
        do {
            $choice = Read-Host "  Apply all changes? [Y/n/review]"
            $choice = $choice.Trim().ToLower()
        } while ($choice -notin @("", "y", "n", "review"))

        switch ($choice) {
            "" { $applyAll = $true }  # Enter = Y
            "y" { $applyAll = $true }
            "n" {
                Write-Host "  Aborted — no changes applied." -ForegroundColor Yellow
                return
            }
            "review" {
                # Fall through to per-file review flow
                $applyAll = $false
            }
        }
    }

    $accepted = 0
    $rejected = 0
    $skipped  = 0

    # Phase 4: Apply changes
    if ($applyAll) {
        # Apply all changes without further prompts
        foreach ($change in $pendingChanges) {
            if ($change.IsSettings) {
                Merge-SettingsJson $change.SrcFile $change.DstFile
                Write-Ok "Merged: settings.json"
                $accepted++
            }
            else {
                New-Item -ItemType Directory -Force -Path (Split-Path $change.DstFile) | Out-Null
                Copy-Item -Force $change.SrcFile $change.DstFile
                Write-Ok "Accepted: $($change.File)"
                $accepted++
            }
        }
    }
    else {
        # Per-file review flow (existing behavior)
        foreach ($change in $pendingChanges) {
            if ($change.IsSettings) {
                Write-Host ""
                Write-Host "--- settings.json (additive merge) ---" -ForegroundColor White
                do {
                    $choice = Read-Host "  Merge template settings.json into project? Accept (a), Skip (s)? [a/s]"
                } while ($choice -ne "a" -and $choice -ne "A" -and $choice -ne "s" -and $choice -ne "S")

                if ($choice -eq "a" -or $choice -eq "A") {
                    Merge-SettingsJson $change.SrcFile $change.DstFile
                    Write-Ok "Merged: settings.json"
                    $accepted++
                }
                else {
                    Write-Skip "Skipped: settings.json"
                    $skipped++
                }
            }
            else {
                Write-Host ""
                Write-Host "--- $($change.File) ---" -ForegroundColor White
                if ($change.Action -eq "update") {
                    Show-DiffSummary $change.SrcFile $change.DstFile
                }
                else {
                    Write-Host "  [NEW FILE]" -ForegroundColor Yellow
                }

                do {
                    $choice = Read-Host "  Accept (a), Reject (r), Skip (s), Diff (d)? [a/r/s/d]"
                    if ($choice -eq "d" -or $choice -eq "D") {
                        Show-DiffFull $change.SrcFile $change.DstFile
                    }
                } while ($choice -eq "d" -or $choice -eq "D")

                switch ($choice.ToLower()) {
                    "a" {
                        New-Item -ItemType Directory -Force -Path (Split-Path $change.DstFile) | Out-Null
                        Copy-Item -Force $change.SrcFile $change.DstFile
                        Write-Ok "Accepted: $($change.File)"
                        $accepted++
                    }
                    "r" {
                        Write-Err "Rejected: $($change.File)"
                        $rejected++
                    }
                    default {
                        Write-Skip "Skipped: $($change.File)"
                        $skipped++
                    }
                }
            }
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
# Subcommand: update (Cascade)
# ---------------------------------------------------------------------------

function Invoke-UpdateCascade {
    param(
        [switch]$Force
    )

    $windsurfDir   = Join-Path $TARGET ".windsurf"
    $templatesDir  = Join-Path $HARNESS_TUNER_HOME "templates-cascade"
    $skillsDir     = Join-Path $HARNESS_TUNER_HOME "templates-claude\skills"

    if (-not (Test-Path $windsurfDir)) {
        Write-Err "Project not initialized (.windsurf/ not found). Run 'ht init -Agent cascade' first."
        exit 1
    }

    if (Test-Path $VERSION_STAMP_CASCADE) {
        $projectVersion = (Get-Content $VERSION_STAMP_CASCADE -Raw).Trim()
    }
    else {
        $projectVersion = $null
    }
    if ($projectVersion) {
        Write-Host "  Project version : v$projectVersion" -ForegroundColor White
    }
    else {
        Write-Warn "No version stamp found. Project may have been bootstrapped before harness-tuner."
    }
    Write-Host "  Framework version: v$FRAMEWORK_VERSION" -ForegroundColor White

    Write-Header "Updating $TARGET for Cascade"

    # Phase 1: Collect all pending changes silently
    $pendingChanges = @()

    # Collect skills from templates/skills/
    if (Test-Path $skillsDir) {
        $skillDirs = Get-ChildItem -Directory $skillsDir
        foreach ($skillDir in $skillDirs) {
            $skillSrc = $skillDir.FullName
            $skillDst = Join-Path $windsurfDir "skills\$($skillDir.Name)"

            $skillFiles = Get-ChildItem -Recurse -File $skillSrc
            foreach ($srcItem in $skillFiles) {
                $rel     = $srcItem.FullName.Substring($skillSrc.Length).TrimStart('\', '/')
                $dstFile = Join-Path $skillDst $rel

                if (Test-Path $dstFile) {
                    $srcHash = (Get-FileHash $srcItem.FullName -Algorithm MD5).Hash
                    $dstHash = (Get-FileHash $dstFile -Algorithm MD5).Hash
                    if ($srcHash -eq $dstHash) {
                        continue  # Identical, skip
                    }
                    $summary = Get-ChangeSummary $srcItem.FullName $dstFile
                    $pendingChanges += @{
                        File = "skills/$($skillDir.Name)/$rel"
                        Action = "update"
                        Added = $summary.Added
                        Removed = $summary.Removed
                        SrcFile = $srcItem.FullName
                        DstFile = $dstFile
                        IsSettings = $false
                    }
                }
                else {
                    $srcLines = (Get-Content $srcItem.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
                    $pendingChanges += @{
                        File = "skills/$($skillDir.Name)/$rel"
                        Action = "new"
                        Added = $srcLines
                        Removed = 0
                        SrcFile = $srcItem.FullName
                        DstFile = $dstFile
                        IsSettings = $false
                    }
                }
            }
        }
    }

    # Collect rules from templates-cascade/rules/
    if (Test-Path $templatesDir) {
        $rulesSrc = Join-Path $templatesDir "rules"
        if (Test-Path $rulesSrc) {
            $ruleFiles = Get-ChildItem -Recurse -File $rulesSrc
            foreach ($srcItem in $ruleFiles) {
                $rel     = $srcItem.FullName.Substring($rulesSrc.Length).TrimStart('\', '/')
                $dstFile = Join-Path $windsurfDir "rules\$rel"

                if (Test-Path $dstFile) {
                    $srcHash = (Get-FileHash $srcItem.FullName -Algorithm MD5).Hash
                    $dstHash = (Get-FileHash $dstFile -Algorithm MD5).Hash
                    if ($srcHash -eq $dstHash) {
                        continue  # Identical, skip
                    }
                    $summary = Get-ChangeSummary $srcItem.FullName $dstFile
                    $pendingChanges += @{
                        File = "rules/$rel"
                        Action = "update"
                        Added = $summary.Added
                        Removed = $summary.Removed
                        SrcFile = $srcItem.FullName
                        DstFile = $dstFile
                        IsSettings = $false
                    }
                }
                else {
                    $srcLines = (Get-Content $srcItem.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
                    $pendingChanges += @{
                        File = "rules/$rel"
                        Action = "new"
                        Added = $srcLines
                        Removed = 0
                        SrcFile = $srcItem.FullName
                        DstFile = $dstFile
                        IsSettings = $false
                    }
                }
            }
        }
    }

    # Collect hooks from templates-cascade/hooks/
    $hooksSrc = Join-Path $templatesDir "hooks"
    if (Test-Path $hooksSrc) {
        $hookFiles = Get-ChildItem -Recurse -File $hooksSrc
        foreach ($srcItem in $hookFiles) {
            $rel     = $srcItem.FullName.Substring($hooksSrc.Length).TrimStart('\', '/')
            $dstFile = Join-Path $windsurfDir "hooks\$rel"

            if (Test-Path $dstFile) {
                $srcHash = (Get-FileHash $srcItem.FullName -Algorithm MD5).Hash
                $dstHash = (Get-FileHash $dstFile -Algorithm MD5).Hash
                if ($srcHash -eq $dstHash) {
                    continue  # Identical, skip
                }
                $summary = Get-ChangeSummary $srcItem.FullName $dstFile
                $pendingChanges += @{
                    File = "hooks/$rel"
                    Action = "update"
                    Added = $summary.Added
                    Removed = $summary.Removed
                    SrcFile = $srcItem.FullName
                    DstFile = $dstFile
                    IsSettings = $false
                }
            }
            else {
                $srcLines = (Get-Content $srcItem.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
                $pendingChanges += @{
                    File = "hooks/$rel"
                    Action = "new"
                    Added = $srcLines
                    Removed = 0
                    SrcFile = $srcItem.FullName
                    DstFile = $dstFile
                    IsSettings = $false
                }
            }
        }
    }

    # Check hooks.json separately
    $srcHooks = Join-Path $templatesDir "hooks.json"
    $dstHooks = Join-Path $windsurfDir "hooks.json"
    if (Test-Path $srcHooks) {
        $pendingChanges += @{
            File = "hooks.json"
            Action = "merge"
            Added = 0
            Removed = 0
            SrcFile = $srcHooks
            DstFile = $dstHooks
            IsHooks = $true
        }
    }

    # Phase 2: Display summary table
    Show-ChangeSummaryTable $pendingChanges

    if ($pendingChanges.Count -eq 0) {
        Write-Ok "No changes to apply."
        return
    }

    # Phase 3: Single confirmation prompt (unless --force)
    $applyAll = $false
    if ($Force) {
        $applyAll = $true
    }
    else {
        do {
            $choice = Read-Host "  Apply all changes? [Y/n/review]"
            $choice = $choice.Trim().ToLower()
        } while ($choice -notin @("", "y", "n", "review"))

        switch ($choice) {
            "" { $applyAll = $true }  # Enter = Y
            "y" { $applyAll = $true }
            "n" {
                Write-Host "  Aborted — no changes applied." -ForegroundColor Yellow
                return
            }
            "review" {
                # Fall through to per-file review flow
                $applyAll = $false
            }
        }
    }

    $accepted = 0
    $rejected = 0
    $skipped  = 0

    # Phase 4: Apply changes
    if ($applyAll) {
        # Apply all changes without further prompts
        foreach ($change in $pendingChanges) {
            if ($change.IsHooks) {
                Merge-HooksJson $change.SrcFile $change.DstFile
                Write-Ok "Merged: hooks.json"
                $accepted++
            }
            else {
                New-Item -ItemType Directory -Force -Path (Split-Path $change.DstFile) | Out-Null
                Copy-Item -Force $change.SrcFile $change.DstFile
                Write-Ok "Accepted: $($change.File)"
                $accepted++
            }
        }
    }
    else {
        # Per-file review flow (existing behavior)
        foreach ($change in $pendingChanges) {
            if ($change.IsHooks) {
                Write-Host ""
                Write-Host "--- hooks.json (additive merge) ---" -ForegroundColor White
                do {
                    $choice = Read-Host "  Merge template hooks.json into project? Accept (a), Skip (s)? [a/s]"
                } while ($choice -ne "a" -and $choice -ne "A" -and $choice -ne "s" -and $choice -ne "S")

                if ($choice -eq "a" -or $choice -eq "A") {
                    Merge-HooksJson $change.SrcFile $change.DstFile
                    Write-Ok "Merged: hooks.json"
                    $accepted++
                }
                else {
                    Write-Skip "Skipped: hooks.json"
                    $skipped++
                }
            }
            else {
                Write-Host ""
                Write-Host "--- $($change.File) ---" -ForegroundColor White
                if ($change.Action -eq "update") {
                    Show-DiffSummary $change.SrcFile $change.DstFile
                }
                else {
                    Write-Host "  [NEW FILE]" -ForegroundColor Yellow
                }

                do {
                    $choice = Read-Host "  Accept (a), Reject (r), Skip (s), Diff (d)? [a/r/s/d]"
                    if ($choice -eq "d" -or $choice -eq "D") {
                        Show-DiffFull $change.SrcFile $change.DstFile
                    }
                } while ($choice -eq "d" -or $choice -eq "D")

                switch ($choice.ToLower()) {
                    "a" {
                        New-Item -ItemType Directory -Force -Path (Split-Path $change.DstFile) | Out-Null
                        Copy-Item -Force $change.SrcFile $change.DstFile
                        Write-Ok "Accepted: $($change.File)"
                        $accepted++
                    }
                    "r" {
                        Write-Err "Rejected: $($change.File)"
                        $rejected++
                    }
                    default {
                        Write-Skip "Skipped: $($change.File)"
                        $skipped++
                    }
                }
            }
        }
    }

    if ($accepted -gt 0) {
        $dir = Split-Path $VERSION_STAMP_CASCADE
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Set-Content -Path $VERSION_STAMP_CASCADE -Value $FRAMEWORK_VERSION -Encoding UTF8
        Write-Ok "Stamped version $FRAMEWORK_VERSION"
    }

    Write-Header "Update complete (v$FRAMEWORK_VERSION)"
    Write-Host "  Accepted: $accepted  |  Rejected: $rejected  |  Skipped: $skipped"
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Subcommand: update (Codex)
# ---------------------------------------------------------------------------

function Invoke-UpdateCodex {
    param(
        [switch]$Force
    )

    $codexDir     = Join-Path $TARGET ".codex"
    $templatesDir = Join-Path $HARNESS_TUNER_HOME "templates-codex"
    $skillsDir    = Join-Path $HARNESS_TUNER_HOME "templates-claude\skills"
    $agentsDir    = Join-Path $templatesDir "agents"

    if (-not (Test-Path $codexDir)) {
        Write-Err "Project not initialized (.codex/ not found). Run 'ht init -Agent codex' first."
        exit 1
    }

    if (Test-Path $VERSION_STAMP_CODEX) {
        $projectVersion = (Get-Content $VERSION_STAMP_CODEX -Raw).Trim()
    }
    else {
        $projectVersion = $null
    }
    if ($projectVersion) {
        Write-Host "  Project version : v$projectVersion" -ForegroundColor White
    }
    else {
        Write-Warn "No version stamp found. Project may have been bootstrapped before harness-tuner."
    }
    Write-Host "  Framework version: v$FRAMEWORK_VERSION" -ForegroundColor White

    Write-Header "Updating $TARGET for Codex"

    $userLanguage = $Language
    if (-not $userLanguage) {
        $userLanguage = Get-CodexInstalledLanguage $codexDir
    }

    $pendingChanges = @()

    if (Test-Path $templatesDir) {
        $templateFiles = Get-ChildItem -Recurse -File $templatesDir
        foreach ($srcItem in $templateFiles) {
            $rel     = $srcItem.FullName.Substring($templatesDir.Length).TrimStart('\', '/')
            $dstFile = Join-Path $codexDir $rel

            if (Test-Path $dstFile) {
                $srcContent = Get-CompiledTemplateContent $srcItem.FullName $userLanguage
                $dstContent = Get-Content $dstFile -Raw -Encoding UTF8
                if ($srcContent -eq $dstContent) {
                    continue
                }
                $summary = Get-ChangeSummary $srcItem.FullName $dstFile
                $pendingChanges += @{
                    File = $rel
                    Action = "update"
                    Added = $summary.Added
                    Removed = $summary.Removed
                    SrcFile = $srcItem.FullName
                    DstFile = $dstFile
                    IsCodexSkill = $false
                }
            }
            else {
                $srcLines = (Get-Content $srcItem.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
                $pendingChanges += @{
                    File = $rel
                    Action = "new"
                    Added = $srcLines
                    Removed = 0
                    SrcFile = $srcItem.FullName
                    DstFile = $dstFile
                    IsCodexSkill = $false
                }
            }
        }
    }

    if (Test-Path $skillsDir) {
        $skillDirs = Get-ChildItem -Directory $skillsDir
        foreach ($skillDir in $skillDirs) {
            $skillSrc = $skillDir.FullName
            $skillDst = Join-Path $codexDir "skills\$($skillDir.Name)"

            $skillFiles = Get-ChildItem -Recurse -File $skillSrc
            foreach ($srcItem in $skillFiles) {
                $rel     = $srcItem.FullName.Substring($skillSrc.Length).TrimStart('\', '/')
                $dstFile = Join-Path $skillDst $rel

                if (Test-Path $dstFile) {
                    $srcContent = Get-CompiledCodexSkillContent $srcItem.FullName $userLanguage
                    $dstContent = Get-Content $dstFile -Raw -Encoding UTF8
                    if ($srcContent -eq $dstContent) {
                        continue
                    }
                    $summary = Get-ChangeSummary $srcItem.FullName $dstFile
                    $pendingChanges += @{
                        File = "skills/$($skillDir.Name)/$rel"
                        Action = "update"
                        Added = $summary.Added
                        Removed = $summary.Removed
                        SrcFile = $srcItem.FullName
                        DstFile = $dstFile
                        IsCodexSkill = $true
                    }
                }
                else {
                    $srcLines = (Get-Content $srcItem.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
                    $pendingChanges += @{
                        File = "skills/$($skillDir.Name)/$rel"
                        Action = "new"
                        Added = $srcLines
                        Removed = 0
                        SrcFile = $srcItem.FullName
                        DstFile = $dstFile
                        IsCodexSkill = $true
                    }
                }
            }
        }
    }

    if (Test-Path $agentsDir) {
        $agentFiles = Get-ChildItem -Recurse -File $agentsDir
        foreach ($srcItem in $agentFiles) {
            $rel     = $srcItem.FullName.Substring($agentsDir.Length).TrimStart('\', '/')
            $dstFile = Join-Path $TARGET ".agents\$rel"

            if (Test-Path $dstFile) {
                $srcHash = (Get-FileHash $srcItem.FullName -Algorithm MD5).Hash
                $dstHash = (Get-FileHash $dstFile -Algorithm MD5).Hash
                if ($srcHash -eq $dstHash) {
                    continue
                }
                $summary = Get-ChangeSummary $srcItem.FullName $dstFile
                $pendingChanges += @{
                    File = ".agents/$rel"
                    Action = "update"
                    Added = $summary.Added
                    Removed = $summary.Removed
                    SrcFile = $srcItem.FullName
                    DstFile = $dstFile
                    IsCodexSkill = $false
                    IsRawTemplate = $true
                }
            }
            else {
                $srcLines = (Get-Content $srcItem.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
                $pendingChanges += @{
                    File = ".agents/$rel"
                    Action = "new"
                    Added = $srcLines
                    Removed = 0
                    SrcFile = $srcItem.FullName
                    DstFile = $dstFile
                    IsCodexSkill = $false
                    IsRawTemplate = $true
                }
            }
        }
    }

    Show-ChangeSummaryTable $pendingChanges

    if ($pendingChanges.Count -eq 0) {
        Write-Ok "No changes to apply."
        return
    }

    $applyAll = $false
    if ($Force) {
        $applyAll = $true
    }
    else {
        do {
            $choice = Read-Host "  Apply all changes? [Y/n/review]"
            $choice = $choice.Trim().ToLower()
        } while ($choice -notin @("", "y", "n", "review"))

        switch ($choice) {
            "" { $applyAll = $true }
            "y" { $applyAll = $true }
            "n" {
                Write-Host "  Aborted — no changes applied." -ForegroundColor Yellow
                return
            }
            "review" {
                $applyAll = $false
            }
        }
    }

    $accepted = 0
    $rejected = 0
    $skipped  = 0

    if ($applyAll) {
        foreach ($change in $pendingChanges) {
            if ($change.IsRawTemplate) {
                Copy-RawTemplateFile $change.SrcFile $change.DstFile
            }
            elseif ($change.IsCodexSkill) {
                Copy-CodexTemplateFile $change.SrcFile $change.DstFile $userLanguage
            }
            else {
                Copy-TemplateFile $change.SrcFile $change.DstFile $userLanguage
            }
            Write-Ok "Accepted: $($change.File)"
            $accepted++
        }
    }
    else {
        foreach ($change in $pendingChanges) {
            Write-Host ""
            Write-Host "--- $($change.File) ---" -ForegroundColor White
            if ($change.Action -eq "update") {
                Show-DiffSummary $change.SrcFile $change.DstFile
            }
            else {
                Write-Host "  [NEW FILE]" -ForegroundColor Yellow
            }

            do {
                $choice = Read-Host "  Accept (a), Reject (r), Skip (s), Diff (d)? [a/r/s/d]"
                if ($choice -eq "d" -or $choice -eq "D") {
                    Show-DiffFull $change.SrcFile $change.DstFile
                }
            } while ($choice -eq "d" -or $choice -eq "D")

            switch ($choice.ToLower()) {
                "a" {
                    if ($change.IsRawTemplate) {
                        Copy-RawTemplateFile $change.SrcFile $change.DstFile
                    }
                    elseif ($change.IsCodexSkill) {
                        Copy-CodexTemplateFile $change.SrcFile $change.DstFile $userLanguage
                    }
                    else {
                        Copy-TemplateFile $change.SrcFile $change.DstFile $userLanguage
                    }
                    Write-Ok "Accepted: $($change.File)"
                    $accepted++
                }
                "r" {
                    Write-Err "Rejected: $($change.File)"
                    $rejected++
                }
                default {
                    Write-Skip "Skipped: $($change.File)"
                    $skipped++
                }
            }
        }
    }

    if ($accepted -gt 0) {
        $dir = Split-Path $VERSION_STAMP_CODEX
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Set-Content -Path $VERSION_STAMP_CODEX -Value $FRAMEWORK_VERSION -Encoding UTF8
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
    Write-Ok "Framework update complete. Run 'ht update-init' in each project to apply changes."
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
    $normalizedAgent = $Agent.ToLowerInvariant()
    if ($normalizedAgent -eq "cascade") {
        Invoke-BootstrapCascade
    }
    elseif ($normalizedAgent -eq "codex") {
        Invoke-BootstrapCodex
    }
    else {
        Invoke-Bootstrap
    }
}
elseif ($Command -eq "update-init") {
    $normalizedAgent = $Agent.ToLowerInvariant()
    if ($normalizedAgent -eq "cascade") {
        Invoke-UpdateCascade -Force:$Force
    }
    elseif ($normalizedAgent -eq "codex") {
        Invoke-UpdateCodex -Force:$Force
    }
    else {
        Invoke-Update -Force:$Force
    }
}
elseif ($Command -eq "update") {
    Invoke-SelfUpdate
}
elseif ($Command -eq "self-update") {
    Write-Warn "'ht self-update' is deprecated. Use 'ht update' for framework updates."
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
