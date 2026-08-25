 $scheduledTaskDefaultLogdirectory = (Get-Item "$PSScriptRoot\..")

function Get-ScheduledSyncLogDirectory($task) {
    if ($task -and $task.Actions -and $task.Actions[0].Arguments -match "\-LogfileDirectory '(?<directory>.+?)'") {
        return $Matches.directory
    }
    else {
        return $scheduledTaskDefaultLogdirectory
    }
}
