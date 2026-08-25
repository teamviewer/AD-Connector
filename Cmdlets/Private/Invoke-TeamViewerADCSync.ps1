function Invoke-TeamViewerADCSync {
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

    Add-TeamViewerADCSyncLogLine ('-' * 50)
    Add-TeamViewerADCSyncLogLine 'Starting synchronization...'
    Add-TeamViewerADCSyncLogLine "Version $ScriptVersion ($([environment]::OSVersion.VersionString), PS $($PSVersionTable.PSVersion))"

    if ($Configuration.TestRun) {
        Add-TeamViewerADCSyncLogLine "Mode 'Test Run' is active. No modifications will be made."
    }

    $Sync_Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $Sync_Context = @{ }

    Invoke-TeamViewerADCSyncPrework -Sync_Context $Sync_Context -Configuration $Configuration -Progress $Progress
    Invoke-TeamViewerADCSyncUser -Sync_Context $Sync_Context -Configuration $Configuration -Progress $Progress

    if ($Configuration.EnableUserGroupsSync) {
        Invoke-TeamViewerADCSyncUserGroup -Sync_Context $Sync_Context -Configuration $Configuration -Progress $Progress
    }

    $Sync_Stopwatch.Stop()
    Out-TeamViewerADCSyncProgress -Handler $Progress -Percent 100 -Operation 'Completed synchronization.'

    Write-Output @{ Activity = 'Total'; Statistics = @{}; Duration = $Sync_Stopwatch.Elapsed }
}
