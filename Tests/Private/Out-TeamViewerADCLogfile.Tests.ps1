BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Out-TeamViewerADCLogfile.ps1"
}

Describe 'Out-TeamViewerADCLogfile' {
    Context 'Function metadata' {
        It 'Should exist as a function' {
            Get-Command -Name Out-TeamViewerADCLogfile -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have CmdletBinding with SupportsShouldProcess' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\[CmdletBinding\(SupportsShouldProcess\s*=\s*\$true\)\]'
        }

        It 'Should declare OutputType as void' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\[OutputType\(\[void\]\)\]'
        }

        It 'Should have begin block' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'begin\s*\{'
        }

        It 'Should have process block' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'process\s*\{'
        }
    }

    Context 'Parameter validation' {
        It 'Should have Log_Directory parameter' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile
            $commandInfo.Parameters['Log_Directory'] | Should -Not -BeNullOrEmpty
        }

        It 'Should have Log_Basename parameter' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile
            $commandInfo.Parameters['Log_Basename'] | Should -Not -BeNullOrEmpty
        }

        It 'Log_Directory should be string type' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile
            $commandInfo.Parameters['Log_Directory'].ParameterType.Name | Should -Be 'String'
        }

        It 'Log_Basename should be string type' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile
            $commandInfo.Parameters['Log_Basename'].ParameterType.Name | Should -Be 'String'
        }

        It 'Log_Directory should have ValidateScript attribute' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $param = $commandInfo.Parameters['Log_Directory']
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] } | Should -Not -BeNullOrEmpty
        }

        It 'Log_Basename should have ValidateNotNullOrEmpty attribute' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $param = $commandInfo.Parameters['Log_Basename']
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] } | Should -Not -BeNullOrEmpty
        }

        It 'Should reject non-existent Log_Directory' {
            { 'test' | Out-TeamViewerADCLogfile -Log_Directory 'C:\NonExistent\Path\12345' -Log_Basename 'Test' -ErrorAction Stop } | Should -Throw
        }

        It 'Should reject empty Log_Basename' {
            $testDir = New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'TestDir1') -ItemType Directory

            try {
                { 'test' | Out-TeamViewerADCLogfile -Log_Directory $testDir.FullName -Log_Basename '' -ErrorAction Stop } | Should -Throw
            }
            finally {
                Remove-Item -Path $testDir.FullName -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Should reject null Log_Basename' {
            $testDir = New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'TestDir2') -ItemType Directory

            try {
                { 'test' | Out-TeamViewerADCLogfile -Log_Directory $testDir.FullName -Log_Basename $null -ErrorAction Stop } | Should -Throw
            }
            finally {
                Remove-Item -Path $testDir.FullName -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Function implementation' {
        It 'Should use Join-Path for path construction' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'Join-Path'
        }

        It 'Should format dates with yyyy-MM-dd pattern' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'yyyy-MM-dd'
        }

        It 'Should use Get-Date for timestamp' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'Get-Date'
        }

        It 'Should use Out-File for writing' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'Out-File'
        }

        It 'Should use -Append flag for appending' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\-Append'
        }

        It 'Should use ShouldProcess for WhatIf support' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'ShouldProcess'
        }

        It 'Should create Log_Filename variable in begin block' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'Log_Filename'
        }

        It 'Should include .log file extension' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\.log'
        }

        It 'Should process pipeline input via $_' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\$_'
        }

        It 'Should use named parameters in Out-File call' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '-FilePath'
        }
    }

    Context 'Filename construction logic' {
        It 'Should combine basename with date in filename' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\$Log_Basename'
            $scriptContent | Should -Match 'yyyy-MM-dd'
        }

        It 'Should use directory from Log_Directory parameter' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\$Log_Directory'
        }

        It 'Should construct path with proper separators' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'Join-Path'
        }
    }

    Context 'ShouldProcess behavior' {
        It 'Should support -Confirm parameter' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile
            $commandInfo.Parameters['Confirm'] | Should -Not -BeNullOrEmpty
        }

        It 'Should support -WhatIf parameter' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile
            $commandInfo.Parameters['WhatIf'] | Should -Not -BeNullOrEmpty
        }

        It 'Should use ShouldProcess method in process block' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'ShouldProcess'
            $scriptContent | Should -Match 'process\s*\{'
        }
    }

    Context 'Return behavior' {
        It 'Should return void (no output)' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\[OutputType\(\[void\]\)\]'
        }

        It 'Should not have explicit return statements with values' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $matches = [regex]::Matches($scriptContent, 'return\s+\$')
            $matches.Count | Should -Be 0
        }
    }

    Context 'Help documentation' {
        It 'Should have help available' {
            $help = Get-Help -Name Out-TeamViewerADCLogfile -ErrorAction SilentlyContinue
            $help | Should -Not -BeNullOrEmpty
        }

        It 'Should have non-empty synopsis' {
            $help = Get-Help -Name Out-TeamViewerADCLogfile -ErrorAction SilentlyContinue
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It 'Should document parameters' {
            $help = Get-Help -Name Out-TeamViewerADCLogfile -Full -ErrorAction SilentlyContinue
            $help.Parameters | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Advanced function features' {
        It 'Should have CmdletBinding for advanced function behavior' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\[CmdletBinding\('
        }

        It 'Should use Out-File with proper parameters' {
            $commandInfo = Get-Command -Name Out-TeamViewerADCLogfile

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'Out-File'
            $scriptContent | Should -Match '-FilePath'
            $scriptContent | Should -Match '-Append'
        }
    }
}
