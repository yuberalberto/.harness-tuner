#Requires -Modules Pester
<#
.SYNOPSIS
    Pester tests for harness-tuner.ps1

.DESCRIPTION
    Covers:
      - ht (no args) prints help summary
      - ht init in temp dir creates .claude/.harness-tuner-version
      - ht init aborts when marker already exists
      - ht init prompts on foreign .claude/ collision
      - ht update interactive flow (mocked Read-Host)
      - ht self-update calls git pull (mocked git)
#>

BeforeAll {
    $script:RepoRoot   = Split-Path $PSScriptRoot
    $script:MainScript = Join-Path $script:RepoRoot "harness-tuner.ps1"

    # Minimal templates/ stub used by all tests — mirrors the real structure.
    # Each test that needs a temp project sets $env:HARNESS_TUNER_TEST_HOME.
    function New-StubTemplates([string]$BaseDir) {
        $tplDir = Join-Path $BaseDir "templates"

        # rules/
        $rulesDir = Join-Path $tplDir "rules"
        New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null
        Set-Content -Path (Join-Path $rulesDir "identity.md") -Value "# Identity`nLanguage: {{USER_LANGUAGE}}" -Encoding UTF8
        Set-Content -Path (Join-Path $rulesDir "engram.md")   -Value "# Engram protocol" -Encoding UTF8

        # skills/
        $skillDir = Join-Path $tplDir "skills" "git-flow"
        New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
        Set-Content -Path (Join-Path $skillDir "SKILL.md") -Value "# git-flow skill" -Encoding UTF8

        # hooks/
        $hooksDir = Join-Path $tplDir "hooks"
        New-Item -ItemType Directory -Force -Path $hooksDir | Out-Null
        Set-Content -Path (Join-Path $hooksDir "format-post-edit.ps1") -Value "# format hook" -Encoding UTF8

        # settings.json
        $settingsJson = @'
{
  "hooks": [],
  "mcpServers": {},
  "permissions": { "allowedTools": ["Read(**)"] }
}
'@
        Set-Content -Path (Join-Path $tplDir "settings.json") -Value $settingsJson -Encoding UTF8

        # VERSION
        Set-Content -Path (Join-Path $BaseDir "VERSION") -Value "1.0.0" -Encoding UTF8

        return $tplDir
    }

    # Helper: run harness-tuner.ps1 with a synthetic HARNESS_TUNER_HOME and working dir.
    # Returns a hashtable: ExitCode, Output (string[]).
    function Invoke-HT {
        param(
            [string]   $HarnessHome,     # synthetic HARNESS_TUNER_HOME (must have templates/ + VERSION)
            [string]   $WorkDir,         # simulated project dir (cwd for the script)
            [string[]] $ScriptArgs = @(), # positional / named args passed to the script
            [string[]] $StdinLines = @()  # lines fed to Read-Host in order
        )

        # Build a wrapper that:
        #   1. Overrides $PSScriptRoot (not directly possible) — instead we
        #      wrap the script invocation in a child process that sets
        #      $script:HARNESS_TUNER_HOME before dot-sourcing the param block.
        #   2. Supplies stdin lines via here-string piped through pwsh.
        #
        # Strategy: serialize StdinLines as a JSON array, pass via env var,
        # and inject a tiny shim before the script runs in the child process.

        $stdinJson = $StdinLines | ConvertTo-Json -Compress

        # The shim sets up the HARNESS_TUNER_HOME override and mocks Read-Host.
        $shim = @"
`$ErrorActionPreference = 'Stop'
Set-Location '$($WorkDir -replace "'", "''")'

# Feed StdinLines to Read-Host by mocking it
`$script:_stdinLines = ('$($stdinJson -replace "'", "''")' | ConvertFrom-Json)
`$script:_stdinIdx   = 0
function global:Read-Host {
    param([string]`$Prompt = '')
    if (`$null -ne `$Prompt -and `$Prompt -ne '') { Write-Host "`$Prompt`: " -NoNewline }
    `$line = if (`$script:_stdinIdx -lt `$script:_stdinLines.Count) { `$script:_stdinLines[`$script:_stdinIdx] } else { '' }
    `$script:_stdinIdx++
    Write-Host `$line
    return `$line
}

# Override `$PSScriptRoot for the invoked script by wrapping it
function script:Get-HarnessHome { return '$($HarnessHome -replace "'", "''")' }

# Dot-source the script with overridden PSScriptRoot equivalent:
# We patch HARNESS_TUNER_HOME by re-declaring the variable before the script
# uses it. This works because the script assigns it from `$PSScriptRoot at top.
`$global:_HT_HOME_OVERRIDE = '$($HarnessHome -replace "'", "''")'

# Patch: execute script but intercept `$PSScriptRoot
`$scriptContent = Get-Content '$($script:MainScript -replace "'", "''")' -Raw
# Replace the PSScriptRoot assignment with our override
`$patched = `$scriptContent -replace '(?m)^\s*\`$HARNESS_TUNER_HOME\s*=\s*\`$PSScriptRoot', '`$HARNESS_TUNER_HOME = `$global:_HT_HOME_OVERRIDE'
`$sb = [scriptblock]::Create(`$patched)
& `$sb $($ScriptArgs -join ' ')
"@

        $tmpShim = [System.IO.Path]::GetTempFileName() + ".ps1"
        Set-Content -Path $tmpShim -Value $shim -Encoding UTF8

        try {
            $result = pwsh -NoProfile -NonInteractive -File $tmpShim 2>&1
            $exitCode = $LASTEXITCODE
        }
        finally {
            Remove-Item $tmpShim -ErrorAction SilentlyContinue
        }

        return @{ ExitCode = $exitCode; Output = $result }
    }
}

# ---------------------------------------------------------------------------
# Describe: Help output
# ---------------------------------------------------------------------------
Describe "harness-tuner.ps1 — help" {

    It "should print subcommand listing when called with no args" {
        $tempHome    = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())")
        $tempProject = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-proj-$([guid]::NewGuid())")
        New-StubTemplates $tempHome.FullName | Out-Null

        try {
            $r = Invoke-HT -HarnessHome $tempHome.FullName -WorkDir $tempProject.FullName -ScriptArgs @()
            $out = $r.Output -join "`n"

            $out | Should -Match "harness-tuner"
            $out | Should -Match "ht init"
            $out | Should -Match "ht update"
            $out | Should -Match "ht self-update"
        }
        finally {
            Remove-Item -Recurse -Force $tempHome.FullName    -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $tempProject.FullName -ErrorAction SilentlyContinue
        }
    }

    It "should print detailed help with --help flag" {
        $tempHome    = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())")
        $tempProject = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-proj-$([guid]::NewGuid())")
        New-StubTemplates $tempHome.FullName | Out-Null

        try {
            $r = Invoke-HT -HarnessHome $tempHome.FullName -WorkDir $tempProject.FullName -ScriptArgs @("--help")
            $out = $r.Output -join "`n"

            $out | Should -Match "SUBCOMMAND DETAILS"
            $out | Should -Match "HARNESS_TUNER_HOME"
        }
        finally {
            Remove-Item -Recurse -Force $tempHome.FullName    -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $tempProject.FullName -ErrorAction SilentlyContinue
        }
    }
}

