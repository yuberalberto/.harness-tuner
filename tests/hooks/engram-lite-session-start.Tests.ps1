#Requires -Modules Pester

<#
.SYNOPSIS
    Pester tests for templates-claude/hooks/engram-lite-session-start.ps1

.DESCRIPTION
    Covers:
      - Hook exits 0 on valid SessionStart payload
      - Hook outputs expected context instructions to stdout
      - Hook handles missing/empty payload gracefully
      - Hook handles malformed JSON without crashing
#>

$HooksDir = Split-Path -Path $PSScriptRoot
$RepoRoot = Split-Path -Path $HooksDir
$HookScript = Join-Path -Path $RepoRoot -ChildPath "templates-claude\hooks\engram-lite-session-start.ps1"

# Helper: invoke hook with payload via stdin and capture output + exit code
function Invoke-HookWithPayload {
    param([string]$Payload)

    $tmpScript = [System.IO.Path]::GetTempFileName() + ".ps1"
    $tmpPayload = [System.IO.Path]::GetTempFileName() + ".json"
    try {
        # Write payload to temp file
        Set-Content -Path $tmpPayload -Value $Payload -Encoding UTF8

        # Create shim script that pipes payload to hook
        $shim = @"
Get-Content '$($tmpPayload -replace "'", "''")' | & '$($HookScript -replace "'", "''")' *>&1
exit `$LASTEXITCODE
"@
        Set-Content -Path $tmpScript -Value $shim -Encoding UTF8
        $output = & pwsh -NoProfile -NonInteractive -File $tmpScript
        $exitCode = $LASTEXITCODE
        return @{ Output = $output; ExitCode = $exitCode }
    }
    finally {
        Remove-Item $tmpScript -ErrorAction SilentlyContinue
        Remove-Item $tmpPayload -ErrorAction SilentlyContinue
    }
}

Describe 'engram-lite-session-start hook — existence' {
    It 'should exist and be a PowerShell script' {
        Test-Path $HookScript | Should Be $true
        (Get-Item $HookScript).Extension | Should Be '.ps1'
    }

    It 'should be under 80 lines' {
        (Get-Content $HookScript | Measure-Object -Line).Lines | Should BeLessThan 80
    }
}

Describe 'engram-lite-session-start hook — with valid payload' {
    $payload = @{
        session_id = '12345-67890'
        cwd        = 'C:\Users\test\my-project'
        user       = @{ email = 'test@example.com' }
    } | ConvertTo-Json -Compress

    $result = Invoke-HookWithPayload -Payload $payload
    $output = $result.Output -join "`n"

    It 'should exit with code 0' {
        $result.ExitCode | Should Be 0
    }

    It 'should output memory protocol header' {
        $output | Should Match 'Engram-Lite Memory Protocol'
    }

    It 'should mention mem_context' {
        $output | Should Match 'mem_context'
    }

    It 'should indicate session start' {
        $output | Should Match 'Session Started'
    }

    It 'should extract project name from payload' {
        $output | Should Match 'my-project'
    }

    It 'should show working directory' {
        $output | Should Match 'working directory'
    }

    It 'should include session ID' {
        $output | Should Match '12345-67890'
    }
}

Describe 'engram-lite-session-start hook — with empty payload' {
    $result = Invoke-HookWithPayload -Payload ''
    $output = $result.Output -join "`n"

    It 'should exit with code 0' {
        $result.ExitCode | Should Be 0
    }

    It 'should still output memory protocol' {
        $output | Should Match 'Engram-Lite Memory Protocol'
    }

    It 'should use default project name' {
        $output | Should Match 'Project:'
    }
}

Describe 'engram-lite-session-start hook — with malformed JSON' {
    $result = Invoke-HookWithPayload -Payload '{ invalid json }'
    $output = $result.Output -join "`n"

    It 'should exit with code 0 (graceful degradation)' {
        $result.ExitCode | Should Be 0
    }

    It 'should still output memory protocol' {
        $output | Should Match 'Engram-Lite Memory Protocol'
    }
}

Describe 'engram-lite-session-start hook — with full payload' {
    $payload = @{
        session_id = 'session-abc-123'
        cwd        = 'C:\projects\harness-tuner'
        user       = @{
            email = 'developer@company.com'
            name  = 'Developer Name'
        }
    } | ConvertTo-Json -Compress

    $result = Invoke-HookWithPayload -Payload $payload
    $output = $result.Output -join "`n"

    It 'should exit with code 0' {
        $result.ExitCode | Should Be 0
    }

    It 'should extract full project name' {
        $output | Should Match 'harness-tuner'
    }

    It 'should include full session ID' {
        $output | Should Match 'session-abc-123'
    }
}

Describe 'engram-lite-session-start hook — output format' {
    $payload = @{
        session_id = 'test-session'
        cwd        = 'C:\test'
    } | ConvertTo-Json -Compress

    $result = Invoke-HookWithPayload -Payload $payload
    $output = $result.Output -join "`n"

    It 'should contain markdown headers' {
        $output | Should Match '##'
    }

    It 'should have clear instructions for Claude Code' {
        $output | Should Match 'Instruction to Claude'
    }

    It 'should be concise' {
        $lineCount = ($output -split "`n" | Where-Object { $_ -ne '' }).Count
        $lineCount | Should BeLessThan 20
    }
}

Describe 'engram-lite-session-start script structure' {
    $content = Get-Content $HookScript -Raw

    It 'should include error handling' {
        $content | Should Match 'ErrorActionPreference'
    }

    It 'should read from stdin' {
        $content | Should Match '\$input'
    }

    It 'should always exit 0' {
        $content | Should Match 'exit 0'
    }
}
