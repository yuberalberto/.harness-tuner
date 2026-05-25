<#
.SYNOPSIS
    Remote one-liner installer for harness-tuner.

.DESCRIPTION
    Downloads and sets up harness-tuner from the remote repository using a
    sparse checkout so that only the user-facing payload lands in ~/.harness-tuner.
    Designed to be fetched and executed via:
      iwr -useb <raw-url>/get.ps1 | iex

    Steps:
    1. Check git is installed; exit 1 if missing.
    2. Clone (sparse) or pull the harness-tuner repo to ~/.harness-tuner.
    3. Run ~/.harness-tuner/install.ps1 to configure the shell alias.
    4. Print success message and next-step hint.

.PARAMETER ProfilePath
    Test override for the PowerShell profile path passed to install.ps1.
    Leave empty for a normal install.

.EXAMPLE
    iwr -useb https://raw.githubusercontent.com/yuberalberto/harness-tuner/main/get.ps1 | iex
#>

param(
    [string]$ProfilePath = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Step 1: Check if git is installed
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCmd) {
    Write-Error "Git is not installed or not in PATH. Please install Git from https://git-scm.com" -ErrorAction Continue
    exit 1
}

# Step 2: Determine repository URL
$repoUrl = if ($env:HARNESS_TUNER_REPO) {
    $env:HARNESS_TUNER_REPO
} else {
    'https://github.com/yuberalberto/harness-tuner.git'
}

# Step 3: Define target directory
$target = Join-Path $env:USERPROFILE '.harness-tuner'

# Exactly what the user needs — nothing more, nothing less.
$sparsePatterns = @(
    '/harness-tuner.ps1',
    '/install.ps1',
    '/get.ps1',
    '/VERSION',
    '/README.md',
    '/CHANGELOG.md',
    '/templates-claude/',
    '/templates-cascade/'
)

# Step 4: Clone (sparse) or update the repository
if ((Test-Path $target) -and (Test-Path "$target/.git")) {
    Write-Host "Updating harness-tuner..." -ForegroundColor Cyan
    & git -C $target sparse-checkout init --no-cone 2>&1 | Out-Null
    & git -C $target sparse-checkout set @sparsePatterns
    & git -C $target pull origin main
} else {
    Write-Host "Installing harness-tuner..." -ForegroundColor Cyan
    & git clone --no-checkout $repoUrl $target
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to clone repository" -ErrorAction Continue
        exit 1
    }
    & git -C $target sparse-checkout init --no-cone
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to initialise sparse-checkout" -ErrorAction Continue
        exit 1
    }
    & git -C $target sparse-checkout set @sparsePatterns
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to configure sparse-checkout" -ErrorAction Continue
        exit 1
    }
    & git -C $target checkout main
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to checkout" -ErrorAction Continue
        exit 1
    }
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to install or update repository" -ErrorAction Continue
    exit 1
}

# Step 5: Run the local installer
Write-Host "Running installer..." -ForegroundColor Cyan
if ($ProfilePath) {
    & "$target/install.ps1" -ProfilePath $ProfilePath
} else {
    & "$target/install.ps1"
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Installer failed" -ErrorAction Continue
    exit 1
}

# Step 6: Print success message and next steps
Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "Next step: Run" -ForegroundColor Yellow -NoNewline
Write-Host " ht init" -ForegroundColor Cyan -NoNewline
Write-Host " inside your project directory." -ForegroundColor Yellow
Write-Host ""
