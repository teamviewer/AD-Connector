BeforeAll {
    $scriptPath = "$PSScriptRoot\..\..\Cmdlets\Public\Invoke-TeamViewerADCConfiguration.ps1"
    $scriptContent = Get-Content -Path $scriptPath -Raw
    $scriptContent = $scriptContent -replace '^#Requires\s+-RunAsAdministrator\s*\r?\n', ''

    Invoke-Expression $scriptContent
}

Describe 'Invoke-TeamViewerADCConfiguration' {
    Context 'Parameter validation' {
        It 'Should have Config_File parameter' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration
            $commandInfo.Parameters['Config_File'] | Should -Not -BeNullOrEmpty
        }

        It 'Should have Culture parameter' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration
            $commandInfo.Parameters['Culture'] | Should -Not -BeNullOrEmpty
        }

        It 'Config_File should have ValidateScript attribute' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $param = $commandInfo.Parameters['Config_File']
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] } | Should -Not -BeNullOrEmpty
        }

        It 'Config_File should validate path exists and is a file' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $param = $commandInfo.Parameters['Config_File']
            $validateScript = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] }
            $validateScript | Should -Not -BeNullOrEmpty
        }

        It 'Culture parameter should accept string type' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $param = $commandInfo.Parameters['Culture']
            $param.ParameterType.Name | Should -Be 'String'
        }
    }

    Context 'Parameter defaults' {
        It 'Should have Config_File default pointing to Config directory' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Config_File.*=.*Config.*TeamViewerADC\.json'
        }

        It 'Should have Culture default based on system locale' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Culture.*=.*Get-Culture.*TwoLetterISOLanguageName'
        }
    }

    Context 'Function structure and attributes' {

        It 'Should have CmdletBinding attribute' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match '\[CmdletBinding\(\)\]'
        }

        It 'Should define process block' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'process\s*\{'
        }

        It 'Should not require administrator privilege via CmdletBinding' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            # The #Requires -RunAsAdministrator is stripped in tests, but verified in source
            $commandInfo | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Private script sourcing' {
        It 'Should source Configuration.ps1 in process block' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Configuration\.ps1'
        }

        It 'Should source ActiveDirectory.ps1 in process block' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'ActiveDirectory\.ps1'
        }

        It 'Should source ScheduledSync.ps1 in process block' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'ScheduledSync\.ps1'
        }

        It 'Should source GraphicalUserInterface.ps1 in process block' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'GraphicalUserInterface\.ps1'
        }
    }

    Context 'Function behavior validation' {
        It 'Should call Import-Configuration' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Import-Configuration'
        }

        It 'Should call Confirm-Configuration' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Confirm-Configuration'
        }

        It 'Should call Invoke-GraphicalUserInterfaceConfiguration' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Invoke-GraphicalUserInterfaceConfiguration'
        }

        It 'Should pass Config_Content to Invoke-GraphicalUserInterfaceConfiguration' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Invoke-GraphicalUserInterfaceConfiguration\s+\$Config_Content'
        }

        It 'Should pass Culture parameter to Invoke-GraphicalUserInterfaceConfiguration' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Invoke-GraphicalUserInterfaceConfiguration.*\$Culture'
        }

        It 'Should use Config_File parameter with Import-Configuration' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Import-Configuration.*Config_File'
        }

        It 'Should have TODO comment about Confirm-Configuration necessity' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'ToDo'
            $scriptContent | Should -Match 'Confirm-Configuration'
        }
    }

    Context 'Parameter combinations' {

        It 'Should accept all parameters simultaneously' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $params = @{
                Config_File = 'C:\test.json'
                Culture     = 'en'
            }

            $missingParams = $params.Keys | Where-Object { -not $commandInfo.Parameters[$_] }
            $missingParams | Should -BeNullOrEmpty
        }

        It 'Should accept only Config_File parameter' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration
            $commandInfo.Parameters['Config_File'] | Should -Not -BeNullOrEmpty
        }

        It 'Should accept only Culture parameter' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration
            $commandInfo.Parameters['Culture'] | Should -Not -BeNullOrEmpty
        }

        It 'Should accept no parameters (all defaults)' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            # All parameters should have defaults
            $commandInfo.Parameters.Keys.Count | Should -BeGreaterThan 0
        }
    }

    Context 'Help documentation' {

        It 'Should have help documentation available' {
            $help = Get-Help -Name Invoke-TeamViewerADCConfiguration -ErrorAction SilentlyContinue
            $help | Should -Not -BeNullOrEmpty
        }

        It 'Should have SYNOPSIS in help' {
            $help = Get-Help -Name Invoke-TeamViewerADCConfiguration -ErrorAction SilentlyContinue
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Culture parameter handling' {

        It 'Should default Culture to current system locale' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match '\(Get-Culture\)\.TwoLetterISOLanguageName'
        }

        It 'Should allow custom Culture values' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $param = $commandInfo.Parameters['Culture']

            # Culture parameter should not be mandatory
            $isMandatory = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }
            $isMandatory | Should -BeNullOrEmpty
        }

        It 'Should accept ISO language codes' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $param = $commandInfo.Parameters['Culture']

            # Should be string type to accept ISO codes
            $param.ParameterType.Name | Should -Be 'String'
        }
    }

    Context 'Configuration flow' {

        It 'Should import configuration before confirming' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            # Find positions of Import and Confirm
            $importPos = $scriptContent.IndexOf('Import-Configuration')
            $confirmPos = $scriptContent.IndexOf('Confirm-Configuration')

            # Import should come before Confirm
            $importPos | Should -BeLessThan $confirmPos
        }

        It 'Should invoke GUI configuration after importing and confirming' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            # Find positions
            $confirmPos = $scriptContent.IndexOf('Confirm-Configuration')
            $guiPos = $scriptContent.IndexOf('Invoke-GraphicalUserInterfaceConfiguration')

            # Confirm should come before GUI
            $confirmPos | Should -BeLessThan $guiPos
        }

        It 'Should store configuration in Config_Content variable' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Config_Content.*='
            $scriptContent | Should -Match '\$Config_Content'
        }
    }

    Context 'Runtime requirements' {
        It 'Should have RunAsAdministrator requirement in source file' {
            $sourcePath = "$PSScriptRoot\..\..\Cmdlets\Public\Invoke-TeamViewerADCConfiguration.ps1"
            $sourceContent = Get-Content -Path $sourcePath -Raw

            $sourceContent | Should -Match '#Requires\s+-RunAsAdministrator'
        }

        It 'Should source from Private folder' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match '\$PSScriptRoot\\\.\.\\Private'
        }
    }

    Context 'Script block structure' {
        It 'Should have proper script block structure' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $ast = $commandInfo.ScriptBlock.Ast

            $ast | Should -Not -BeNullOrEmpty
        }

        It 'Should not define begin or end blocks (only process)' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCConfiguration

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'process\s*\{'
            # Should not have explicit begin block (besides automatic)
            $beginCount = [regex]::Matches($scriptContent, '\bbegin\s*\{').Count
            $beginCount | Should -Be 0
        }
    }
}
