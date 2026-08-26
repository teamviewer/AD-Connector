function Sync-TVADCGuiScheduledSyncData {
    [CmdletBinding()]

    [OutputType([void])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]
        $Data,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]
        $Locale
    )

    $SchedTask = Get-TVADCScheduledTask
    $SchedTask_Enabled = [bool]($SchedTask)

    if ($SchedTask_Enabled) {
        $Data.StatusMessage = $Locale.ScheduledSyncEnabled
    }
    else {
        $Data.StatusMessage = $Locale.ScheduledSyncDisabled
    }

    if (-not $Data.IsEnabled) {
        $Data.Interval = (Get-TVADCScheduledInterval -Task $SchedTask).TotalHours
        $Data.LogDirectory = Get-TVADCScheduledTaskLogDirectory -Task $SchedTask
    }

    $Data.IsEnabled = $SchedTask_Enabled
    $Data.IsNotEnabled = (-not $SchedTask_Enabled)
}