# ---------------------------------------------------------------------------
# Describe: ht init — clean bootstrap
# ---------------------------------------------------------------------------
Describe "harness-tuner.ps1 — ht init (clean project)" {

    It "should create .claude/.harness-tuner-version in a fresh project" {
        $tempHome    = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())")
        $tempProject = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-proj-$([guid]::NewGuid())")
        New-StubTemplates $tempHome.FullName | Out-Null

        try {
            $r = Invoke-HT `
                -HarnessHome $tempHome.FullName `
                -WorkDir     $tempProject.FullName `
                -ScriptArgs  @("init", "-Language", "Spanish") `
                -StdinLines  @()

            $marker = Join-Path $tempProject.FullName ".claude" ".harness-tuner-version"
            Test-Path $marker | Should -Be $true
            (Get-Content $marker -Raw).Trim() | Should -Be "1.0.0"
        }
        finally {
            Remove-Item -Recurse -Force $tempHome.FullName    -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $tempProject.FullName -ErrorAction SilentlyContinue
        }
    }

    It "should copy template files into .claude/" {
        $tempHome    = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())")
        $tempProject = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-proj-$([guid]::NewGuid())")
        New-StubTemplates $tempHome.FullName | Out-Null

        try {
            Invoke-HT `
                -HarnessHome $tempHome.FullName `
                -WorkDir     $tempProject.FullName `
                -ScriptArgs  @("init", "-Language", "English") `
                -StdinLines  @() | Out-Null

            $claudeDir = Join-Path $tempProject.FullName ".claude"
            Test-Path (Join-Path $claudeDir "rules" "identity.md") | Should -Be $true
            Test-Path (Join-Path $claudeDir "rules" "engram.md")   | Should -Be $true
            Test-Path (Join-Path $claudeDir "skills" "git-flow" "SKILL.md") | Should -Be $true
            Test-Path (Join-Path $claudeDir "hooks" "format-post-edit.ps1") | Should -Be $true
        }
        finally {
            Remove-Item -Recurse -Force $tempHome.FullName    -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $tempProject.FullName -ErrorAction SilentlyContinue
        }
    }

    It "should interpolate USER_LANGUAGE in identity.md" {
        $tempHome    = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())")
        $tempProject = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-proj-$([guid]::NewGuid())")
        New-StubTemplates $tempHome.FullName | Out-Null

        try {
            Invoke-HT `
                -HarnessHome $tempHome.FullName `
                -WorkDir     $tempProject.FullName `
                -ScriptArgs  @("init", "-Language", "French") `
                -StdinLines  @() | Out-Null

            $identityPath = Join-Path $tempProject.FullName ".claude" "rules" "identity.md"
            $content = Get-Content $identityPath -Raw
            $content | Should -Match "French"
            $content | Should -Not -Match [regex]::Escape("{{USER_LANGUAGE}}")
        }
        finally {
            Remove-Item -Recurse -Force $tempHome.FullName    -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $tempProject.FullName -ErrorAction SilentlyContinue
        }
    }
}

