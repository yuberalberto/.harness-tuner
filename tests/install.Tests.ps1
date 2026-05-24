Describe "install.ps1" {

    BeforeAll {
        $script:installScript = Join-Path (Split-Path $PSScriptRoot) "install.ps1"
    }

    Context "Fresh install with temp USERPROFILE" {
        BeforeEach {
            # Create a temporary directory for a fake home
            $script:tempHome = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) "ht-test-$([guid]::NewGuid())") -Force
            $script:profilePath = Join-Path $script:tempHome.FullName "Documents\PowerShell\profile.ps1"
        }

        AfterEach {
            # Clean up temp home
            if ($script:tempHome -and (Test-Path $script:tempHome)) {
                Remove-Item -Recurse -Force $script:tempHome -ErrorAction SilentlyContinue
            }
        }

        It "should add ht function to profile" {
            & $script:installScript -ProfilePath $script:profilePath 2>&1 | Out-Null

            (Test-Path $script:profilePath) | Should Be $true

            $profileContent = Get-Content $script:profilePath -Raw
            $profileContent | Should Match 'function\s+ht\s*\{'
            $profileContent | Should Match 'harness-tuner\.ps1'
        }

        It "should create profile directory if missing" {
            $profileDir = Split-Path $script:profilePath
            (Test-Path $profileDir) | Should Be $false

            & $script:installScript -ProfilePath $script:profilePath 2>&1 | Out-Null

            (Test-Path $profileDir) | Should Be $true
        }

        It "should be idempotent (second run does not duplicate)" {
            # First run
            & $script:installScript -ProfilePath $script:profilePath 2>&1 | Out-Null
            $firstContent = Get-Content $script:profilePath -Raw

            # Count occurrences of 'function ht'
            $firstCount = ([regex]::Matches($firstContent, 'function\s+ht\s*\{') | Measure-Object).Count
            $firstCount | Should Be 1

            # Second run
            & $script:installScript -ProfilePath $script:profilePath 2>&1 | Out-Null
            $secondContent = Get-Content $script:profilePath -Raw

            # Should still be 1, not 2
            $secondCount = ([regex]::Matches($secondContent, 'function\s+ht\s*\{') | Measure-Object).Count
            $secondCount | Should Be 1

            # Content should be identical
            $secondContent | Should Be $firstContent
        }

        It "should not create .claude directory" {
            & $script:installScript -ProfilePath $script:profilePath 2>&1 | Out-Null

            $claudeDir = Join-Path $script:tempHome.FullName ".claude"
            (Test-Path $claudeDir) | Should Be $false
        }
    }

}
