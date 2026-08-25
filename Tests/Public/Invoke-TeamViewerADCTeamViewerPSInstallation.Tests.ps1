BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Public\Test-TeamViewerADCTeamViewerPS.ps1"

    $scriptPath = "$PSScriptRoot\..\..\Cmdlets\Public\Invoke-TeamViewerADCTeamViewerPSInstallation.ps1"
    $scriptContent = Get-Content -Path $scriptPath -Raw
    $scriptContent = $scriptContent -replace '^#Requires\s+-RunAsAdministrator\s*\r?\n', ''

    Invoke-Expression $scriptContent
}

Describe 'Invoke-TeamViewerADCTeamViewerPSInstallation' {
    Context 'When TeamViewerPS module is already installed' {
        BeforeEach {
            Mock -CommandName Test-TeamViewerADCTeamViewerPS -MockWith {
                return $true
            }
            Mock -CommandName Install-Module
        }

        It 'Should return $true' {
            $result = Invoke-TeamViewerADCTeamViewerPSInstallation

            $result | Should -BeTrue
        }

        It 'Should return a boolean type' {
            $result = Invoke-TeamViewerADCTeamViewerPSInstallation

            $result | Should -BeOfType [bool]
        }

        It 'Should not call Install-Module' {
            Invoke-TeamViewerADCTeamViewerPSInstallation

            Assert-MockCalled -CommandName Test-TeamViewerADCTeamViewerPS -Times 1
            Assert-MockCalled -CommandName Install-Module -Times 0
        }

        It 'Should write verbose message indicating module is already installed' {
            $VerbosePreference = 'Continue'

            Invoke-TeamViewerADCTeamViewerPSInstallation -Verbose 4>&1 | Where-Object { $_ -match 'already installed' } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When TeamViewerPS module is not installed and installation succeeds' {
        BeforeEach {
            Mock -CommandName Test-TeamViewerADCTeamViewerPS -MockWith {
                return $false
            }
            Mock -CommandName Install-Module
        }

        It 'Should return $true' {
            $result = Invoke-TeamViewerADCTeamViewerPSInstallation -Confirm:$false

            $result | Should -BeTrue
        }

        It 'Should return a boolean type' {
            $result = Invoke-TeamViewerADCTeamViewerPSInstallation -Confirm:$false

            $result | Should -BeOfType [bool]
        }

        It 'Should call Install-Module with correct parameters' {
            Invoke-TeamViewerADCTeamViewerPSInstallation -Confirm:$false

            Assert-MockCalled -CommandName Install-Module -Times 1 -ParameterFilter {
                $Name -eq 'TeamViewerPS' -and
                $Scope -eq 'AllUsers' -and
                $Force -eq $true -and
                $ErrorAction -eq [System.Management.Automation.ActionPreference]::Stop
            }
        }

        It 'Should write verbose messages during installation' {
            $VerbosePreference = 'Continue'

            $output = Invoke-TeamViewerADCTeamViewerPSInstallation -Confirm:$false -Verbose 4>&1

            $output | Where-Object { $_ -match 'is being installed' } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When TeamViewerPS module is not installed and installation fails' {
        BeforeEach {
            Mock -CommandName Test-TeamViewerADCTeamViewerPS -MockWith {
                return $false
            }
            Mock -CommandName Install-Module -MockWith {
                throw 'Install failed'
            }
        }

        It 'Should return $false' {
            $result = Invoke-TeamViewerADCTeamViewerPSInstallation -Confirm:$false

            $result | Should -BeFalse
        }

        It 'Should return a boolean type' {
            $result = Invoke-TeamViewerADCTeamViewerPSInstallation -Confirm:$false

            $result | Should -BeOfType [bool]
        }

        It 'Should call Install-Module once before failing' {
            Invoke-TeamViewerADCTeamViewerPSInstallation -Confirm:$false

            Assert-MockCalled -CommandName Install-Module -Times 1
        }

        It 'Should write verbose error message when installation fails' {
            $VerbosePreference = 'Continue'

            $output = Invoke-TeamViewerADCTeamViewerPSInstallation -Confirm:$false -Verbose 4>&1

            $output | Where-Object { $_ -match 'Installation error' } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When WhatIf parameter is used' {
        BeforeEach {
            Mock -CommandName Test-TeamViewerADCTeamViewerPS -MockWith {
                return $false
            }
            Mock -CommandName Install-Module
        }

        It 'Should not perform installation with -WhatIf' {
            $result = Invoke-TeamViewerADCTeamViewerPSInstallation -WhatIf

            Assert-MockCalled -CommandName Install-Module -Times 0
        }

        It 'Should not return a value when -WhatIf is used' {
            $result = Invoke-TeamViewerADCTeamViewerPSInstallation -WhatIf

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Output type verification' {

        BeforeEach {
            Mock -CommandName Test-TeamViewerADCTeamViewerPS -MockWith {
                return $true
            }
            Mock -CommandName Install-Module
        }

        It 'Should have correct OutputType declaration' {
            $commandInfo = Get-Command Invoke-TeamViewerADCTeamViewerPSInstallation

            $commandInfo.OutputType.Name | Should -Contain 'System.Boolean'
        }
    }
}
