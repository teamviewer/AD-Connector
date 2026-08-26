function Invoke-TVADCSyncUser {
    [CmdletBinding()]

    [OutputType([hashtable])]

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

    Add-TVADCSyncLogLine 'Starting user synchronization...'

    if ($Configuration.TestRun) {
        Add-TVADCSyncLogLine "Mode 'Test Run' is active. No modifications will be made."
    }

    $Sync_Statistics = @{ Created = 0; Updated = 0; NotChanged = 0; Deactivated = 0; Failed = 0; }
    $Sync_Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Create or update TeamViewer users to match Active Directory.
    Out-TVADCSyncProgress -Handler $Progress -Percent 50 -Operation 'CreateUpdateUser'

    foreach ($AD_User in $Sync_Context.ActiveDirectoryUsers) {
        $TV_User = $AD_User | Resolve-TVADCTeamViewerAccount -Sync_Context $Sync_Context -Configuration $Configuration

        if ($TV_User -and $TV_User.active -and $TV_User.name -eq $AD_User.name) {
            Add-TVADCSyncLogLine "No changes for TV user $($AD_User.email). Skipped."

            $Sync_Statistics.NotChanged++
        }
        elseif ($TV_User) {
            $TV_Changeset = (ConvertTo-TVADCSyncUpdateUserChangeset -TV_User $TV_User -AD_User $AD_User)

            Add-TVADCSyncLogLine "Updating TV user $($AD_User.email): $($TV_Changeset | Format-TVADCSyncUpdateUserChangeset)" -Extra $TV_Changeset

            if (-not $Configuration.TestRun) {
                $TV_ApiToken = ConvertTo-TVADCSecureString -Value $Configuration.Api_Token
                $TV_UpdateParams = @{ ApiToken = $TV_ApiToken; UserId = $TV_User.id }

                if ($TV_Changeset.Name) {
                    $TV_UpdateParams['Name'] = $TV_Changeset.Name
                }

                if ($TV_Changeset.PSObject.Properties['Active']) {
                    $TV_UpdateParams['Active'] = $TV_Changeset.Active
                }

                try {
                    Set-TeamViewerUser @TV_UpdateParams | Out-Null

                    $Sync_Statistics.Updated++
                }
                catch {
                    Add-TVADCSyncLogLine "Failed to update TV user $($AD_User.email): $_"

                    $Sync_Statistics.Failed++
                }
            }
            else {
                $Sync_Statistics.Updated++
            }
        }
        else {
            Add-TVADCSyncLogLine "Creating user $($AD_User.email)..."

            if (-not $Configuration.TestRun) {
                $TV_ApiToken = ConvertTo-TVADCSecureString -Value $Configuration.Api_Token
                $TV_NewUserParams = @{ ApiToken = $TV_ApiToken; Email = $AD_User.Email; Name = $AD_User.Name }

                if ($Configuration.Use_DefaultPassword) {
                    $TV_NewUserParams['Password'] = ConvertTo-TVADCSecureString -Value $Configuration.User_DefaultPassword
                }
                elseif ($Configuration.Use_GeneratedPassword) {
                    $TV_NewUserParams['WithoutPassword'] = $true
                }
                elseif ($Configuration.Use_SsoCustomerId) {
                    $TV_NewUserParams['SsoCustomerIdentifier'] = ConvertTo-TVADCSecureString -Value $Configuration.Sso_CustomerId
                }

                if ($Configuration.User_Language) {
                    $TV_NewUserParams['Culture'] = $Configuration.User_Language
                }

                if ($Configuration.User_MeetingLicenseKey) {
                    $TV_NewUserParams['MeetingLicenseKey'] = $Configuration.User_MeetingLicenseKey
                }

                try {
                    $TV_AddedUser = (New-TeamViewerUser @TV_NewUserParams)
                    $Sync_Context.TeamViewerUsersByEmail[$TV_AddedUser.Email] = $TV_AddedUser

                    $Sync_Statistics.Created++
                }
                catch {
                    Add-TVADCSyncLogLine "Failed to create TV user $($AD_User.email): $_"

                    $Sync_Statistics.Failed++
                }
            }
            else {
                $Sync_Context.TeamViewerUsersByEmail[$AD_User.email] = @{ id = 'u0'; email = $AD_User.email }
                $Sync_Statistics.Created++
            }
        }
    }

    # Deactivate active TeamViewer users that are no longer in Active Directory.
    Out-TVADCSyncProgress -Handler $Progress -Percent 60 -Operation 'DeactivateUser'
    if ($Configuration.Sync_DeactivateUsers) {
        Add-TVADCSyncLogLine 'Trying to fetch user information of configured TeamViewer API token...'

        if (-not $Configuration.TestRun) {
            try {
                $TV_CurrentAccount = Get-TeamViewerAccount -ApiToken (ConvertTo-TVADCSecureString -Value $Configuration.Api_Token)
            }
            catch {
                Add-TVADCSyncLogLine 'Unable to determine token user information. Please check API token permissions.'
            }
        }

        $TV_UnknownUsers = ($Sync_Context.TeamViewerUsersByEmail.Values | Where-Object { !$Sync_Context.ActiveDirectoryUsersByEmail[$_.email] -and $_.active })
        foreach ($TV_User in $TV_UnknownUsers) {
            if ($TV_CurrentAccount -and $TV_CurrentAccount.email -eq $TV_User.email) {
                Add-TVADCSyncLogLine "Skipping deactivation of TV user $($TV_User.email), because it owns the configured TV API token."

                continue
            }

            Add-TVADCSyncLogLine "Deactivating TV user $($TV_User.email)..."

            if (-not $Configuration.TestRun) {
                try {
                    Set-TeamViewerUser -ApiToken (ConvertTo-TVADCSecureString -Value $Configuration.Api_Token) -User $TV_User.id -Property @{ active = $false } | Out-Null

                    $Sync_Statistics.Deactivated++
                }
                catch {
                    Add-TVADCSyncLogLine "Failed to deactivate TV user $($TV_User.email): $_"

                    $Sync_Statistics.Failed++
                }
            }
            else {
                $Sync_Statistics.Deactivated++
            }
        }
    }

    $Sync_Stopwatch.Stop()
    Add-TVADCSyncLogLine 'Completed user synchronization.'

    Write-Output @{ Activity = 'SyncUser'; Statistics = $Sync_Statistics; Duration = $Sync_Stopwatch.Elapsed }
}
