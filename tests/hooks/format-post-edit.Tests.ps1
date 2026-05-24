#Requires -Modules Pester
<#
.SYNOPSIS
    Pester tests for templates/hooks/format-post-edit.ps1

.DESCRIPTION
    Tests cover:
      - JS / TS / JSON / MD file  -> prettier is invoked
      - Python file               -> ruff is invoked (preferred); black as fallback
      - Unknown extension (.xyz)  -> silent no-op, no formatter invoked
      - Missing formatter binary  -> warning on stderr, exit 0 (no crash)
      - NotebookEdit payload      -> notebook_path field is used
      - Empty / malformed payload -> exit 0 gracefully

    Mocking strategy
    ----------------
    Each test runs the hook in a child pwsh process. A shim script is generated
    that:

      1. Overrides Get-Command (global function) so it returns a fake object
         (or $null) for the binary names the hook will look up.
      2. Overrides Start-Process (global function) so it records invocations
         to a shared temp JSON file instead of launching any real binary.
      3. Pipes the JSON payload string to the hook script via stdin (echo |).

    After the child exits, the parent reads the invocation record + exit code +
    stderr and asserts against them.

    Why a child process rather than in-process mocking
    ---------------------------------------------------
    The hook script uses Set-StrictMode and assigns $ErrorActionPreference at
    script scope.  Dot-sourcing it inside the Pester process contaminates
    global scope.  A child process gives full isolation.
#>

BeforeAll {
    $script:RepoRoot = Split-Path (Split-Path $PSScriptRoot)
    $script:HookPath = Join-Path $script:RepoRoot "templates" "hooks" "format-post-edit.ps1"

    # -----------------------------------------------------------------------
    # Build a Claude Code PostToolUse payload JSON string.
    # -----------------------------------------------------------------------
    function New-Payload {
        param(
            [string] $ToolName     = 'Edit',
            [string] $FilePath     = 'C:\project\src\index.js',
            [string] $NotebookPath = $null
        )

        if ($ToolName -eq 'NotebookEdit') {
            return [PSCustomObject]@{
                tool_name  = $ToolName
                tool_input = [PSCustomObject]@{ notebook_path = $NotebookPath }
            } | ConvertTo-Json -Compress
        }

        return [PSCustomObject]@{
            tool_name  = $ToolName
            tool_input = [PSCustomObject]@{ file_path = $FilePath }
        } | ConvertTo-Json -Compress
    }

    # -----------------------------------------------------------------------
    # Run format-post-edit.ps1 in an isolated child pwsh process.
    #
    # The child process:
    #   - loads a generated shim that overrides Get-Command / Start-Process
    #   - then dot-sources the hook, piping $PayloadJson via stdin
    #
    # Returns @{ ExitCode; Stdout; Stderr; Invocations }
    #   Invocations: array of @{ FilePath; ArgumentList } recorded by mock
    # -----------------------------------------------------------------------
    function Invoke-Hook {
        param(
            [string] $PayloadJson,
            # Path returned by mocked Get-Command for generic formatters.
            # Pass '' or $null to simulate "binary not found".
            [string] $FakeCommandPath = 'C:\fake\prettier.cmd',
            # Override for ruff specifically (Python dispatch)
            [string] $FakeRuffPath    = '',
            # Override for black specifically (Python fallback)
            [string] $FakeBlackPath   = ''
        )

        # Temp file stores Start-Process call records as JSON array.
        $invFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $invFile -Value '[]' -Encoding UTF8

        # Escape single-quotes for embedding inside PowerShell single-quoted strings.
        function q([string]$s) { $s -replace "'", "''" }

        $hookEsc    = q $script:HookPath
        $invFileEsc = q $invFile
        $fakeEsc    = if ($FakeCommandPath) { q $FakeCommandPath } else { '' }
        $ruffEsc    = if ($FakeRuffPath)    { q $FakeRuffPath    } else { '' }
        $blackEsc   = if ($FakeBlackPath)   { q $FakeBlackPath   } else { '' }

        # The shim injects mocks then dot-sources the hook.
        # Stdin for the hook comes from the pipeline set up by the wrapper
        # command below (echo $payload | pwsh -Command ...).
        $shim = @"
Set-StrictMode -Off
`$ErrorActionPreference = 'Continue'

# ---- Override Get-Command ----
function global:Get-Command {
    param([string]`$Name, [string]`$ErrorAction = 'Stop')

    `$ruffPath  = '$ruffEsc'
    `$blackPath = '$blackEsc'
    `$fakePath  = '$fakeEsc'

    if (`$Name -eq 'ruff') {
        if (`$ruffPath  -ne '') { return [PSCustomObject]@{ Source = `$ruffPath  } }
        return `$null
    }
    if (`$Name -eq 'black') {
        if (`$blackPath -ne '') { return [PSCustomObject]@{ Source = `$blackPath } }
        return `$null
    }
    # All other binaries (prettier, gofmt, rustfmt …)
    if (`$fakePath -ne '') { return [PSCustomObject]@{ Source = `$fakePath } }
    return `$null
}

# ---- Override Start-Process ----
# Records calls to a JSON file; returns a fake process with ExitCode=0.
function global:Start-Process {
    param(
        [string]  `$FilePath,
        [string[]]`$ArgumentList,
        [switch]  `$Wait,
        [switch]  `$NoNewWindow,
        [switch]  `$PassThru,
        [string]  `$RedirectStandardOutput,
        [string]  `$RedirectStandardError
    )
    # Write stub temp files so Remove-Item in hook doesn't fail.
    if (`$RedirectStandardOutput) { New-Item -Force -Path `$RedirectStandardOutput | Out-Null }
    if (`$RedirectStandardError)  { New-Item -Force -Path `$RedirectStandardError  | Out-Null }

    `$record  = [PSCustomObject]@{ FilePath = `$FilePath; ArgumentList = `$ArgumentList }
    `$existing = (Get-Content '$invFileEsc' -Raw) | ConvertFrom-Json
    `$list   = @(`$existing) + `$record
    `$list | ConvertTo-Json -Depth 5 | Set-Content '$invFileEsc' -Encoding UTF8

    return [PSCustomObject]@{ ExitCode = 0 }
}

