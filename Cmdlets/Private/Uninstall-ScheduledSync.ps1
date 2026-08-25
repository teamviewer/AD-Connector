function Uninstall-ScheduledSync() {
    if (Get-ScheduledSync) {
        (Unregister-ScheduledTask -TaskPath $scheduledTaskPath -TaskName $scheduledTaskName -Confirm:$false)
    }
}
