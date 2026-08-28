function Invoke-TVADCSync {
    [CmdletBinding()]

    [OutputType([hashtable])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$Configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$Progress
    )

    Add-TVADCSyncLogLine ('-' * 50)
    Add-TVADCSyncLogLine 'Starting synchronization...'
    Add-TVADCSyncLogLine "Version $ScriptVersion ($([environment]::OSVersion.VersionString), PS $($PSVersionTable.PSVersion))"

    if ($Configuration.TestRun) {
        Add-TVADCSyncLogLine "Mode 'Test Run' is active. No modifications will be made."
    }

    if ([string]::IsNullOrWhiteSpace($Configuration.Api_Uri)) {
        Set-TeamViewerAPIUri -Default $true
    }
    else {
        Set-TeamViewerAPIUri -NewUri $Configuration.Api_Uri
    }

    $Sync_Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $Sync_Context = @{ }

    Invoke-TVADCSyncPrework -Sync_Context $Sync_Context -Configuration $Configuration -Progress $Progress
    Invoke-TVADCSyncUser -Sync_Context $Sync_Context -Configuration $Configuration -Progress $Progress

    if ($Configuration.Sync_IncludeUserGroups) {
        Invoke-TVADCSyncUserGroup -Sync_Context $Sync_Context -Configuration $Configuration -Progress $Progress
    }

    $Sync_Stopwatch.Stop()

    Out-TVADCSyncProgress -Handler $Progress -Percent 100 -Operation 'Completed synchronization.'

    Write-Output @{ Activity = 'Total'; Statistics = @{}; Duration = $Sync_Stopwatch.Elapsed }
}
