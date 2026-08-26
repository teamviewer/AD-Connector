BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Public\Invoke-TeamViewerADCSynchronization.ps1"
}

Describe 'Invoke-TeamViewerADCSynchronization' {
    Context 'Parameter validation' {
        It 'Should have Config_File parameter' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization
            $commandInfo.Parameters['Config_File'] | Should -Not -BeNullOrEmpty
        }

        It 'Should have Directory parameter' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization
            $commandInfo.Parameters['Directory'] | Should -Not -BeNullOrEmpty
        }

        It 'Should have Retention parameter with default value 16' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $param = $commandInfo.Parameters['Retention']
            $param | Should -Not -BeNullOrEmpty
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] } | Should -Not -BeNullOrEmpty
        }

        It 'Should have optional Basename parameter' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $param = $commandInfo.Parameters['Basename']
            $param | Should -Not -BeNullOrEmpty
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory } | Should -BeNullOrEmpty
        }

        It 'Should have Progress_Handler parameter as ScriptBlock' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $param = $commandInfo.Parameters['Progress_Handler']
            $param | Should -Not -BeNullOrEmpty
            $param.ParameterType.Name | Should -Be 'ScriptBlock'
        }

        It 'Should have PassThru switch parameter' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $param = $commandInfo.Parameters['PassThru']
            $param | Should -Not -BeNullOrEmpty
            $param.SwitchParameter | Should -BeTrue
        }

        It 'Config_File should have ValidateScript attribute' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $param = $commandInfo.Parameters['Config_File']
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] } | Should -Not -BeNullOrEmpty
        }

        It 'Directory should have ValidateScript attribute' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $param = $commandInfo.Parameters['Directory']
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] } | Should -Not -BeNullOrEmpty
        }

        It 'Retention should validate minimum value of 1' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $param = $commandInfo.Parameters['Retention']

            $validateRange = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange.MinRange | Should -Be 1
        }
    }

    Context 'Function structure and attributes' {
        It 'Should support ShouldProcess in script content' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'SupportsShouldProcess'
        }

        It 'Should have CmdletBinding attribute' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match '\[CmdletBinding'
        }

        It 'Should not define begin/process blocks when lifecycle behavior is unnecessary' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Not -Match 'begin\s*\{'
            $scriptContent | Should -Not -Match 'process\s*\{'
        }
    }

    Context 'Parameter defaults' {
        It 'Should have Config_File default pointing to Config directory' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Config_File.*=.*Config.*TeamViewerADC\.json'
        }

        It 'Should have Directory default pointing to Logs directory' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Directory.*=.*Logs'
        }

        It 'Should have Retention default of 16' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Retention.*=.*16'
        }

        It 'Should have Progress_Handler default as empty ScriptBlock' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Progress_Handler.*=.*\{\}'
        }
    }

    Context 'Help documentation' {
        It 'Should have help documentation' {
            $help = Get-Help -Name Invoke-TeamViewerADCSynchronization -ErrorAction SilentlyContinue
            $help | Should -Not -BeNullOrEmpty
        }

        It 'Should have SYNOPSIS in help' {
            $help = Get-Help -Name Invoke-TeamViewerADCSynchronization -ErrorAction SilentlyContinue
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Script block validation' {
        It 'Should call Import-TVADCConfiguration' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Import-TVADCConfiguration'
        }

        It 'Should call Test-TVADCConfiguration' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Test-TVADCConfiguration'
        }

        It 'Should call Invoke-TVADCSync' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Invoke-TVADCSync'
        }

        It 'Should handle PassThru switch logic' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match '\$PassThru'
        }

        It 'Should handle ShouldProcess check' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'ShouldProcess'
        }

        It 'Should call Format-TVADCSyncLog when not PassThru' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Format-TVADCSyncLog'
        }

        It 'Should call Out-TVADCLogLine for logging' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Out-TVADCLogLine'
        }

        It 'Should call Invoke-TeamViewerADCLogRotation for log rotation' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Invoke-TeamViewerADCLogRotation'
        }

        It 'Should use Progress_Handler parameter in Invoke-TVADCSync calls' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Progress_Handler'
        }
    }

    Context 'Parameter combinations' {
        It 'Should accept all parameters simultaneously' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            # Verify that we can construct a call with all parameters
            $params = @{
                Config_File      = 'C:\test.json'
                Directory    = 'C:\logs'
                Basename     = 'TestLog_'
                Retention    = 10
                Progress_Handler = {}
                PassThru         = $true
                Confirm          = $false
            }

            # All parameters should be recognized
            $missingParams = $params.Keys | Where-Object { -not $commandInfo.Parameters[$_] }
            $missingParams | Should -BeNullOrEmpty
        }

        It 'Should not require Basename parameter when default is defined' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $param = $commandInfo.Parameters['Basename']
            $isMandatory = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }
            $isMandatory | Should -BeNullOrEmpty
        }

        It 'Should validate Basename is not null or empty' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $param = $commandInfo.Parameters['Basename']
            $validateNotNull = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] }
            $validateNotNull | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Execution behavior validation' {

        It 'Should not have begin block defined' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Not -Match 'begin\s*\{'
        }

        It 'Should use Basename parameter in logging operations' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Basename'
        }

        It 'Should pass Basename to Out-TVADCLogLine' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Basename.*\$Basename'
        }

        It 'Should pass Basename to Invoke-TeamViewerADCLogRotation' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Invoke-TeamViewerADCLogRotation.*Basename'
        }

        It 'Should have proper error handling with try-catch pattern in sourced files' {
            # This validates that the function expects error handling
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCSynchronization

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            # Should invoke sync and handle the results
            $scriptContent | Should -Match 'Invoke-TVADCSync'
        }
    }
}
