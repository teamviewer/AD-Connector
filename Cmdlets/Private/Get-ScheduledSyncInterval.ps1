 $scheduledTaskDefaultInterval = (New-TimeSpan -Hours 24)

function Get-ScheduledSyncInterval($task) {
    if ($task -and $task.Triggers.Repetition.Interval) {
        return ([Xml.XmlConvert]::ToTimeSpan($task.Triggers.Repetition.Interval))
    }
    else {
        return $scheduledTaskDefaultInterval
    }
}
