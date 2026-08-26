BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Out-TVADCLogLine.ps1"
}

Describe 'Out-TVADCLogLine' {
    Context 'Function metadata' {
        It 'Should exist as a function' {
            Get-Command -Name Out-TVADCLogLine -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have CmdletBinding with SupportsShouldProcess' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\[CmdletBinding\(SupportsShouldProcess\s*=\s*\$true\)\]'
        }

        It 'Should declare OutputType as void' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\[OutputType\(\[void\]\)\]'
        }

        It 'Should have begin block' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'begin\s*\{'
        }

        It 'Should have process block' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'process\s*\{'
        }
    }

    Context 'Parameter validation' {
        It 'Should have Directory parameter' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine
            $commandInfo.Parameters['Directory'] | Should -Not -BeNullOrEmpty
        }

        It 'Should have Basename parameter' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine
            $commandInfo.Parameters['Basename'] | Should -Not -BeNullOrEmpty
        }

        It 'Directory should be string type' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine
            $commandInfo.Parameters['Directory'].ParameterType.Name | Should -Be 'String'
        }

        It 'Basename should be string type' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine
            $commandInfo.Parameters['Basename'].ParameterType.Name | Should -Be 'String'
        }

        It 'Directory should have ValidateScript attribute' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $param = $commandInfo.Parameters['Directory']
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] } | Should -Not -BeNullOrEmpty
        }

        It 'Basename should have ValidateNotNullOrEmpty attribute' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $param = $commandInfo.Parameters['Basename']
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] } | Should -Not -BeNullOrEmpty
        }

        It 'Should create a non-existent Directory' {
            $LogDirectory = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid())

            'test' | Out-TVADCLogLine -Directory $LogDirectory -Basename 'Test'

            Test-Path -Path $LogDirectory -PathType Container | Should -BeTrue
        }

        It 'Should reject empty Basename' {
            $testDir = New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'TestDir1') -ItemType Directory

            try {
                { 'test' | Out-TVADCLogLine -Directory $testDir.FullName -Basename '' -ErrorAction Stop } | Should -Throw
            }
            finally {
                Remove-Item -Path $testDir.FullName -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Should reject null Basename' {
            $testDir = New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'TestDir2') -ItemType Directory

            try {
                { 'test' | Out-TVADCLogLine -Directory $testDir.FullName -Basename $null -ErrorAction Stop } | Should -Throw
            }
            finally {
                Remove-Item -Path $testDir.FullName -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Function implementation' {
        It 'Should use Join-Path for path construction' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'Join-Path'
        }

        It 'Should format dates with yyyy-MM-dd pattern' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'yyyy-MM-dd'
        }

        It 'Should use Get-Date for timestamp' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'Get-Date'
        }

        It 'Should use Out-File for writing' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'Out-File'
        }

        It 'Should use -Append flag for appending' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\-Append'
        }

        It 'Should use ShouldProcess for WhatIf support' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'ShouldProcess'
        }

        It 'Should create Log_Filename variable in begin block' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'Log_Filename'
        }

        It 'Should include .log file extension' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\.log'
        }

        It 'Should process pipeline input via $_' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\$_'
        }

        It 'Should use named parameters in Out-File call' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '-FilePath'
        }
    }

    Context 'Filename construction logic' {
        It 'Should combine basename with date in filename' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\$Basename'
            $scriptContent | Should -Match 'yyyy-MM-dd'
        }

        It 'Should use directory from Directory parameter' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\$Directory'
        }

        It 'Should construct path with proper separators' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'Join-Path'
        }
    }

    Context 'ShouldProcess behavior' {
        It 'Should support -Confirm parameter' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine
            $commandInfo.Parameters['Confirm'] | Should -Not -BeNullOrEmpty
        }

        It 'Should support -WhatIf parameter' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine
            $commandInfo.Parameters['WhatIf'] | Should -Not -BeNullOrEmpty
        }

        It 'Should use ShouldProcess method in process block' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'ShouldProcess'
            $scriptContent | Should -Match 'process\s*\{'
        }
    }

    Context 'Return behavior' {
        It 'Should return void (no output)' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\[OutputType\(\[void\]\)\]'
        }

        It 'Should not have explicit return statements with values' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $ReturnMatches = [regex]::Matches($scriptContent, 'return\s+\$')
            $ReturnMatches.Count | Should -Be 0
        }
    }

    Context 'Help documentation' {
        It 'Should have help available' {
            $help = Get-Help -Name Out-TVADCLogLine -ErrorAction SilentlyContinue
            $help | Should -Not -BeNullOrEmpty
        }

        It 'Should have non-empty synopsis' {
            $help = Get-Help -Name Out-TVADCLogLine -ErrorAction SilentlyContinue
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It 'Should document parameters' {
            $help = Get-Help -Name Out-TVADCLogLine -Full -ErrorAction SilentlyContinue
            $help.Parameters | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Advanced function features' {
        It 'Should have CmdletBinding for advanced function behavior' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match '\[CmdletBinding\('
        }

        It 'Should use Out-File with proper parameters' {
            $commandInfo = Get-Command -Name Out-TVADCLogLine

            $scriptContent = $commandInfo.ScriptBlock.ToString()
            $scriptContent | Should -Match 'Out-File'
            $scriptContent | Should -Match '-FilePath'
            $scriptContent | Should -Match '-Append'
        }
    }

    Context 'File output behavior' {
        BeforeEach {
            Mock Get-Date { [datetime]'2024-06-07' }
        }

        It 'writes pipeline input to a dated logfile with the configured basename' {
            $LogDirectory = New-Item -Path (Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid())) -ItemType Directory

            $Result = 'Started' | Out-TVADCLogLine -Directory $LogDirectory.FullName -Basename 'Sync'
            $LogFile = Join-Path -Path $LogDirectory.FullName -ChildPath 'Sync2024-06-07.log'

            $Result | Should -BeNullOrEmpty
            Test-Path -Path $LogFile | Should -BeTrue
            Get-Content -Path $LogFile | Should -Be 'Started'
        }

        It 'appends entries to the same logfile' {
            $LogDirectory = New-Item -Path (Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid())) -ItemType Directory
            $LogFile = Join-Path -Path $LogDirectory.FullName -ChildPath 'TeamViewerADC2024-06-07.log'

            'First' | Out-TVADCLogLine -Directory $LogDirectory.FullName
            'Second' | Out-TVADCLogLine -Directory $LogDirectory.FullName

            Get-Content -Path $LogFile | Should -Be @('First', 'Second')
        }

        It 'writes each pipeline entry independently' {
            $LogDirectory = New-Item -Path (Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid())) -ItemType Directory
            $Entries = @('First', 'Second', 'Third')

            $Entries | Out-TVADCLogLine -Directory $LogDirectory.FullName

            $LogFile = Join-Path -Path $LogDirectory.FullName -ChildPath 'TeamViewerADC2024-06-07.log'
            Get-Content -Path $LogFile | Should -Be $Entries
        }

        It 'does not create a logfile with WhatIf' {
            $LogDirectory = New-Item -Path (Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid())) -ItemType Directory
            $LogFile = Join-Path -Path $LogDirectory.FullName -ChildPath 'TeamViewerADC2024-06-07.log'

            'Skipped' | Out-TVADCLogLine -Directory $LogDirectory.FullName -WhatIf

            Test-Path -Path $LogFile | Should -BeFalse
        }
    }
}
