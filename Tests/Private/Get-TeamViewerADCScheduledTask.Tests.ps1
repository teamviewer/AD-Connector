BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TeamViewerADCScheduledTask.ps1"
}

Describe 'Get-TeamViewerADCScheduledTask' {
    It 'returns the scheduled synchronization task' {
        $ScheduledTask = [pscustomobject]@{
            TaskName = 'Automatic Synchronization'
            TaskPath = '\TeamViewerADC\'
        }

        Mock Get-ScheduledTask { return $ScheduledTask }

        $Result = Get-TeamViewerADCScheduledTask

        $Result | Should -Be $ScheduledTask
        Should -Invoke -CommandName Get-ScheduledTask -Times 1 -Exactly -Scope It -ParameterFilter {
            $TaskPath -eq '\TeamViewerADC\' -and $TaskName -eq 'Automatic Synchronization' -and $ErrorAction -eq 'SilentlyContinue'
        }
    }

    It 'returns no task when the scheduled synchronization task does not exist' {
        Mock Get-ScheduledTask { return $null }

        $Result = Get-TeamViewerADCScheduledTask

        $Result | Should -BeNullOrEmpty
        Should -Invoke -CommandName Get-ScheduledTask -Times 1 -Exactly -Scope It -ParameterFilter {
            $TaskPath -eq '\TeamViewerADC\' -and $TaskName -eq 'Automatic Synchronization' -and $ErrorAction -eq 'SilentlyContinue'
        }
    }

    It 'declares a parameterless advanced function with the expected output type' {
        $CommandInfo = Get-Command -Name Get-TeamViewerADCScheduledTask

        $CommandInfo.CmdletBinding | Should -BeTrue
        $CommandInfo.Parameters.Keys | Should -Not -Contain 'TaskPath'
        $CommandInfo.OutputType.Type | Should -Contain ([Microsoft.Management.Infrastructure.CimInstance])
    }
}
