Describe 'engram-session-end Hook' {
  # Script under test
  $hookScript = Resolve-Path "$PSScriptRoot/../../templates/hooks/engram-session-end.ps1"

  Context 'Happy path: session end without prior summary save' {
    It 'should exit 0' {
      $mockPayload = @{
        eventType = 'Stop'
        sessionId = 'test-session-001'
      } | ConvertTo-Json

      # Test exit code directly
      & powershell -NoProfile -Command "Write-Host -NoNewline '$mockPayload' | & '$hookScript' > `$null 2>&1 ; `$LASTEXITCODE"
      $LASTEXITCODE | Should Be 0
    }

    It 'should output mem_session_summary invocation directive' {
      $mockPayload = @{
        eventType   = 'Stop'
        sessionId   = 'test-session-002'
        elapsedTime = 1234
      } | ConvertTo-Json

      $output = & powershell -NoProfile -Command "Write-Host -NoNewline '$mockPayload' | & '$hookScript' 2>&1"
      $output | Should Not BeNullOrEmpty
      ($output | Select-String 'hookSpecificOutput') | Should Not BeNullOrEmpty
      ($output | Select-String 'mem_session_summary') | Should Not BeNullOrEmpty
    }

    It 'should produce valid JSON output' {
      $mockPayload = @{
        eventType = 'Stop'
        sessionId = 'test-session-003'
      } | ConvertTo-Json

      $output = & powershell -NoProfile -Command "Write-Host -NoNewline '$mockPayload' | & '$hookScript' 2>&1"
      { $output | ConvertFrom-Json } | Should Not Throw
    }

    It 'should include requestMcpCall with engram tool' {
      $mockPayload = @{
        eventType = 'Stop'
        sessionId = 'test-session-004'
      } | ConvertTo-Json

      $output = & powershell -NoProfile -Command "Write-Host -NoNewline '$mockPayload' | & '$hookScript' 2>&1"
      # Output contains input payload and output JSON; just check for key strings
      ($output | Select-String 'hookSpecificOutput') | Should Not BeNullOrEmpty
      ($output | Select-String 'requestMcpCall') | Should Not BeNullOrEmpty
      ($output | Select-String '"tool":\s*"engram"') | Should Not BeNullOrEmpty
      ($output | Select-String '"call":\s*"mem_session_summary"') | Should Not BeNullOrEmpty
    }
  }

  Context 'Idempotency: summary already saved in session' {
    It 'should exit 0 when mem_session_summary_called flag is set' {
      $mockPayload = @{
        eventType      = 'Stop'
        sessionId      = 'test-session-005'
        sessionContext = @{
          mem_session_summary_called = $true
        }
      } | ConvertTo-Json

      & powershell -NoProfile -Command "Write-Host -NoNewline '$mockPayload' | & '$hookScript' > `$null 2>&1 ; `$LASTEXITCODE"
      $LASTEXITCODE | Should Be 0
    }

    It 'should not emit requestMcpCall when summary already saved (idempotent)' {
      $mockPayload = @{
        eventType      = 'Stop'
        sessionId      = 'test-session-006'
        sessionContext = @{
          mem_session_summary_called = $true
        }
      } | ConvertTo-Json

      $output = & powershell -NoProfile -Command "Write-Host -NoNewline '$mockPayload' | & '$hookScript' 2>&1"

      # Filter for actual JSON output (starts with { and ends with })
      # When idempotent, script exits without JSON output
      $hasJsonOutput = $output | Select-String '^\{[\s\S]*\}$' | Measure-Object | Select-Object -ExpandProperty Count
      $hasJsonOutput | Should Be 0
    }
  }

  Context 'Graceful degradation: malformed or missing input' {
    It 'should exit 0 on empty input' {
      & powershell -NoProfile -Command "`$null | & '$hookScript' > `$null 2>&1 ; `$LASTEXITCODE"
      $LASTEXITCODE | Should Be 0
    }

    It 'should exit 0 on invalid JSON and still emit directive (treat as not-yet-saved)' {
      $output = & powershell -NoProfile -Command "`@{ x = 'y' } | % { '{invalid' } | & '$hookScript' 2>&1"
      $LASTEXITCODE | Should Be 0
      ($output | Select-String 'mem_session_summary') | Should Not BeNullOrEmpty
    }
  }

  Context 'Edge cases' {
    It 'should handle Stop payload with extra fields' {
      $mockPayload = @{
        eventType     = 'Stop'
        sessionId     = 'test-session-007'
        timestamp     = [datetime]::UtcNow.ToString('o')
        exitCode      = 0
        agentModel    = 'claude-opus'
        tokenEstimate = 95000
      } | ConvertTo-Json

      $output = & powershell -NoProfile -Command "Write-Host -NoNewline '$mockPayload' | & '$hookScript' 2>&1"
      $LASTEXITCODE | Should Be 0
      $output | Should Not BeNullOrEmpty
    }

    It 'should handle null/empty sessionContext gracefully' {
      $mockPayload = @{
        eventType      = 'Stop'
        sessionId      = 'test-session-008'
        sessionContext = @{}
      } | ConvertTo-Json

      $output = & powershell -NoProfile -Command "Write-Host -NoNewline '$mockPayload' | & '$hookScript' 2>&1"
      $LASTEXITCODE | Should Be 0
      ($output | Select-String 'mem_session_summary') | Should Not BeNullOrEmpty
    }
  }
}