# ---------------------------------------------------------------------------
# Describe: ht init — marker already exists (abort)
# ---------------------------------------------------------------------------
Describe "harness-tuner.ps1 — ht init (already installed)" {

    It "should abort with non-zero exit code when .harness-tuner-version exists" {
        $tempHome    = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())")
        $tempProject = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-proj-$([guid]::NewGuid())")
        New-StubTemplates $tempHome.FullName | Out-Null

        # Pre-create the marker
        $claudeDir = Join-Path $tempProject.FullName ".claude"
        New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
        Set-Content -Path (Join-Path $claudeDir ".harness-tuner-version") -Value "1.0.0" -Encoding UTF8

        try {
            $r = Invoke-HT `
                -HarnessHome $tempHome.FullName `
                -WorkDir     $tempProject.FullName `
                -ScriptArgs  @("init", "-Language", "English") `
                -StdinLines  @()

            $r.ExitCode | Should -Not -Be 0
            $out = $r.Output -join "`n"
            $out | Should -Match "Already installed"
            $out | Should -Match "ht update"
        }
        finally {
            Remove-Item -Recurse -Force $tempHome.FullName    -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $tempProject.FullName -ErrorAction SilentlyContinue
        }
    }
}

# ---------------------------------------------------------------------------
# Describe: ht init — foreign .claude/ collision prompts
# ---------------------------------------------------------------------------
Describe "harness-tuner.ps1 — ht init (foreign .claude/ coexistence)" {

    It "should warn about foreign .claude/ and prompt on collision" {
        $tempHome    = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())")
        $tempProject = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-proj-$([guid]::NewGuid())")
        New-StubTemplates $tempHome.FullName | Out-Null

        # Create a foreign .claude/ with a colliding file — no version marker
        $claudeDir = Join-Path $tempProject.FullName ".claude"
        $rulesDir  = Join-Path $claudeDir "rules"
        New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null
        Set-Content -Path (Join-Path $rulesDir "identity.md") -Value "# Old identity" -Encoding UTF8

        try {
            # Answer "a" (accept) for every collision prompt
            $r = Invoke-HT `
                -HarnessHome $tempHome.FullName `
                -WorkDir     $tempProject.FullName `
                -ScriptArgs  @("init", "-Language", "English") `
                -StdinLines  @("a", "a", "a", "a", "a", "a")

            $out = $r.Output -join "`n"
            $out | Should -Match "Foreign .claude/"

            # Marker should still be written
            $marker = Join-Path $claudeDir ".harness-tuner-version"
            Test-Path $marker | Should -Be $true
        }
        finally {
            Remove-Item -Recurse -Force $tempHome.FullName    -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $tempProject.FullName -ErrorAction SilentlyContinue
        }
    }

    It "should write version marker even when some files are rejected" {
        $tempHome    = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())")
        $tempProject = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-proj-$([guid]::NewGuid())")
        New-StubTemplates $tempHome.FullName | Out-Null

        $claudeDir = Join-Path $tempProject.FullName ".claude"
        $rulesDir  = Join-Path $claudeDir "rules"
        New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null
        Set-Content -Path (Join-Path $rulesDir "identity.md") -Value "# Old identity" -Encoding UTF8

        try {
            # Reject the colliding file, accept others
            $r = Invoke-HT `
                -HarnessHome $tempHome.FullName `
                -WorkDir     $tempProject.FullName `
                -ScriptArgs  @("init", "-Language", "English") `
                -StdinLines  @("r", "a", "a", "a", "a", "a")

            $marker = Join-Path $claudeDir ".harness-tuner-version"
            Test-Path $marker | Should -Be $true

            # Rejected file should NOT have been overwritten
            $identityContent = Get-Content (Join-Path $rulesDir "identity.md") -Raw
            $identityContent | Should -Match "Old identity"
        }
        finally {
            Remove-Item -Recurse -Force $tempHome.FullName    -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $tempProject.FullName -ErrorAction SilentlyContinue
        }
    }
}

