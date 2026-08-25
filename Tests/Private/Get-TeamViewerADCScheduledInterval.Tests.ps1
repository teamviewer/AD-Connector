BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TeamViewerADCScheduledInterval.ps1"
}

Describe 'Get-TeamViewerADCScheduledInterval' {
    It 'declares TimeSpan as its output type' {
        $CommandInfo = Get-Command -Name Get-TeamViewerADCScheduledInterval

        $OutputType = $CommandInfo.OutputType.Type

        $OutputType | Should -Contain ([TimeSpan])
    }

    It 'converts the scheduled task repetition interval to a TimeSpan' {
        $Task = [pscustomobject]@{
            Triggers = [pscustomobject]@{
                Repetition = [pscustomobject]@{
                    Interval = 'PT6H'
                }
            }
        }

        $Result = Get-TeamViewerADCScheduledInterval -Task $Task

        $Result | Should -Be ([TimeSpan]::FromHours(6))
    }

    It 'converts ISO duration components including days and minutes' {
        $Task = [pscustomobject]@{
            Triggers = [pscustomobject]@{
                Repetition = [pscustomobject]@{
                    Interval = 'P1DT30M'
                }
            }
        }

        $Result = $Task | Get-TeamViewerADCScheduledInterval

        $Result | Should -Be ([TimeSpan]::FromDays(1).Add([TimeSpan]::FromMinutes(30)))
    }

    It 'returns a daily interval when no task is available' {
        $Result = Get-TeamViewerADCScheduledInterval -Task $null

        $Result | Should -Be ([TimeSpan]::FromHours(24))
    }

    It 'returns a daily interval when the task has no repetition interval' {
        $Task = [pscustomobject]@{
            Triggers = [pscustomobject]@{
                Repetition = [pscustomobject]@{
                    Interval = $null
                }
            }
        }

        $Result = Get-TeamViewerADCScheduledInterval -Task $Task

        $Result | Should -Be ([TimeSpan]::FromHours(24))
    }

    It 'returns a daily interval when the task has no triggers' {
        $Task = [pscustomobject]@{}

        $Result = Get-TeamViewerADCScheduledInterval -Task $Task

        $Result | Should -Be ([TimeSpan]::FromHours(24))
    }

    It 'formats each pipeline task independently' {
        $FirstTask = [pscustomobject]@{
            Triggers = [pscustomobject]@{ Repetition = [pscustomobject]@{ Interval = 'PT1H' } }
        }
        $SecondTask = [pscustomobject]@{
            Triggers = [pscustomobject]@{ Repetition = [pscustomobject]@{ Interval = 'PT2H' } }
        }

        $Result = @($FirstTask, $SecondTask) | Get-TeamViewerADCScheduledInterval

        $Result | Should -HaveCount 2
        $Result[0] | Should -Be ([TimeSpan]::FromHours(1))
        $Result[1] | Should -Be ([TimeSpan]::FromHours(2))
    }

    It 'propagates invalid XML duration values' {
        $Task = [pscustomobject]@{
            Triggers = [pscustomobject]@{
                Repetition = [pscustomobject]@{ Interval = 'not-a-duration' }
            }
        }

        { Get-TeamViewerADCScheduledInterval -Task $Task -ErrorAction Stop } | Should -Throw
    }

    It 'declares Task as pipeline input' {
        $Parameter = (Get-Command Get-TeamViewerADCScheduledInterval).Parameters['Task']

        $Parameter.ParameterType | Should -Be ([object])
        $Parameter.Attributes.ValueFromPipeline | Should -Contain $true
    }
}
