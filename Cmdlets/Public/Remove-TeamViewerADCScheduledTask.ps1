function Remove-TeamViewerADCScheduledTask {
    [CmdletBinding(SupportsShouldProcess = $true)]

    [OutputType([void])]

    param()

    $ScheduledTask = Get-TVADCScheduledTask

    if ($ScheduledTask -and $PSCmdlet.ShouldProcess($ScheduledTask.TaskName, 'Unregister scheduled task.')) {
        Unregister-ScheduledTask -TaskPath $ScheduledTask.TaskPath -TaskName $ScheduledTask.TaskName -Confirm:$false
    }
}
