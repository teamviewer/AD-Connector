BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Public\Test-TeamViewerADCTeamViewerPS.ps1"
}

Describe 'Test-TeamViewerADCTeamViewerPS' {

    Context 'When TeamViewerPS module is installed' {

        BeforeEach {
            Mock -CommandName Get-InstalledModule -MockWith {
                return @{ Name = 'TeamViewerPS'; Version = [version]'1.0.0' }
            } -ParameterFilter {
                $Name -eq 'TeamViewerPS'
            }
        }

        It 'Should return $true' {
            $result = Test-TeamViewerADCTeamViewerPS

            $result | Should -BeTrue
        }

        It 'Should return a boolean type' {
            $result = Test-TeamViewerADCTeamViewerPS

            $result | Should -BeOfType [bool]
        }

        It 'Should call Get-InstalledModule with correct parameters' {
            Test-TeamViewerADCTeamViewerPS

            Should -Invoke -CommandName Get-InstalledModule -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'TeamViewerPS' -and $ErrorAction -eq [System.Management.Automation.ActionPreference]::SilentlyContinue
            }
        }

        It 'Should write verbose message when module is installed' {
            $VerbosePreference = 'Continue'
            Test-TeamViewerADCTeamViewerPS -Verbose 4>&1 | Where-Object { $_ -match 'already installed' } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When TeamViewerPS module is not installed' {

        BeforeEach {
            Mock -CommandName Get-InstalledModule -MockWith {
                return $null
            } -ParameterFilter {
                $Name -eq 'TeamViewerPS'
            }
        }

        It 'Should return $false' {
            $result = Test-TeamViewerADCTeamViewerPS

            $result | Should -BeFalse
        }

        It 'Should return a boolean type' {
            $result = Test-TeamViewerADCTeamViewerPS

            $result | Should -BeOfType [bool]
        }

        It 'Should call Get-InstalledModule with correct parameters' {
            Test-TeamViewerADCTeamViewerPS

            Should -Invoke -CommandName Get-InstalledModule -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'TeamViewerPS' -and $ErrorAction -eq [System.Management.Automation.ActionPreference]::SilentlyContinue
            }
        }

        It 'Should write verbose message when module is not installed' {
            $VerbosePreference = 'Continue'
            Test-TeamViewerADCTeamViewerPS -Verbose 4>&1 | Where-Object { $_ -match 'is not installed' } | Should -Not -BeNullOrEmpty
        }
    }
}
