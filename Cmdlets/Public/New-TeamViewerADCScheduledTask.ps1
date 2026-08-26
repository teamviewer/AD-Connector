function New-TeamViewerADCScheduledTask {
    [CmdletBinding(SupportsShouldProcess = $true)]

    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]

    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 24)]
        [int]$Interval = 24
    )

    $ScheduledTask = Get-TVADCScheduledTask

    if ($ScheduledTask) {
        return $ScheduledTask
    }

    $SchedTask_Path = '\TeamViewerADC\'
    $SchedTask_Name = 'Automatic Synchronization'
    $SchedTask_Command = Join-Path -Path $PSScriptRoot -ChildPath 'Invoke-TeamViewerADCSynchronization.ps1'

    $Posh_Arguments = @(
        '-NoProfile',
        '-NoLogo',
        '-NonInteractive',
        '-WindowStyle Hidden',
        '-ExecutionPolicy Bypass',
        "-Command `"& { . '$SchedTask_Command'; Invoke-TeamViewerADCSynchronization; exit `$LastExitCode }`""
    )

    if ($PSCmdlet.ShouldProcess($SchedTask_Name, 'Register scheduled task.')) {
        $SchedTask_Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument ($Posh_Arguments -join ' ') -WorkingDirectory $PSScriptRoot
        $StartTime = (Get-Date).AddMinutes(1)
        $SchedTask_Interval = New-TimeSpan -Hours $Interval

        if ([Environment]::OSVersion.Version.Major -lt 10) {
            $SchedTask_Trigger = New-ScheduledTaskTrigger -Once -At $StartTime -RepetitionInterval $SchedTask_Interval -RepetitionDuration ([TimeSpan]::MaxValue)
        }
        else {
            $SchedTask_Trigger = New-ScheduledTaskTrigger -Once -At $StartTime -RepetitionInterval $SchedTask_Interval
        }

        $SchedTask_Principal = New-ScheduledTaskPrincipal -UserId 'NETWORKSERVICE' -LogonType ServiceAccount

        return Register-ScheduledTask -TaskPath $SchedTask_Path -TaskName $SchedTask_Name -Action $SchedTask_Action -Trigger $SchedTask_Trigger -Principal $SchedTask_Principal
    }
}
