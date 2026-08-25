function Get-TeamViewerADCScheduledSynchronization() {
    [CmdletBinding()]

    param()

    begin {
        $SchedTask_Path = '\TeamViewerADC\'
        $SchedTask_Name = 'ScheduledSynchronization'
    }

    process {
        return (Get-ScheduledTask -TaskPath $SchedTask_Path -TaskName $SchedTask_Name -ErrorAction SilentlyContinue)
    }
}
