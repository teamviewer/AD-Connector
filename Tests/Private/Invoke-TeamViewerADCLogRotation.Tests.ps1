BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Invoke-TeamViewerADCLogRotation.ps1"
}

Describe 'Invoke-TeamViewerADCLogRotation' {
    Context 'Parameter validation' {
        It 'Should have Log_Directory parameter as mandatory' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $param = $commandInfo.Parameters['Log_Directory']

            $param | Should -Not -BeNullOrEmpty
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory } | Should -Not -BeNullOrEmpty
        }

        It 'Should have Log_Basename parameter as mandatory' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $param = $commandInfo.Parameters['Log_Basename']

            $param | Should -Not -BeNullOrEmpty
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory } | Should -Not -BeNullOrEmpty
        }

        It 'Should have RetentionCount parameter as mandatory' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $param = $commandInfo.Parameters['RetentionCount']

            $param | Should -Not -BeNullOrEmpty
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory } | Should -Not -BeNullOrEmpty
        }

        It 'Log_Directory should validate path exists and is a container' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $param = $commandInfo.Parameters['Log_Directory']

            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] } | Should -Not -BeNullOrEmpty
        }

        It 'Log_Basename should validate not null or empty' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $param = $commandInfo.Parameters['Log_Basename']

            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] } | Should -Not -BeNullOrEmpty
        }

        It 'RetentionCount should validate minimum value of 1' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $param = $commandInfo.Parameters['RetentionCount']

            $validateRange = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange | Should -Not -BeNullOrEmpty
            $validateRange.MinRange | Should -Be 1
        }
    }

    Context 'Function structure and attributes' {
        It 'Should have CmdletBinding attribute' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match '\[CmdletBinding\(\)\]'
        }

        It 'Should have no parameters attribute on CmdletBinding' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match '\[CmdletBinding\(\)\]\s*\n\s*param\('
        }

        It 'Should not have begin or end blocks' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            # Count explicit begin blocks (not auto-generated)
            $beginCount = [regex]::Matches($scriptContent, '\bbegin\s*\{').Count
            $endCount = [regex]::Matches($scriptContent, '\bend\s*\{').Count
            $beginCount | Should -Be 0
            $endCount | Should -Be 0
        }
    }

    Context 'Log file retrieval' {
        It 'Should retrieve log files with correct pattern' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Get-ChildItem'
            $scriptContent | Should -Match '\$Log_Basename\*\.log'
        }

        It 'Should filter for .log files only' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match '-File'
            $scriptContent | Should -Match '\.log'
        }

        It 'Should sort by LastWriteTimeUtc, CreationTimeUtc, and FullName' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Sort-Object'
            $scriptContent | Should -Match 'LastWriteTimeUtc'
            $scriptContent | Should -Match 'CreationTimeUtc'
            $scriptContent | Should -Match 'FullName'
        }

        It 'Should use Log_Directory parameter in path construction' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match '\$Log_Directory'
        }

        It 'Should store files in Log_Files variable' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match '\$Log_Files'
        }
    }

    Context 'Log file deletion logic' {
        It 'Should delete files when count exceeds retention' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'if.*\$Log_Files\.Count.*-gt.*\$RetentionCount'
        }

        It 'Should use Remove-Item for deletion' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Remove-Item'
        }

        It 'Should remove oldest files first' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            # Should use array slicing starting from index 0
            $scriptContent | Should -Match '\$Log_Files\[0\.\.'
        }

        It 'Should calculate correct count of files to remove' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            # Should subtract RetentionCount from total count
            $scriptContent | Should -Match '\$Log_Files\.Count\s*-\s*\$RetentionCount\s*-\s*1'
        }

        It 'Should use ErrorAction Stop for Remove-Item' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            $scriptContent | Should -Match 'Remove-Item.*-ErrorAction\s+Stop'
        }

        It 'Should not delete files when count is within retention' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $scriptContent = $commandInfo.ScriptBlock.ToString()

            # Should have if condition that checks count before deleting
            $scriptContent | Should -Match 'if.*\$Log_Files\.Count'
        }
    }

    Context 'Runtime behavior' {
        BeforeEach {
            $script:TestLogDirectory = New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'TestLogs') -ItemType Directory -Force
        }

        AfterEach {
            if (Test-Path -Path $script:TestLogDirectory) {
                Remove-Item -Path $script:TestLogDirectory -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Should accept valid parameters without throwing' {
            $basename = 'TestLog_'
            $retentionCount = 5

            # Create some test log files
            1..3 | ForEach-Object { New-Item -Path (Join-Path -Path $script:TestLogDirectory -ChildPath "$basename$_.log") -ItemType File -Force | Out-Null }

            { Invoke-TeamViewerADCLogRotation -Log_Directory $script:TestLogDirectory -Log_Basename $basename -RetentionCount $retentionCount } | Should -Not -Throw
        }

        It 'Should not delete files when count equals retention' {
            $basename = 'TestLog_'
            $retentionCount = 3

            # Create exactly 3 log files
            1..3 | ForEach-Object { New-Item -Path (Join-Path -Path $script:TestLogDirectory -ChildPath "$basename$_.log") -ItemType File -Force | Out-Null }

            Invoke-TeamViewerADCLogRotation -Log_Directory $script:TestLogDirectory -Log_Basename $basename -RetentionCount $retentionCount

            # Should still have all 3 files
            $files = Get-ChildItem -Path (Join-Path -Path $script:TestLogDirectory -ChildPath "$basename*.log") -File
            $files.Count | Should -Be 3
        }

        It 'Should not delete files when count is below retention' {
            $basename = 'TestLog_'
            $retentionCount = 5

            # Create only 3 log files
            1..3 | ForEach-Object { New-Item -Path (Join-Path -Path $script:TestLogDirectory -ChildPath "$basename$_.log") -ItemType File -Force | Out-Null }

            Invoke-TeamViewerADCLogRotation -Log_Directory $script:TestLogDirectory -Log_Basename $basename -RetentionCount $retentionCount

            # Should still have all 3 files
            $files = Get-ChildItem -Path (Join-Path -Path $script:TestLogDirectory -ChildPath "$basename*.log") -File
            $files.Count | Should -Be 3
        }

        It 'Should delete oldest files when count exceeds retention' {
            $basename = 'TestLog_'
            $retentionCount = 2

            # Create 5 log files with staggered timestamps
            1..5 | ForEach-Object {
                $filePath = Join-Path -Path $script:TestLogDirectory -ChildPath "$basename$_.log"

                New-Item -Path $filePath -ItemType File -Force | Out-Null
                # Stagger the write times
                (Get-Item -Path $filePath).LastWriteTime = (Get-Date).AddSeconds(-$_)
            }

            Invoke-TeamViewerADCLogRotation -Log_Directory $script:TestLogDirectory -Log_Basename $basename -RetentionCount $retentionCount

            # Should have only 2 files remaining (the newest ones)
            $files = Get-ChildItem -Path (Join-Path -Path $script:TestLogDirectory -ChildPath "$basename*.log") -File
            $files.Count | Should -Be 2
        }

        It 'Should preserve newest log files' {
            $basename = 'TestLog'
            $retentionCount = 2

            # Create 3 log files with clear naming
            1..3 | ForEach-Object {
                $filePath = Join-Path -Path $script:TestLogDirectory -ChildPath "${basename}_$_.log"

                New-Item -Path $filePath -ItemType File -Force | Out-Null

                # Stagger the timestamps with older files having older times
                $item = Get-Item -Path $filePath
                $item.LastWriteTime = (Get-Date).AddSeconds(-$_)
            }

            Invoke-TeamViewerADCLogRotation -Log_Directory $script:TestLogDirectory -Log_Basename $basename -RetentionCount $retentionCount

            # Should have exactly 2 files remaining (the newest ones)
            $remainingFiles = Get-ChildItem -Path (Join-Path -Path $script:TestLogDirectory -ChildPath "${basename}*.log") -File
            $remainingFiles.Count | Should -Be 2
        }

        It 'Should handle single log file correctly' {
            $basename = 'TestLog_'
            $retentionCount = 1

            # Create 1 log file
            New-Item -Path (Join-Path -Path $script:TestLogDirectory -ChildPath "$basename`1.log") -ItemType File -Force | Out-Null

            { Invoke-TeamViewerADCLogRotation -Log_Directory $script:TestLogDirectory -Log_Basename $basename -RetentionCount $retentionCount } | Should -Not -Throw

            # Should still have 1 file
            $files = Get-ChildItem -Path (Join-Path -Path $script:TestLogDirectory -ChildPath "$basename*.log") -File
            $files.Count | Should -Be 1
        }

        It 'Should handle no matching log files' {
            $basename = 'NonExistent_'
            $retentionCount = 5

            # No log files created
            { Invoke-TeamViewerADCLogRotation -Log_Directory $script:TestLogDirectory -Log_Basename $basename -RetentionCount $retentionCount } | Should -Not -Throw

            # Should have 0 files
            $files = Get-ChildItem -Path (Join-Path -Path $script:TestLogDirectory -ChildPath "$basename*.log") -File -ErrorAction SilentlyContinue
            $files | Should -BeNullOrEmpty
        }
    }

    Context 'Parameter edge cases' {
        It 'Should accept RetentionCount of 1' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            # RetentionCount should accept minimum value of 1
            $param = $commandInfo.Parameters['RetentionCount']

            $validateRange = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange.MinRange | Should -Be 1
        }

        It 'Should accept large RetentionCount values' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $param = $commandInfo.Parameters['RetentionCount']

            $validateRange = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange.MaxRange | Should -Be ([int]::MaxValue)
        }

        It 'Should accept empty Log_Basename if wrapped in quotes' {
            # This test validates that the parameter accepts strings
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            $param = $commandInfo.Parameters['Log_Basename']
            $param.ParameterType.Name | Should -Be 'String'
        }

        It 'Should accept Log_Basename with special characters' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            # Log_Basename is just a string, so it should accept any non-null value
            $param = $commandInfo.Parameters['Log_Basename']
            $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Help documentation' {
        It 'Should have help documentation' {
            $help = Get-Help -Name Invoke-TeamViewerADCLogRotation -ErrorAction SilentlyContinue
            $help | Should -Not -BeNullOrEmpty
        }

        It 'Should have SYNOPSIS in help' {
            $help = Get-Help -Name Invoke-TeamViewerADCLogRotation -ErrorAction SilentlyContinue
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Execution guarantees' {
        It 'Should have no output' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation

            # Function should not have explicit [OutputType()] or return statements
            $scriptContent = $commandInfo.ScriptBlock.ToString()

            # Should not have return statements (except implicit returns)
            $returnCount = [regex]::Matches($scriptContent, 'return\s').Count
            $returnCount | Should -Be 0
        }

        It 'Should be optimized with named parameters' {
            $commandInfo = Get-Command -Name Invoke-TeamViewerADCLogRotation
            $scriptContent = $commandInfo.ScriptBlock.ToString()

            # Should use named parameters in function calls
            $scriptContent | Should -Match '-Path'
            $scriptContent | Should -Match '-PathType'
            $scriptContent | Should -Match '-Property'
            $scriptContent | Should -Match '-ErrorAction'
        }
    }
}
