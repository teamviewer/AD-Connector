BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCScheduledTaskLogDirectory.ps1"
}

Describe 'Get-TVADCScheduledTaskLogDirectory' {
    BeforeEach {
        $script:DefaultLogDirectory = 'C:\TeamViewerADC\Logs'

        Mock Get-Item {
            return [pscustomobject]@{
                FullName = $script:DefaultLogDirectory
            }
        }
    }

    It 'declares a string output contract' {
        $CommandInfo = Get-Command -Name Get-TVADCScheduledTaskLogDirectory
        $TaskParameter = $CommandInfo.Parameters['Task']

        $CommandInfo.OutputType.Type | Should -Contain ([string])
        $CommandInfo.CmdletBinding | Should -BeTrue
        $TaskParameter.ParameterType | Should -Be ([object])

        $TaskParameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ValueFromPipeline
        } | Should -Not -BeNullOrEmpty
    }

    It 'returns the default log directory when no task is supplied' {
        $Result = Get-TVADCScheduledTaskLogDirectory

        $Result | Should -Be $script:DefaultLogDirectory
        Should -Invoke -CommandName Get-Item -Times 1 -Exactly -Scope It
    }

    It 'returns the default log directory for a null task' {
        $Result = Get-TVADCScheduledTaskLogDirectory -Task $null

        $Result | Should -Be $script:DefaultLogDirectory
    }

    It 'returns the default log directory when the task has no action arguments' {
        $Task = [pscustomobject]@{
            Actions = @([pscustomobject]@{})
        }

        $Result = Get-TVADCScheduledTaskLogDirectory -Task $Task

        $Result | Should -Be $script:DefaultLogDirectory
    }

    It 'returns the log directory configured in the task action arguments' {
        $Task = [pscustomobject]@{
            Actions = @([pscustomobject]@{
                    Arguments = "-NoProfile -Directory 'C:\Configured Logs'"
                })
        }

        $Result = Get-TVADCScheduledTaskLogDirectory -Task $Task

        $Result | Should -Be 'C:\Configured Logs'
    }

    It 'returns the default directory when the arguments do not configure logging' {
        $Task = [pscustomobject]@{
            Actions = @([pscustomobject]@{ Arguments = '-NoProfile' })
        }

        $Result = Get-TVADCScheduledTaskLogDirectory -Task $Task

        $Result | Should -Be $script:DefaultLogDirectory
    }

    It 'returns the default directory for an empty configured path' {
        $Task = [pscustomobject]@{
            Actions = @([pscustomobject]@{ Arguments = "-Directory ''" })
        }

        $Result = Get-TVADCScheduledTaskLogDirectory -Task $Task

        $Result | Should -Be $script:DefaultLogDirectory
    }

    It 'examines only the first task action' {
        $Task = [pscustomobject]@{
            Actions = @(
                [pscustomobject]@{ Arguments = '-NoProfile' }
                [pscustomobject]@{ Arguments = "-Directory 'C:\Second Action Logs'" }
            )
        }

        $Result = Get-TVADCScheduledTaskLogDirectory -Task $Task

        $Result | Should -Be $script:DefaultLogDirectory
    }

    It 'processes each task received from the pipeline' {
        $ConfiguredTask = [pscustomobject]@{
            Actions = @([pscustomobject]@{
                    Arguments = "-Directory 'C:\Configured Logs'"
                })
        }
        $UnconfiguredTask = [pscustomobject]@{ Actions = @() }

        $Result = @($ConfiguredTask, $UnconfiguredTask | Get-TVADCScheduledTaskLogDirectory)

        $Result | Should -Be @('C:\Configured Logs', $script:DefaultLogDirectory)
        Should -Invoke -CommandName Get-Item -Times 1 -Exactly -Scope It
    }
}
