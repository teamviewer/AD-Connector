 $scheduledTaskPath = '\TeamViewer\'
 $scheduledTaskName = 'TeamViewer AD Connector'
 $scheduledTaskPrincipal = 'NETWORKSERVICE'
 $scheduledTaskCommand = "$(Join-Path (Get-Item "$PSScriptRoot\..") 'Invoke-Sync.ps1')"

function Install-ScheduledSync([TimeSpan] $interval, [string] $logdirectory) {
    if (!(Get-ScheduledSync)) {
        $command = $scheduledTaskCommand -replace ' ', '` '

        if ($logdirectory) {
            $command = "$($command) -LogfileDirectory '$logdirectory'"
        }

        $arguments = @(
            '-NoProfile',
            '-NoLogo',
            '-NonInteractive',
            '-WindowStyle Hidden',
            '-ExecutionPolicy Bypass'
            "-Command `"& { $command; exit `$LastExitCode }`""
        )

        $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ($arguments -join ' ') -WorkingDirectory ((Get-Item -Path "$PSScriptRoot").Parent.FullName)

        if ([Environment]::OSVersion.Version.Major -lt 10) {
            $trigger = (New-ScheduledTaskTrigger -Once -At ((Get-Date) + (New-TimeSpan -Minutes 1)) -RepetitionInterval $interval -RepetitionDuration ([TimeSpan]::MaxValue))
        }
        else {
            $trigger = (New-ScheduledTaskTrigger -Once -At ((Get-Date) + (New-TimeSpan -Minutes 1)) -RepetitionInterval $interval)
        }

        $principal = New-ScheduledTaskPrincipal -UserId $scheduledTaskPrincipal -LogonType ServiceAccount
        (Register-ScheduledTask -TaskPath $scheduledTaskPath -TaskName $scheduledTaskName -Action $action -Trigger $trigger -Principal $principal)
    }
}