# ---------------------------------------------------------------------------
# Describe: ht update — interactive flow
# ---------------------------------------------------------------------------
Describe "harness-tuner.ps1 — ht update (interactive)" {

    It "should stamp new version when a file is accepted" {
        $tempHome    = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())")
        $tempProject = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-proj-$([guid]::NewGuid())")
        New-StubTemplates $tempHome.FullName | Out-Null

        # Set up a project that is "installed" with an older version
        $claudeDir = Join-Path $tempProject.FullName ".claude"
        $rulesDir  = Join-Path $claudeDir "rules"
        $skillDir  = Join-Path $claudeDir "skills" "git-flow"
        $hooksDir  = Join-Path $claudeDir "hooks"
        New-Item -ItemType Directory -Force -Path $rulesDir  | Out-Null
        New-Item -ItemType Directory -Force -Path $skillDir  | Out-Null
        New-Item -ItemType Directory -Force -Path $hooksDir  | Out-Null

        # Slightly different content to trigger diff detection
        Set-Content -Path (Join-Path $rulesDir "identity.md")           -Value "# Old identity" -Encoding UTF8
        Set-Content -Path (Join-Path $rulesDir "engram.md")             -Value "# Engram protocol" -Encoding UTF8
        Set-Content -Path (Join-Path $skillDir "SKILL.md")              -Value "# git-flow skill" -Encoding UTF8
        Set-Content -Path (Join-Path $hooksDir "format-post-edit.ps1")  -Value "# format hook" -Encoding UTF8

        Set-Content -Path (Join-Path $claudeDir ".harness-tuner-version") -Value "0.9.0" -Encoding UTF8

        try {
            # Accept first file (identity.md), skip rest, accept settings.json
            $r = Invoke-HT `
                -HarnessHome $tempHome.FullName `
                -WorkDir     $tempProject.FullName `
                -ScriptArgs  @("update") `
                -StdinLines  @("a", "s", "s", "s", "a")

            $out = $r.Output -join "`n"
            $out | Should -Match "Accepted"

            $marker = Get-Content (Join-Path $claudeDir ".harness-tuner-version") -Raw
            $marker.Trim() | Should -Be "1.0.0"
        }
        finally {
            Remove-Item -Recurse -Force $tempHome.FullName    -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $tempProject.FullName -ErrorAction SilentlyContinue
        }
    }

    It "should not stamp version when all files are skipped or rejected" {
        $tempHome    = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())")
        $tempProject = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-proj-$([guid]::NewGuid())")
        New-StubTemplates $tempHome.FullName | Out-Null

        $claudeDir = Join-Path $tempProject.FullName ".claude"
        $rulesDir  = Join-Path $claudeDir "rules"
        New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null
        Set-Content -Path (Join-Path $rulesDir "identity.md") -Value "# Old identity" -Encoding UTF8
        Set-Content -Path (Join-Path $claudeDir ".harness-tuner-version") -Value "0.9.0" -Encoding UTF8

        try {
            # Reject / skip everything
            $r = Invoke-HT `
                -HarnessHome $tempHome.FullName `
                -WorkDir     $tempProject.FullName `
                -ScriptArgs  @("update") `
                -StdinLines  @("r", "s", "s", "s", "s")

            $marker = Get-Content (Join-Path $claudeDir ".harness-tuner-version") -Raw
            $marker.Trim() | Should -Be "0.9.0"   # unchanged
        }
        finally {
            Remove-Item -Recurse -Force $tempHome.FullName    -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $tempProject.FullName -ErrorAction SilentlyContinue
        }
    }

    It "should abort when .claude/ does not exist" {
        $tempHome    = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())")
        $tempProject = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-proj-$([guid]::NewGuid())")
        New-StubTemplates $tempHome.FullName | Out-Null

        try {
            $r = Invoke-HT `
                -HarnessHome $tempHome.FullName `
                -WorkDir     $tempProject.FullName `
                -ScriptArgs  @("update") `
                -StdinLines  @()

            $r.ExitCode | Should -Not -Be 0
            ($r.Output -join "`n") | Should -Match "ht init"
        }
        finally {
            Remove-Item -Recurse -Force $tempHome.FullName    -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $tempProject.FullName -ErrorAction SilentlyContinue
        }
    }
}

