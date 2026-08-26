function Get-TVADCScheduledTask {
    [CmdletBinding()]

    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]

    param()

    $SchedTask_Path = '\TeamViewerADC\'
    $SchedTask_Name = 'Automatic Synchronization'

    return (Get-ScheduledTask -TaskPath $SchedTask_Path -TaskName $SchedTask_Name -ErrorAction SilentlyContinue)
}
