BeforeAll {
    # Import Pester module (already available in modern PowerShell)
    $scriptRoot = Split-Path $PSScriptRoot -Parent
    $getScriptPath = Join-Path $scriptRoot 'get.ps1'
}

if ($env:CI_NETWORK_TESTS) {
    Describe 'get.ps1 smoke test' {
        It 'should clone the repository to a temp profile directory' {
            # Create a temporary directory to act as $env:USERPROFILE
            $tempProfileDir = New-Item -ItemType Directory -Path "$env:TEMP\ht-test-$(Get-Random)" -Force
            $originalUserProfile = $env:USERPROFILE

            try {
                # Override USERPROFILE for this test
                $env:USERPROFILE = $tempProfileDir

                # Execute get.ps1 with the temp profile
                & $getScriptPath
                $LASTEXITCODE | Should -Be 0

                # Verify the target directory exists and is a git repository
                $targetDir = Join-Path $env:USERPROFILE '.harness-tuner'
                Test-Path $targetDir | Should -Be $true
                Test-Path "$targetDir/.git" | Should -Be $true
            } finally {
                # Restore original USERPROFILE
                $env:USERPROFILE = $originalUserProfile
                # Clean up temp directory
                if (Test-Path $tempProfileDir) {
                    Remove-Item -Recurse -Force $tempProfileDir
                }
            }
        }

        It 'should add ht function to the PowerShell profile' {
            # Create a temporary directory to act as $env:USERPROFILE
            $tempProfileDir = New-Item -ItemType Directory -Path "$env:TEMP\ht-test-$(Get-Random)" -Force
            $originalUserProfile = $env:USERPROFILE

            try {
                # Override USERPROFILE for this test
                $env:USERPROFILE = $tempProfileDir

                # Execute get.ps1
                & $getScriptPath
                $LASTEXITCODE | Should -Be 0

                # Check that the profile exists and contains the ht function
                $profilePath = Join-Path $tempProfileDir 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
                Test-Path $profilePath | Should -Be $true

                $profileContent = Get-Content $profilePath -Raw
                $profileContent | Should -Match 'function\s+ht\s*\{'
            } finally {
                # Restore original USERPROFILE
                $env:USERPROFILE = $originalUserProfile
                # Clean up temp directory
                if (Test-Path $tempProfileDir) {
                    Remove-Item -Recurse -Force $tempProfileDir
                }
            }
        }
    }
} else {
    Write-Host "Skipping network smoke test for get.ps1. Set CI_NETWORK_TESTS=1 to enable."
}