# ---- Dot-source the hook (stdin is inherited from the parent pipeline) ----
. '$hookEsc'
"@

        $shimFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        Set-Content -Path $shimFile -Value $shim -Encoding UTF8

        $stdoutFile = [System.IO.Path]::GetTempFileName()
        $stderrFile = [System.IO.Path]::GetTempFileName()

        # Build the payload line to echo into the child process.
        # We use a temp file to avoid quoting hell with arbitrary JSON.
        $payloadFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $payloadFile -Value $PayloadJson -Encoding UTF8

        try {
            # Cat the payload file to stdin of the shim via cmd /c type pipe.
            # Using cmd here keeps the pipe simple and avoids PowerShell quoting issues.
            $proc = Start-Process cmd `
                -ArgumentList @('/c', "type `"$payloadFile`" | pwsh -NoProfile -NonInteractive -File `"$shimFile`"") `
                -Wait `
                -NoNewWindow `
                -PassThru `
                -RedirectStandardOutput $stdoutFile `
                -RedirectStandardError  $stderrFile

            $exitCode = $proc.ExitCode
            $stdout   = Get-Content $stdoutFile -Raw -ErrorAction SilentlyContinue
            $stderr   = Get-Content $stderrFile  -Raw -ErrorAction SilentlyContinue
            $rawInv   = Get-Content $invFile     -Raw -ErrorAction SilentlyContinue
            $invocations = if ($rawInv -and $rawInv.Trim() -ne '[]') {
                @($rawInv | ConvertFrom-Json)
            } else {
                @()
            }
        } finally {
            Remove-Item $shimFile    -ErrorAction SilentlyContinue
            Remove-Item $stdoutFile  -ErrorAction SilentlyContinue
            Remove-Item $stderrFile  -ErrorAction SilentlyContinue
            Remove-Item $payloadFile -ErrorAction SilentlyContinue
            Remove-Item $invFile     -ErrorAction SilentlyContinue
        }

        return @{
            ExitCode    = $exitCode
            Stdout      = $stdout
            Stderr      = $stderr
            Invocations = $invocations
        }
    }
}

# ===========================================================================
# Describe: JS / TS / JSON / MD -> prettier
# ===========================================================================
Describe "format-post-edit — prettier dispatch" {

    It "hook__should_invoke_prettier__when_file_extension_is_js" {
        $payload = New-Payload -ToolName 'Edit' -FilePath 'C:\project\src\app.js'
        $r = Invoke-Hook -PayloadJson $payload -FakeCommandPath 'C:\fake\prettier.cmd'

        $r.ExitCode              | Should -Be 0
        $r.Invocations.Count     | Should -Be 1
        $r.Invocations[0].FilePath       | Should -Match 'prettier'
        $r.Invocations[0].ArgumentList   | Should -Contain '--write'
        $r.Invocations[0].ArgumentList   | Should -Contain 'C:\project\src\app.js'
    }

    It "hook__should_invoke_prettier__when_file_extension_is_ts" {
        $payload = New-Payload -ToolName 'Write' -FilePath 'C:\project\src\types.ts'
        $r = Invoke-Hook -PayloadJson $payload -FakeCommandPath 'C:\fake\prettier.cmd'

        $r.ExitCode          | Should -Be 0
        $r.Invocations.Count | Should -Be 1
        $r.Invocations[0].ArgumentList | Should -Contain 'C:\project\src\types.ts'
    }

    It "hook__should_invoke_prettier__when_file_extension_is_json" {
        $payload = New-Payload -ToolName 'Edit' -FilePath 'C:\project\package.json'
        $r = Invoke-Hook -PayloadJson $payload -FakeCommandPath 'C:\fake\prettier.cmd'

        $r.ExitCode          | Should -Be 0
        $r.Invocations.Count | Should -Be 1
        $r.Invocations[0].FilePath | Should -Match 'prettier'
    }

    It "hook__should_invoke_prettier__when_file_extension_is_md" {
        $payload = New-Payload -ToolName 'Edit' -FilePath 'C:\project\README.md'
        $r = Invoke-Hook -PayloadJson $payload -FakeCommandPath 'C:\fake\prettier.cmd'

        $r.ExitCode          | Should -Be 0
        $r.Invocations.Count | Should -Be 1
        $r.Invocations[0].FilePath | Should -Match 'prettier'
    }
}

# ===========================================================================
# Describe: Python -> ruff (preferred) or black (fallback)
# ===========================================================================
Describe "format-post-edit — Python dispatch" {

    It "hook__should_invoke_ruff_format__when_ruff_is_available" {
        $payload = New-Payload -ToolName 'Edit' -FilePath 'C:\project\main.py'
        $r = Invoke-Hook -PayloadJson $payload -FakeRuffPath 'C:\fake\ruff.exe'

        $r.ExitCode          | Should -Be 0
        $r.Invocations.Count | Should -Be 1
        $r.Invocations[0].FilePath     | Should -Match 'ruff'
        $r.Invocations[0].ArgumentList | Should -Contain 'format'
        $r.Invocations[0].ArgumentList | Should -Contain 'C:\project\main.py'
    }

    It "hook__should_invoke_black__when_ruff_is_missing" {
        $payload = New-Payload -ToolName 'Edit' -FilePath 'C:\project\utils.py'
        # FakeRuffPath empty -> ruff not found; FakeBlackPath set -> black found
        $r = Invoke-Hook -PayloadJson $payload -FakeBlackPath 'C:\fake\black.exe'

        $r.ExitCode          | Should -Be 0
        $r.Invocations.Count | Should -Be 1
        $r.Invocations[0].FilePath     | Should -Match 'black'
        $r.Invocations[0].ArgumentList | Should -Contain 'C:\project\utils.py'
    }
}

# ===========================================================================
# Describe: Unknown extension -> silent no-op
# ===========================================================================
Describe "format-post-edit — unknown extension is a no-op" {

    It "hook__should_not_invoke_any_formatter__when_extension_is_xyz" {
        $payload = New-Payload -ToolName 'Edit' -FilePath 'C:\project\data.xyz'
        $r = Invoke-Hook -PayloadJson $payload -FakeCommandPath 'C:\fake\prettier.cmd'

        $r.ExitCode          | Should -Be 0
        $r.Invocations.Count | Should -Be 0
    }

    It "hook__should_not_invoke_any_formatter__when_extension_is_ps1" {
        # .ps1 is an explicit no-op in the dispatch table
        $payload = New-Payload -ToolName 'Edit' -FilePath 'C:\project\script.ps1'
        $r = Invoke-Hook -PayloadJson $payload -FakeCommandPath 'C:\fake\prettier.cmd'

        $r.ExitCode          | Should -Be 0
        $r.Invocations.Count | Should -Be 0
    }
}

# ===========================================================================
# Describe: Missing formatter binary -> warning on stderr, exit 0
# ===========================================================================
Describe "format-post-edit — missing formatter binary" {

    It "hook__should_emit_warning_to_stderr__when_prettier_is_missing" {
        $payload = New-Payload -ToolName 'Edit' -FilePath 'C:\project\src\app.js'
        # All fake paths empty -> every Get-Command returns $null
        $r = Invoke-Hook -PayloadJson $payload -FakeCommandPath ''

        $r.ExitCode          | Should -Be 0
        $r.Invocations.Count | Should -Be 0
        $r.Stderr            | Should -Match "not found"
    }

    It "hook__should_exit_0__when_ruff_and_black_are_both_missing_for_python" {
        $payload = New-Payload -ToolName 'Edit' -FilePath 'C:\project\main.py'
        $r = Invoke-Hook -PayloadJson $payload -FakeCommandPath '' -FakeRuffPath '' -FakeBlackPath ''

        $r.ExitCode          | Should -Be 0
        $r.Invocations.Count | Should -Be 0
        $r.Stderr            | Should -Match "not found"
    }
}

# ===========================================================================
# Describe: NotebookEdit uses notebook_path
# ===========================================================================
Describe "format-post-edit — NotebookEdit payload" {

    It "hook__should_read_notebook_path__when_tool_is_NotebookEdit" {
        # Use .md notebook path so the dispatch table actually triggers prettier
        $payload = New-Payload -ToolName 'NotebookEdit' -NotebookPath 'C:\project\notes.md'
        $r = Invoke-Hook -PayloadJson $payload -FakeCommandPath 'C:\fake\prettier.cmd'

        $r.ExitCode          | Should -Be 0
        $r.Invocations.Count | Should -Be 1
        $r.Invocations[0].FilePath     | Should -Match 'prettier'
        $r.Invocations[0].ArgumentList | Should -Contain 'C:\project\notes.md'
    }
}

# ===========================================================================
# Describe: Edge cases
# ===========================================================================
Describe "format-post-edit — edge cases" {

    It "hook__should_exit_0__when_payload_is_empty" {
        $r = Invoke-Hook -PayloadJson '' -FakeCommandPath 'C:\fake\prettier.cmd'
        $r.ExitCode          | Should -Be 0
        $r.Invocations.Count | Should -Be 0
    }

    It "hook__should_exit_0__when_file_path_is_absent_from_payload" {
        $payload = '{"tool_name":"Edit","tool_input":{}}'
        $r = Invoke-Hook -PayloadJson $payload -FakeCommandPath 'C:\fake\prettier.cmd'
        $r.ExitCode          | Should -Be 0
        $r.Invocations.Count | Should -Be 0
    }
}
