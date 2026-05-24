<#
.SYNOPSIS
    PostToolUse hook — formats the modified file with the language-appropriate formatter.

.DESCRIPTION
    Claude Code invokes this script on PostToolUse events for Edit, Write, and NotebookEdit
    tools. The event payload is delivered as JSON on stdin.

    Dispatch table:
        .js .jsx .ts .tsx .json .md  -> prettier
        .py                          -> ruff format (preferred), fallback to black
        .go                          -> gofmt -w
        .rs                          -> rustfmt
        .ps1                         -> no-op (no widely-adopted formatter)
        <unknown>                    -> silent no-op, exit 0

    Safety contract:
        - If the formatter binary is missing: one-line warning to stderr, exit 0.
        - If the formatter exits non-zero: formatter output written to stderr, exit 0.
        - This hook NEVER exits non-zero — a format failure must not block Claude Code.

.NOTES
    Claude Code PostToolUse payload shape (relevant fields only):
    {
      "tool_name": "Edit" | "Write" | "NotebookEdit",
      "tool_input": {
        "file_path": "<absolute-or-relative path>",   // Edit, Write
        "notebook_path": "<path>"                     // NotebookEdit
      }
    }
#>

#Requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 1. Read and parse stdin payload
# ---------------------------------------------------------------------------
$rawPayload = $input | Out-String
if ([string]::IsNullOrWhiteSpace($rawPayload)) {
    # No payload — nothing to do.
    exit 0
}

try {
    $payload = $rawPayload | ConvertFrom-Json
} catch {
    Write-Error "format-post-edit: failed to parse JSON payload: $_"
    exit 0
}

# ---------------------------------------------------------------------------
# 2. Extract file path — NotebookEdit uses notebook_path, others use file_path
# ---------------------------------------------------------------------------
$filePath = $null

if ($payload.tool_input -ne $null) {
    if ($payload.tool_name -eq 'NotebookEdit' -and $payload.tool_input.PSObject.Properties['notebook_path']) {
        $filePath = $payload.tool_input.notebook_path
    } elseif ($payload.tool_input.PSObject.Properties['file_path']) {
        $filePath = $payload.tool_input.file_path
    }
}

if ([string]::IsNullOrWhiteSpace($filePath)) {
    # No path found — silent no-op.
    exit 0
}

# ---------------------------------------------------------------------------
# 3. Resolve extension (lower-case, includes the dot)
# ---------------------------------------------------------------------------
$ext = [System.IO.Path]::GetExtension($filePath).ToLower()

# ---------------------------------------------------------------------------
# 4. Helper: invoke a formatter command, capturing output.
#    - Looks up $BinaryName via Get-Command.
#    - If missing: writes a one-line warning to stderr, returns immediately.
#    - If formatter exits non-zero: writes combined stdout+stderr to stderr.
#    - ALWAYS returns without setting a non-zero exit code.
# ---------------------------------------------------------------------------
function Invoke-Formatter {
    param(
        [string]   $BinaryName,
        [string[]] $Arguments,
        [string]   $FilePath
    )

    $cmd = Get-Command $BinaryName -ErrorAction SilentlyContinue
    if ($null -eq $cmd) {
        Write-Warning "format-post-edit: '$BinaryName' not found — skipping format for '$FilePath'"
        return
    }

    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()

    try {
        $proc = Start-Process `
            -FilePath               $cmd.Source `
            -ArgumentList           $Arguments `
            -Wait `
            -NoNewWindow `
            -PassThru `
            -RedirectStandardOutput $outFile `
            -RedirectStandardError  $errFile

        if ($proc.ExitCode -ne 0) {
            $outText = Get-Content $outFile -Raw -ErrorAction SilentlyContinue
            $errText = Get-Content $errFile -Raw -ErrorAction SilentlyContinue
            $combined = (@($outText, $errText) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n"
            [Console]::Error.WriteLine("format-post-edit: '$BinaryName' exited $($proc.ExitCode) for '$FilePath':`n$combined")
        }
    } finally {
        Remove-Item $outFile -ErrorAction SilentlyContinue
        Remove-Item $errFile -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# 5. Dispatch table
# ---------------------------------------------------------------------------
switch ($ext) {

    # --- Prettier: JS / TS / JSON / Markdown ---
    { $_ -in @('.js', '.jsx', '.ts', '.tsx', '.json', '.md') } {
        Invoke-Formatter -BinaryName 'prettier' -Arguments @('--write', $filePath) -FilePath $filePath
        break
    }

    # --- Python: ruff (preferred), fallback to black ---
    # Probe ruff first to decide which formatter to use; Invoke-Formatter will
    # probe again internally, but that is a cheap Get-Command call with no side
    # effects — acceptable in exchange for clean separation of concerns.
    '.py' {
        $ruffCmd = Get-Command 'ruff' -ErrorAction SilentlyContinue
        if ($null -ne $ruffCmd) {
            Invoke-Formatter -BinaryName 'ruff' -Arguments @('format', $filePath) -FilePath $filePath
        } else {
            Invoke-Formatter -BinaryName 'black' -Arguments @($filePath) -FilePath $filePath
        }
        break
    }

    # --- Go ---
    '.go' {
        Invoke-Formatter -BinaryName 'gofmt' -Arguments @('-w', $filePath) -FilePath $filePath
        break
    }

    # --- Rust ---
    '.rs' {
        Invoke-Formatter -BinaryName 'rustfmt' -Arguments @($filePath) -FilePath $filePath
        break
    }

    # --- PowerShell: no widely-adopted formatter — intentional no-op ---
    '.ps1' {
        # no-op
        break
    }

    # --- Unknown extension: silent no-op ---
    default {
        # Nothing to do.
        break
    }
}

exit 0
