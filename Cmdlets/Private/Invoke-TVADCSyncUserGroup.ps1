function Invoke-TVADCSyncUserGroup {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$Sync_Context,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$Configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$Progress
    )

    Add-TVADCSyncLogLine 'Starting user groups synchronization...'

    if ($Configuration.TestRun) {
        Add-TVADCSyncLogLine "Mode 'Test Run' is active. No modifications will be made."
    }

    $Sync_Statistics = @{ CreatedGroups = 0; AddedMembers = 0; RemovedMembers = 0; NotChanged = 0; Failed = 0; }
    $Sync_Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Out-TVADCSyncProgress -Handler $Progress -Percent 80 -Operation 'User Groups'

    # Ensure each configured Active Directory user group has a TeamViewer user group.
    foreach ($AD_UserGroup in $Configuration.ActiveDirectory_Groups) {
        $AD_UserGroupName = ($AD_UserGroup | Select-TVADCActiveDirectoryCommonName)
        $TV_UserGroup = ($Sync_Context.UserGroups | Where-Object { $_.Name -eq $AD_UserGroupName } | Select-Object -First 1)

        if (-not $TV_UserGroup) {
            Add-TVADCSyncLogLine "Creating TV user group '$AD_UserGroupName'..."

            if (-not $Configuration.TestRun) {
                try {
                    $TV_UserGroup = (New-TeamViewerUserGroup -ApiToken (ConvertTo-TVADCSecureString -Value $Configuration.Api_Token) -Name $AD_UserGroupName)

                    $Sync_Statistics.CreatedGroups++
                }
                catch {
                    Add-TVADCSyncLogLine "Failed to create TV user group '$AD_UserGroupName': $_"

                    $Sync_Statistics.Failed++

                    continue
                }
            }
            else {
                $TV_UserGroup = @{ id = (Get-Random); name = $AD_UserGroupName; }

                $Sync_Statistics.CreatedGroups++
            }
        }

        # Figure out which TeamViewer users should belong to user group based on current Active Directory membership.
        $AD_Users = @($Sync_Context.ActiveDirectoryUsersByGroup[$AD_UserGroup]) | Where-Object { $_ }
        $TV_UserGroupMembers = @($Sync_Context.UserGroupMembersByGroup[$TV_UserGroup.id]) | Where-Object { $_ }
        $TV_Users = @($AD_Users | Resolve-TVADCTeamViewerAccount -Sync_Context $Sync_Context -Configuration $Configuration | Where-Object { $_ })

        $Members_ToAdd = @()

        foreach ($TV_User in $TV_Users) {
            $TV_UserGroupMember = ($TV_UserGroupMembers | Where-Object { $_.AccountId -eq $TV_User.Id.Trim('u') })

            if (-not $TV_UserGroupMember) {
                Add-TVADCSyncLogLine "TV user '$($TV_User.email)' will be added to TV user group '$($TV_UserGroup.name)'..."

                $Members_ToAdd += $TV_User.id.Trim('u')
            }
            else {
                Add-TVADCSyncLogLine "TV user '$($TV_User.email)' is already member of TV user group '$($TV_UserGroup.name)'. Skipped."

                $Sync_Statistics.NotChanged++
            }
        }

        Add-TVADCSyncLogLine "Adding TV $($Members_ToAdd.Count) users to TV user group '$($TV_UserGroup.name)'..."

        if (-not $Configuration.TestRun -and $Members_ToAdd.Count -gt 0) {
            $Members_ToAdd | Split-TVADCUserGroupMemberId | ForEach-Object {
                $TV_CurrentMembersToAdd = $_

                try {
                    (Add-TeamViewerUserGroupMember -ApiToken (ConvertTo-TVADCSecureString -Value $Configuration.Api_Token) $TV_UserGroup.id $TV_CurrentMembersToAdd) | Out-Null

                    $Sync_Statistics.AddedMembers += $TV_CurrentMembersToAdd.Count
                }
                catch {
                    Add-TVADCSyncLogLine "Failed to add members to TVuser group '$($TV_UserGroup.name)': $_"

                    $Sync_Statistics.Failed += $TV_CurrentMembersToAdd.Count
                }
            }
        }
        else {
            $Sync_Statistics.AddedMembers += $Members_ToAdd.Count
        }

        # Remove group members on TeamViewer side who are no longer in the Active Directory user group.
        $Members_ToRemove = @()

        foreach ($TV_UserGroupMember in $TV_UserGroupMembers) {
            $TV_User = ($TV_Users | Where-Object { $_.id.Trim('u') -eq $TV_UserGroupMember.accountId })

            if (-not $TV_User) {
                Add-TVADCSyncLogLine "TV user '$($TV_UserGroupMember.name)' will be removed from TV user group '$($TV_UserGroup.name)'..."

                $Members_ToRemove += $TV_UserGroupMember.accountId
            }
        }

        Add-TVADCSyncLogLine "Removing $($Members_ToRemove.Count) members from TV user group '$($TV_UserGroup.name)'..."

        if (-not $Configuration.TestRun -and $Members_ToRemove.Count -gt 0) {
            $Members_ToRemove | Split-TVADCUserGroupMemberId | ForEach-Object {
                $TV_CurrentMembersToRemove = $_

                try {
                    (Remove-TeamViewerUserGroupMember -ApiToken (ConvertTo-TVADCSecureString -Value $Configuration.Api_Token) $TV_UserGroup.id $TV_CurrentMembersToRemove) | Out-Null

                    $Sync_Statistics.RemovedMembers += $TV_CurrentMembersToRemove.Count
                }
                catch {
                    Add-TVADCSyncLogLine "Failed to remove members from TV user group '$($TV_UserGroup.name)'"

                    $Sync_Statistics.Failed += $TV_CurrentMembersToRemove.Count
                }
            }
        }
        else {
            $Sync_Statistics.RemovedMembers += $Members_ToRemove.Count
        }
    }

    $Sync_Stopwatch.Stop()

    Add-TVADCSyncLogLine 'Completed user group synchronization.'

    Write-Output @{ Activity = 'SyncUserGroups'; Statistics = $Sync_Statistics; Duration = $Sync_Stopwatch.Elapsed }
}
