# Copyright (c) 2018-2023 TeamViewer Germany GmbH
# See file LICENSE

$scheduledTaskPath = "\TeamViewer\"
$scheduledTaskName = "TeamViewer AD Connector"
$scheduledTaskPrincipal = "NETWORKSERVICE"
$scheduledTaskCommand = "$(Join-Path (Get-Item "$PSScriptRoot\..") "Invoke-Sync.ps1")"
$scheduledTaskDefaultInterval = (New-TimeSpan -Hours 24)
$scheduledTaskDefaultLogdirectory = (Get-Item "$PSScriptRoot\..")

function Get-ScheduledSync() {
    return (Get-ScheduledTask -TaskPath $scheduledTaskPath -TaskName $scheduledTaskName -ErrorAction SilentlyContinue)
}

function Get-ScheduledSyncInterval($task) {
    if ($task -And $task.Triggers.Repetition.Interval) {
        return ([Xml.XmlConvert]::ToTimeSpan($task.Triggers.Repetition.Interval))
    }
    else {
        return $scheduledTaskDefaultInterval
    }
}

function Get-ScheduledSyncLogDirectory($task) {
    if ($task -And $task.Actions -And $task.Actions[0].Arguments -match "\-LogfileDirectory '(?<directory>.+?)'") {
        return $Matches.directory
    }
    else {
        return $scheduledTaskDefaultLogdirectory
    }
}

function Install-ScheduledSync([TimeSpan] $interval, [string] $logdirectory) {
    if (!(Get-ScheduledSync)) {
        $command = $scheduledTaskCommand -Replace ' ','` '
        if ($logdirectory) {
            $command = "$($command) -LogfileDirectory '$logdirectory'"
        }
        $arguments = @(
            "-NoProfile",
            "-NoLogo",
            "-NonInteractive",
            "-WindowStyle Hidden",
            "-ExecutionPolicy Bypass"
            "-Command `"& { $command; exit `$LastExitCode }`""
        )
        $action = New-ScheduledTaskAction `
            -Execute "powershell.exe" `
            -Argument ($arguments -join " ") `
            -WorkingDirectory ((Get-Item -Path "$PSScriptRoot").Parent.FullName)
        if ([Environment]::OSVersion.Version.Major -lt 10) {
            $trigger = (New-ScheduledTaskTrigger -Once -At ((Get-Date) + (New-TimeSpan -Minutes 1)) `
                    -RepetitionInterval $interval -RepetitionDuration ([TimeSpan]::MaxValue))
        }
        else {
            $trigger = (New-ScheduledTaskTrigger -Once -At ((Get-Date) + (New-TimeSpan -Minutes 1)) `
                    -RepetitionInterval $interval)
        }
        $principal = New-ScheduledTaskPrincipal -UserID $scheduledTaskPrincipal -LogonType ServiceAccount
        (Register-ScheduledTask -TaskPath $scheduledTaskPath -TaskName $scheduledTaskName `
                -Action $action -Trigger $trigger -Principal $principal)
    }
}

function Uninstall-ScheduledSync() {
    if (Get-ScheduledSync) {
        (Unregister-ScheduledTask -TaskPath $scheduledTaskPath -TaskName $scheduledTaskName -Confirm:$false)
    }
}
