<#
.SYNOPSIS
    Adds the `ht` function to PowerShell profile.

.DESCRIPTION
    Installs a shell alias function in $PROFILE.CurrentUserAllHosts that delegates
    to ~/harness-tuner/harness-tuner.ps1. Idempotent: skips if `ht` function
    already exists in profile.

.EXAMPLE
    & "$env:USERPROFILE\harness-tuner\install.ps1"
#>

param(
    [string]$ProfilePath = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Allow test override of profile path, otherwise use the standard location
if ([string]::IsNullOrEmpty($ProfilePath)) {
    $ProfilePath = $PROFILE.CurrentUserAllHosts
}

# The function block to add to the profile
$aliasBlock = @'

# harness-tuner - CLI alias
function ht { & "$env:USERPROFILE\harness-tuner\harness-tuner.ps1" @args }
'@

# Check if ht function already exists in profile
$aliasExists = $false
if (Test-Path $ProfilePath) {
    $profileContent = Get-Content $ProfilePath -Raw
    if ($profileContent -match 'function\s+ht\s*\{') {
        $aliasExists = $true
    }
}

# Idempotency: skip if already installed
if ($aliasExists) {
    Write-Host "ht function already in profile - skipping."
    exit 0
}

# Create $PROFILE directory if it doesn't exist
$profileDir = Split-Path $ProfilePath
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
}

# Add the ht function to the profile
Add-Content -Path $ProfilePath -Value $aliasBlock -Encoding UTF8

# Confirmation and reload instruction
Write-Host ""
Write-Host "Added ht function to profile." -ForegroundColor Green
Write-Host "Reload your profile to use it:  . `$PROFILE" -ForegroundColor DarkYellow
Write-Host ""
