<#
.SYNOPSIS
Pester tests for templates-claude/hooks/git-guardrails-pre-bash.ps1

.DESCRIPTION
Covers:
  - Force-push variants             -> blocked (exit 2, decision:block JSON)
  - Push to protected branches      -> blocked unless ALLOW_PROTECTED=1
  - git reset --hard                -> blocked
  - git clean -f / -fd / -fdx      -> blocked
  - git checkout . / restore .      -> blocked
  - git branch -D                   -> blocked
  - git commit --no-verify etc.     -> blocked
  - git status, git diff            -> allowed (exit 0, no stdout)
  - git commit -m "msg"             -> allowed
  - git push to non-protected branch -> allowed
  - ALLOW_PROTECTED=1               -> push to main allowed

Compatible with Pester v3 (no BeforeAll).
#>

# ---- Script-level setup -------------------------------------------------------
$script:HookScript = Resolve-Path "$PSScriptRoot/../../templates-claude/hooks/git-guardrails-pre-bash.ps1"

# Helper: run the hook with a given Bash command string piped as a PreToolUse
# JSON payload. Optionally set extra env vars (as hashtable).
# Returns hashtable: ExitCode, Stdout (string), StdoutJson (parsed or $null).
function Invoke-Hook {
    param(
        [string]   $Command,
        [hashtable]$Env = @{}
    )

    $payload = @{
        hook_event_name = 'PreToolUse'
        tool_name       = 'Bash'
        tool_input      = @{ command = $Command }
    } | ConvertTo-Json -Compress

    # Escape single-quotes for safe embedding inside a pwsh -Command string
    $payloadEsc = $payload -replace "'", "''"

    $envSetup   = ''
    $envCleanup = ''
    foreach ($kv in $Env.GetEnumerator()) {
        $val         = $kv.Value -replace "'", "''"
        $envSetup   += "`$env:$($kv.Key) = '$val'`n"
        $envCleanup += "if (Test-Path Env:$($kv.Key)) { Remove-Item Env:$($kv.Key) }`n"
    }

    # Write the payload to a temp file, then pipe it into the hook via -File
    # (matching how Claude Code invokes hooks: stdin = event JSON).
    # We use a wrapper script that sets env vars, pipes payload, captures output.
    $psCmd = @"
$envSetup
`$result = '$payloadEsc' | pwsh -NoProfile -NonInteractive -File '$($script:HookScript -replace "'","''")'
`$ec = `$LASTEXITCODE
Write-Output `$result
$envCleanup
exit `$ec
"@

    $tmp = [System.IO.Path]::GetTempFileName() + '.ps1'
    [System.IO.File]::WriteAllText($tmp, $psCmd, [System.Text.Encoding]::UTF8)

    try {
        $stdout   = pwsh -NoProfile -NonInteractive -File $tmp 2>$null
        $exitCode = $LASTEXITCODE
    }
    finally {
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }

    $stdoutStr = if ($stdout -is [array]) { $stdout -join "`n" } else { "$stdout" }
    $parsed    = $null
    try { $parsed = $stdoutStr.Trim() | ConvertFrom-Json -ErrorAction Stop } catch { }

    return @{
        ExitCode   = $exitCode
        Stdout     = $stdoutStr.Trim()
        StdoutJson = $parsed
    }
}

# ===========================================================================
# Blocked commands
# ===========================================================================

Describe 'git-guardrails-pre-bash — force-push blocked' {

    It 'git push --force origin main should block' {
        $r = Invoke-Hook -Command 'git push --force origin main'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
        $r.StdoutJson.reason   | Should Match 'force'
    }

    It 'git push -f origin main should block (short flag)' {
        $r = Invoke-Hook -Command 'git push -f origin main'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }

    It 'git push origin main --force should block (flag at end)' {
        $r = Invoke-Hook -Command 'git push origin main --force'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }

    It 'git push --force-with-lease should block' {
        $r = Invoke-Hook -Command 'git push --force-with-lease origin feature/foo'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }
}

Describe 'git-guardrails-pre-bash — protected branch push blocked' {

    It 'git push origin main should block (protected branch)' {
        $r = Invoke-Hook -Command 'git push origin main'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
        $r.StdoutJson.reason   | Should Match 'protected'
    }

    It 'git push origin master should block (protected branch)' {
        $r = Invoke-Hook -Command 'git push origin master'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }

    It 'git push origin main should allow when ALLOW_PROTECTED=1' {
        $r = Invoke-Hook -Command 'git push origin main' -Env @{ ALLOW_PROTECTED = '1' }
        $r.ExitCode | Should Be 0
        $r.Stdout   | Should BeNullOrEmpty
    }
}

Describe 'git-guardrails-pre-bash — destructive reset/clean blocked' {

    It 'git reset --hard should block' {
        $r = Invoke-Hook -Command 'git reset --hard'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
        $r.StdoutJson.reason   | Should Match 'reset'
    }

    It 'git reset --hard HEAD~1 should block' {
        $r = Invoke-Hook -Command 'git reset --hard HEAD~1'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }

    It 'git clean -f should block' {
        $r = Invoke-Hook -Command 'git clean -f'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }

    It 'git clean -fd should block' {
        $r = Invoke-Hook -Command 'git clean -fd'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }

    It 'git clean -fdx should block' {
        $r = Invoke-Hook -Command 'git clean -fdx'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }
}

