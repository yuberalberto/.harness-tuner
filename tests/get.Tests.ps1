$script:repoRoot  = Split-Path $PSScriptRoot -Parent
$script:getScript = Join-Path $script:repoRoot 'get.ps1'

# ---------------------------------------------------------------------------
# Offline e2e: sparse-checkout installs exactly the payload — no dev artifacts
# ---------------------------------------------------------------------------
Describe 'get.ps1 — sparse-checkout payload (offline)' {

    BeforeAll {
        # Bare clone of the current repo acts as the "remote"
        $script:bareDir = Join-Path ([IO.Path]::GetTempPath()) "ht-bare-$([guid]::NewGuid())"
        git clone --bare $script:repoRoot $script:bareDir 2>&1 | Out-Null
    }

    AfterAll {
        Remove-Item -Recurse -Force $script:bareDir -ErrorAction SilentlyContinue
    }

    BeforeEach {
        $script:fakeHome = New-Item -ItemType Directory -Force `
            -Path (Join-Path ([IO.Path]::GetTempPath()) "ht-home-$([guid]::NewGuid())")
        $script:fakeProfile     = Join-Path $script:fakeHome.FullName 'Documents\PowerShell\profile.ps1'
        $script:installed       = Join-Path $script:fakeHome.FullName '.harness-tuner'
        $script:origUserProfile = $env:USERPROFILE
        $script:origRepo        = $env:HARNESS_TUNER_REPO
        $env:USERPROFILE        = $script:fakeHome.FullName
        $env:HARNESS_TUNER_REPO = $script:bareDir
    }

    AfterEach {
        $env:USERPROFILE        = $script:origUserProfile
        $env:HARNESS_TUNER_REPO = $script:origRepo
        Remove-Item -Recurse -Force $script:fakeHome.FullName -ErrorAction SilentlyContinue
    }

    It 'should install all payload files and directories' {
        & $script:getScript -ProfilePath $script:fakeProfile 2>&1 | Out-Null

        (Test-Path (Join-Path $script:installed 'harness-tuner.ps1')) | Should Be $true
        (Test-Path (Join-Path $script:installed 'install.ps1'))        | Should Be $true
        (Test-Path (Join-Path $script:installed 'get.ps1'))            | Should Be $true
        (Test-Path (Join-Path $script:installed 'VERSION'))            | Should Be $true
        (Test-Path (Join-Path $script:installed 'README.md'))          | Should Be $true
        (Test-Path (Join-Path $script:installed 'CHANGELOG.md'))       | Should Be $true
        (Test-Path (Join-Path $script:installed 'templates-claude'))   | Should Be $true
        (Test-Path (Join-Path $script:installed 'templates-cascade'))  | Should Be $true
    }

    It 'should NOT install dev-only artifacts' {
        & $script:getScript -ProfilePath $script:fakeProfile 2>&1 | Out-Null

        (Test-Path (Join-Path $script:installed '.claude'))      | Should Be $false
        (Test-Path (Join-Path $script:installed '.windsurf'))    | Should Be $false
        (Test-Path (Join-Path $script:installed 'tests'))        | Should Be $false
        (Test-Path (Join-Path $script:installed 'docs'))         | Should Be $false
        (Test-Path (Join-Path $script:installed '.specs'))       | Should Be $false
        (Test-Path (Join-Path $script:installed '.engram'))      | Should Be $false
        (Test-Path (Join-Path $script:installed '.engram-lite')) | Should Be $false
        (Test-Path (Join-Path $script:installed 'CONTEXT.md'))  | Should Be $false
        (Test-Path (Join-Path $script:installed '.gitignore'))   | Should Be $false
    }

    It 'should be idempotent — second run succeeds and payload stays intact' {
        & $script:getScript -ProfilePath $script:fakeProfile 2>&1 | Out-Null
        & $script:getScript -ProfilePath $script:fakeProfile 2>&1 | Out-Null

        (Test-Path (Join-Path $script:installed 'harness-tuner.ps1')) | Should Be $true
        (Test-Path (Join-Path $script:installed 'templates-claude'))   | Should Be $true
        (Test-Path (Join-Path $script:installed '.claude'))            | Should Be $false
    }
}

# ---------------------------------------------------------------------------
# Network smoke test (CI only — requires live GitHub)
# ---------------------------------------------------------------------------
if ($env:CI_NETWORK_TESTS) {
    Describe 'get.ps1 smoke test' {
        It 'should clone the repository to a temp profile directory' {
            $tempProfileDir      = New-Item -ItemType Directory -Path "$env:TEMP\ht-test-$(Get-Random)" -Force
            $originalUserProfile = $env:USERPROFILE

            try {
                $env:USERPROFILE = $tempProfileDir
                & $script:getScript
                $LASTEXITCODE | Should Be 0

                $targetDir = Join-Path $env:USERPROFILE '.harness-tuner'
                (Test-Path $targetDir)        | Should Be $true
                (Test-Path "$targetDir/.git") | Should Be $true
            } finally {
                $env:USERPROFILE = $originalUserProfile
                if (Test-Path $tempProfileDir) { Remove-Item -Recurse -Force $tempProfileDir }
            }
        }

        It 'should add ht function to the PowerShell profile' {
            $tempProfileDir      = New-Item -ItemType Directory -Path "$env:TEMP\ht-test-$(Get-Random)" -Force
            $originalUserProfile = $env:USERPROFILE

            try {
                $env:USERPROFILE = $tempProfileDir
                & $script:getScript
                $LASTEXITCODE | Should Be 0

                $profilePath = Join-Path $tempProfileDir 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
                (Test-Path $profilePath) | Should Be $true

                $profileContent = Get-Content $profilePath -Raw
                $profileContent | Should Match 'function\s+ht\s*\{'
            } finally {
                $env:USERPROFILE = $originalUserProfile
                if (Test-Path $tempProfileDir) { Remove-Item -Recurse -Force $tempProfileDir }
            }
        }
    }
} else {
    Write-Host "Skipping network smoke test for get.ps1. Set CI_NETWORK_TESTS=1 to enable."
}
