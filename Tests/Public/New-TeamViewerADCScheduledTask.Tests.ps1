BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TeamViewerADCScheduledTask.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Public\New-TeamViewerADCScheduledTask.ps1"
}

Describe 'New-TeamViewerADCScheduledTask' {
    BeforeEach {
        Mock Get-TeamViewerADCScheduledTask { return $null }
        Mock New-ScheduledTaskAction { return 'Action' }
        Mock New-ScheduledTaskTrigger { return 'Trigger' }
        Mock New-ScheduledTaskPrincipal { return 'Principal' }
        Mock Register-ScheduledTask -RemoveParameterType Action, Trigger, Principal { return 'ScheduledTask' }
    }

    It 'declares its task output contract, interval validation, and WhatIf support' {
        $CommandInfo = Get-Command -Name New-TeamViewerADCScheduledTask

        $CommandInfo.OutputType.Type | Should -Contain ([Microsoft.Management.Infrastructure.CimInstance])
        $CommandInfo.Parameters.Keys | Should -Contain 'WhatIf'
        $CommandInfo.Parameters.Keys | Should -Contain 'Interval'

        { New-TeamViewerADCScheduledTask -Interval 0 } | Should -Throw
        { New-TeamViewerADCScheduledTask -Interval 25 } | Should -Throw
    }

    It 'registers the scheduled task when it does not exist' {
        $Result = New-TeamViewerADCScheduledTask -Interval 12

        $Result | Should -Be 'ScheduledTask'

        Should -Invoke -CommandName New-ScheduledTaskAction -Times 1 -Exactly -Scope It -ParameterFilter {
            $Execute -eq 'Powershell.exe' -and $WorkingDirectory -like '*\Cmdlets\Public' -and $Argument -match '^-NoProfile -NoLogo -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass ' -and $Argument -match "Invoke-TeamViewerADCSynchronization.ps1'; Invoke-TeamViewerADCSynchronization"
        }
        Should -Invoke -CommandName New-ScheduledTaskTrigger -Times 1 -Exactly -Scope It -ParameterFilter {
            $RepetitionInterval -eq (New-TimeSpan -Hours 12)
        }
        Should -Invoke -CommandName New-ScheduledTaskPrincipal -Times 1 -Exactly -Scope It -ParameterFilter {
            $UserId -eq 'NETWORKSERVICE' -and $LogonType -eq 'ServiceAccount'
        }
        Should -Invoke -CommandName Register-ScheduledTask -Times 1 -Exactly -Scope It -ParameterFilter {
            $TaskPath -eq '\TeamViewerADC\' -and $TaskName -eq 'Automatic Synchronization' -and $Action -eq 'Action' -and $Trigger -eq 'Trigger' -and $Principal -eq 'Principal'
        }
    }

    It 'returns the existing scheduled task without registering another one' {
        $ScheduledTask = [pscustomobject]@{ TaskName = 'Automatic Synchronization' }

        Mock Get-TeamViewerADCScheduledTask { return $ScheduledTask }

        $Result = New-TeamViewerADCScheduledTask

        $Result | Should -Be $ScheduledTask
        Should -Invoke -CommandName New-ScheduledTaskAction -Times 0 -Exactly -Scope It
        Should -Invoke -CommandName New-ScheduledTaskTrigger -Times 0 -Exactly -Scope It
        Should -Invoke -CommandName New-ScheduledTaskPrincipal -Times 0 -Exactly -Scope It
        Should -Invoke -CommandName Register-ScheduledTask -Times 0 -Exactly -Scope It
    }

    It 'does not register a scheduled task when invoked with WhatIf' {
        New-TeamViewerADCScheduledTask -WhatIf

        Should -Invoke -CommandName New-ScheduledTaskAction -Times 0 -Exactly -Scope It
        Should -Invoke -CommandName New-ScheduledTaskTrigger -Times 0 -Exactly -Scope It
        Should -Invoke -CommandName New-ScheduledTaskPrincipal -Times 0 -Exactly -Scope It
        Should -Invoke -CommandName Register-ScheduledTask -Times 0 -Exactly -Scope It
    }
}
