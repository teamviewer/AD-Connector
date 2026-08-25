BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TeamViewerADCScheduledSynchronization.ps1"
}

Describe 'Get-TeamViewerADCScheduledSynchronization' {
    It 'Should return the scheduled synchronization task' {
        $scheduledTask = [pscustomobject]@{
            TaskName = 'ScheduledSynchronization'
            TaskPath = '\TeamViewerADC\'
        }

        Mock Get-ScheduledTask { return $scheduledTask }

        $result = Get-TeamViewerADCScheduledSynchronization

        $result | Should -Be $scheduledTask

        Assert-MockCalled Get-ScheduledTask -Times 1 -Scope It -ParameterFilter {
            $TaskPath -eq '\TeamViewerADC\' -and $TaskName -eq 'ScheduledSynchronization' -and $ErrorAction -eq 'SilentlyContinue'
        }
    }

    It 'Should return no task when the scheduled synchronization task does not exist' {
        Mock Get-ScheduledTask { return $null }

        $result = Get-TeamViewerADCScheduledSynchronization

        $result | Should -BeNullOrEmpty
        Assert-MockCalled Get-ScheduledTask -Times 1 -Scope It -ParameterFilter {
            $TaskPath -eq '\TeamViewerADC\' -and $TaskName -eq 'ScheduledSynchronization' -and $ErrorAction -eq 'SilentlyContinue'
        }
    }
}
