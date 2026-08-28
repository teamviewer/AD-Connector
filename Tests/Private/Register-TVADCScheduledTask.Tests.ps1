BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Register-TVADCScheduledTask.ps1"
}

Describe 'Register-TVADCScheduledTask' {
    It 'forwards the scheduled task parameters to Register-ScheduledTask' {
        $ExpectedAction = New-ScheduledTaskAction -Execute 'Powershell.exe'
        $ExpectedTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date)
        $ExpectedPrincipal = New-ScheduledTaskPrincipal -UserId 'NETWORKSERVICE' -LogonType ServiceAccount
        $ScheduledTask = [pscustomobject]@{ TaskName = 'Automatic Synchronization' }

        Mock Register-ScheduledTask { return $ScheduledTask }

        $Result = Register-TVADCScheduledTask -TaskPath '\TeamViewerADC\' -TaskName 'Automatic Synchronization' -Action $ExpectedAction -Trigger $ExpectedTrigger -Principal $ExpectedPrincipal

        $Result | Should -Be $ScheduledTask

        Should -Invoke -CommandName Register-ScheduledTask -Times 1 -Exactly -Scope It -ParameterFilter {
            $TaskPath -eq '\TeamViewerADC\' -and $TaskName -eq 'Automatic Synchronization' -and $Action -eq $ExpectedAction -and $Trigger -eq $ExpectedTrigger -and $Principal -eq $ExpectedPrincipal
        }
    }

    It 'declares an advanced function with the expected output type' {
        $CommandInfo = Get-Command -Name Register-TVADCScheduledTask

        $CommandInfo.CmdletBinding | Should -BeTrue
        $CommandInfo.OutputType.Type | Should -Contain ([Microsoft.Management.Infrastructure.CimInstance])
    }
}