Describe 'git-guardrails-pre-bash — mass working-tree discard blocked' {

    It 'git checkout . should block' {
        $r = Invoke-Hook -Command 'git checkout .'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }

    It 'git restore . should block' {
        $r = Invoke-Hook -Command 'git restore .'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }
}

Describe 'git-guardrails-pre-bash — force branch delete blocked' {

    It 'git branch -D feature/old should block' {
        $r = Invoke-Hook -Command 'git branch -D feature/old'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }
}

Describe 'git-guardrails-pre-bash — commit hook/signing bypass blocked' {

    It 'git commit --no-verify should block' {
        $r = Invoke-Hook -Command 'git commit --no-verify -m "msg"'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }

    It 'git commit --no-gpg-sign should block' {
        $r = Invoke-Hook -Command 'git commit --no-gpg-sign -m "msg"'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }

    It 'git commit -c commit.gpgsign=false should block' {
        $r = Invoke-Hook -Command 'git commit -c commit.gpgsign=false -m "msg"'
        $r.ExitCode            | Should Not Be 0
        $r.StdoutJson.decision | Should Be 'block'
    }
}

# ===========================================================================
# Allowed commands
# ===========================================================================

Describe 'git-guardrails-pre-bash — allowed commands pass through' {

    It 'git status should allow' {
        $r = Invoke-Hook -Command 'git status'
        $r.ExitCode | Should Be 0
        $r.Stdout   | Should BeNullOrEmpty
    }

    It 'git diff should allow' {
        $r = Invoke-Hook -Command 'git diff'
        $r.ExitCode | Should Be 0
        $r.Stdout   | Should BeNullOrEmpty
    }

    It 'git commit -m "msg" should allow (normal commit)' {
        $r = Invoke-Hook -Command 'git commit -m "fix: update readme"'
        $r.ExitCode | Should Be 0
        $r.Stdout   | Should BeNullOrEmpty
    }

    It 'git push origin feature/foo should allow (non-protected branch)' {
        $r = Invoke-Hook -Command 'git push origin feature/foo'
        $r.ExitCode | Should Be 0
        $r.Stdout   | Should BeNullOrEmpty
    }

    It 'git push origin feature/main-refactor should allow (main as substring only)' {
        $r = Invoke-Hook -Command 'git push origin feature/main-refactor'
        $r.ExitCode | Should Be 0
        $r.Stdout   | Should BeNullOrEmpty
    }

    It 'git log --oneline should allow' {
        $r = Invoke-Hook -Command 'git log --oneline'
        $r.ExitCode | Should Be 0
        $r.Stdout   | Should BeNullOrEmpty
    }

    It 'git stash should allow' {
        $r = Invoke-Hook -Command 'git stash'
        $r.ExitCode | Should Be 0
        $r.Stdout   | Should BeNullOrEmpty
    }

    It 'git checkout feature/foo should allow (branch checkout, not mass discard)' {
        $r = Invoke-Hook -Command 'git checkout feature/foo'
        $r.ExitCode | Should Be 0
        $r.Stdout   | Should BeNullOrEmpty
    }

    It 'git branch -d feature/old should allow (safe lowercase -d delete)' {
        $r = Invoke-Hook -Command 'git branch -d feature/old'
        $r.ExitCode | Should Be 0
        $r.Stdout   | Should BeNullOrEmpty
    }

    It 'npm install should allow (non-git command)' {
        $r = Invoke-Hook -Command 'npm install'
        $r.ExitCode | Should Be 0
        $r.Stdout   | Should BeNullOrEmpty
    }
}

# ===========================================================================
# Output format contract
# ===========================================================================

Describe 'git-guardrails-pre-bash — output format contract' {

    It 'blocked command should emit valid JSON with decision and reason' {
        $r = Invoke-Hook -Command 'git push --force origin main'
        { $r.Stdout | ConvertFrom-Json -ErrorAction Stop } | Should Not Throw
        $r.StdoutJson.decision | Should Not BeNullOrEmpty
        $r.StdoutJson.reason   | Should Not BeNullOrEmpty
    }

    It 'allowed command should produce no stdout' {
        $r = Invoke-Hook -Command 'git status'
        $r.Stdout | Should BeNullOrEmpty
    }

    It 'malformed JSON stdin should degrade gracefully and allow (exit 0)' {
        $tmp = [System.IO.Path]::GetTempFileName() + '.ps1'
        [System.IO.File]::WriteAllText(
            $tmp,
            "Write-Output 'not-json' | & '$($script:HookScript -replace "'","''")'",
            [System.Text.Encoding]::UTF8
        )
        try {
            pwsh -NoProfile -NonInteractive -File $tmp 2>$null | Out-Null
            $LASTEXITCODE | Should Be 0
        }
        finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
    }

    It 'empty stdin should allow (exit 0)' {
        $tmp = [System.IO.Path]::GetTempFileName() + '.ps1'
        [System.IO.File]::WriteAllText(
            $tmp,
            "Write-Output '' | & '$($script:HookScript -replace "'","''")'",
            [System.Text.Encoding]::UTF8
        )
        try {
            pwsh -NoProfile -NonInteractive -File $tmp 2>$null | Out-Null
            $LASTEXITCODE | Should Be 0
        }
        finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
    }
}