# ---------------------------------------------------------------------------
# Describe: ht self-update — calls git pull
# ---------------------------------------------------------------------------
Describe "harness-tuner.ps1 — ht self-update" {

    It "should invoke git pull and print output" {
        $tempHome    = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())")
        $tempProject = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-proj-$([guid]::NewGuid())")
        New-StubTemplates $tempHome.FullName | Out-Null

        # Initialize a bare git repo so "git pull origin main" has something to run against
        # (it will fail on network, but we just need to confirm git was invoked)
        Push-Location $tempHome.FullName
        try {
            git init --quiet 2>&1 | Out-Null
            git remote add origin "https://github.com/example/harness-tuner.git" 2>&1 | Out-Null
        }
        finally { Pop-Location }

        try {
            $r = Invoke-HT `
                -HarnessHome $tempHome.FullName `
                -WorkDir     $tempProject.FullName `
                -ScriptArgs  @("self-update") `
                -StdinLines  @()

            $out = $r.Output -join "`n"
            # git pull was attempted (output may include "fatal" due to network, that's expected in test)
            $out | Should -Match "(Self-update|pull|origin|fatal|error)" -Because "git pull was invoked"
        }
        finally {
            Remove-Item -Recurse -Force $tempHome.FullName    -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $tempProject.FullName -ErrorAction SilentlyContinue
        }
    }
}

# ---------------------------------------------------------------------------
# Describe: legacy .windsurf/ is ignored silently
# ---------------------------------------------------------------------------
Describe "harness-tuner.ps1 — legacy .windsurf/ ignored" {

    It "should complete init without error when .windsurf/ exists" {
        $tempHome    = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())")
        $tempProject = New-Item -ItemType Directory -Force -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-proj-$([guid]::NewGuid())")
        New-StubTemplates $tempHome.FullName | Out-Null

        # Create legacy .windsurf/ directory
        New-Item -ItemType Directory -Force -Path (Join-Path $tempProject.FullName ".windsurf" "rules") | Out-Null

        try {
            $r = Invoke-HT `
                -HarnessHome $tempHome.FullName `
                -WorkDir     $tempProject.FullName `
                -ScriptArgs  @("init", "-Language", "English") `
                -StdinLines  @()

            $r.ExitCode | Should -Be 0
            $marker = Join-Path $tempProject.FullName ".claude" ".harness-tuner-version"
            Test-Path $marker | Should -Be $true
        }
        finally {
            Remove-Item -Recurse -Force $tempHome.FullName    -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $tempProject.FullName -ErrorAction SilentlyContinue
        }
    }
}
