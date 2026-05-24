<#
.SYNOPSIS
    Remote one-liner installer for harness-tuner.

.DESCRIPTION
    Downloads and sets up harness-tuner from the remote repository.
    Designed to be fetched and executed via:
      iwr -useb <raw-url>/get.ps1 | iex

    Steps:
    1. Check git is installed; exit 1 if missing.
    2. Clone or pull the harness-tuner repo to ~/harness-tuner.
    3. Run ~/harness-tuner/install.ps1 to configure the shell alias.
    4. Print success message and next-step hint.

.EXAMPLE
    iwr -useb https://raw.githubusercontent.com/yuberalberto/harness-tuner/main/get.ps1 | iex
#>

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
$target = Join-Path $env:USERPROFILE 'harness-tuner'

# Step 4: Clone or update the repository
if ((Test-Path $target) -and (Test-Path "$target/.git")) {
    Write-Host "Updating harness-tuner..." -ForegroundColor Cyan
    & git -C $target pull origin main
} else {
    Write-Host "Cloning harness-tuner..." -ForegroundColor Cyan
    & git clone $repoUrl $target
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to clone or update repository" -ErrorAction Continue
    exit 1
}

# Step 5: Run the local installer
Write-Host "Running installer..." -ForegroundColor Cyan
& "$target/install.ps1"

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
