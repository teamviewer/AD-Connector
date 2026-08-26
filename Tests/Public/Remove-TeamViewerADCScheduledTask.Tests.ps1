BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCScheduledTask.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Public\Remove-TeamViewerADCScheduledTask.ps1"
}

Describe 'Remove-TeamViewerADCScheduledTask' {
    BeforeEach {
        $ScheduledTask = [pscustomobject]@{
            TaskName = 'Automatic Synchronization'
            TaskPath = '\TeamViewerADC\'
        }

        Mock Get-TVADCScheduledTask { return $ScheduledTask }
        Mock Unregister-ScheduledTask {}
    }

    It 'declares a void output contract and supports WhatIf' {
        $CommandInfo = Get-Command -Name Remove-TeamViewerADCScheduledTask

        $CommandInfo.OutputType.Type | Should -Contain ([void])
        $CommandInfo.Parameters.Keys | Should -Contain 'WhatIf'
    }

    It 'unregisters the scheduled task when it exists' {
        Remove-TeamViewerADCScheduledTask

        Should -Invoke -CommandName Get-TVADCScheduledTask -Times 1 -Exactly -Scope It
        Should -Invoke -CommandName Unregister-ScheduledTask -Times 1 -Exactly -Scope It -ParameterFilter {
            $TaskPath -eq '\TeamViewerADC\' -and $TaskName -eq 'Automatic Synchronization' -and -not $Confirm
        }
    }

    It 'does not unregister a task when no scheduled task exists' {
        Mock Get-TVADCScheduledTask { return $null }

        Remove-TeamViewerADCScheduledTask

        Should -Invoke -CommandName Get-TVADCScheduledTask -Times 1 -Exactly -Scope It
        Should -Invoke -CommandName Unregister-ScheduledTask -Times 0 -Exactly -Scope It
    }

    It 'does not unregister a task when invoked with WhatIf' {
        Remove-TeamViewerADCScheduledTask -WhatIf

        Should -Invoke -CommandName Unregister-ScheduledTask -Times 0 -Exactly -Scope It
    }
}
