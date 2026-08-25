. "$PSScriptRoot\ConvertTo-TeamViewerADCSecureString.ps1"

function Invoke-TeamViewerADCSyncUser {
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

    Add-TeamViewerADCSyncLogLine 'Starting user synchronization...'

    if ($Configuration.TestRun) {
        Add-TeamViewerADCSyncLogLine "Mode 'Test Run' is active. No modifications will be made."
    }

    $Sync_Statistics = @{ Created = 0; Updated = 0; NotChanged = 0; Deactivated = 0; Failed = 0; }
    $Sync_Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Create or update TeamViewer users to match Active Directory.
    Out-TeamViewerADCSyncProgress -Handler $Progress -Percent 50 -Operation 'CreateUpdateUser'

    foreach ($AD_User in $Sync_Context.ActiveDirectoryUsers) {
        $TV_User = $AD_User | Resolve-TeamViewerADCTeamViewerAccount -Sync_Context $Sync_Context -Configuration $Configuration

        if ($TV_User -and $TV_User.active -and $TV_User.name -eq $AD_User.name) {
            Add-TeamViewerADCSyncLogLine "No changes for TV user $($AD_User.email). Skipped."

            $Sync_Statistics.NotChanged++
        }
        elseif ($TV_User) {
            $TV_Changeset = (ConvertTo-TeamViewerADCSyncUpdateUserChangeset -TV_User $TV_User -AD_User $AD_User)

            Add-TeamViewerADCSyncLogLine "Updating TV user $($AD_User.email): $($TV_Changeset | Format-TeamViewerADCSyncUpdateUserChangeset)" -Extra $TV_Changeset

            if (-not $Configuration.TestRun) {
                $TV_ApiToken = ConvertTo-TeamViewerADCSecureString -Value $Configuration.ApiToken
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
                    Add-TeamViewerADCSyncLogLine "Failed to update TV user $($AD_User.email): $_"

                    $Sync_Statistics.Failed++
                }
            }
            else {
                $Sync_Statistics.Updated++
            }
        }
        else {
            Add-TeamViewerADCSyncLogLine "Creating user $($AD_User.email)..."

            if (-not $Configuration.TestRun) {
                $TV_ApiToken = ConvertTo-TeamViewerADCSecureString -Value $Configuration.ApiToken
                $TV_NewUserParams = @{ ApiToken = $TV_ApiToken; Email = $AD_User.Email; Name = $AD_User.Name }

                if ($Configuration.UseDefaultPassword) {
                    $TV_NewUserParams['Password'] = ConvertTo-TeamViewerADCSecureString -Value $Configuration.DefaultPassword
                }
                elseif ($Configuration.UseGeneratedPassword) {
                    $TV_NewUserParams['WithoutPassword'] = $true
                }
                elseif ($Configuration.UseSsoCustomerId) {
                    $TV_NewUserParams['SsoCustomerIdentifier'] = ConvertTo-TeamViewerADCSecureString -Value $Configuration.SsoCustomerId
                }

                if ($Configuration.UserLanguage) {
                    $TV_NewUserParams['Culture'] = $Configuration.UserLanguage
                }

                if ($Configuration.MeetingLicenseKey) {
                    $TV_NewUserParams['MeetingLicenseKey'] = $Configuration.MeetingLicenseKey
                }

                try {
                    $TV_AddedUser = (New-TeamViewerUser @TV_NewUserParams)
                    $Sync_Context.TeamViewerUsersByEmail[$TV_AddedUser.Email] = $TV_AddedUser

                    $Sync_Statistics.Created++
                }
                catch {
                    Add-TeamViewerADCSyncLogLine "Failed to create TV user $($AD_User.email): $_"

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
    Out-TeamViewerADCSyncProgress -Handler $Progress -Percent 60 -Operation 'DeactivateUser'
    if ($Configuration.DeactivateUsers) {
        Add-TeamViewerADCSyncLogLine 'Trying to fetch user information of configured TeamViewer API token...'

        if (-not $Configuration.TestRun) {
            try {
                $TV_CurrentAccount = Get-TeamViewerAccount -ApiToken (ConvertTo-TeamViewerADCSecureString -Value $Configuration.ApiToken)
            }
            catch {
                Add-TeamViewerADCSyncLogLine 'Unable to determine token user information. Please check API token permissions.'
            }
        }

        $TV_UnknownUsers = ($Sync_Context.TeamViewerUsersByEmail.Values | Where-Object { !$Sync_Context.ActiveDirectoryUsersByEmail[$_.email] -and $_.active })
        foreach ($TV_User in $TV_UnknownUsers) {
            if ($TV_CurrentAccount -and $TV_CurrentAccount.email -eq $TV_User.email) {
                Add-TeamViewerADCSyncLogLine "Skipping deactivation of TV user $($TV_User.email), because it owns the configured TV API token."

                continue
            }

            Add-TeamViewerADCSyncLogLine "Deactivating TV user $($TV_User.email)..."

            if (-not $Configuration.TestRun) {
                try {
                    Set-TeamViewerUser -ApiToken (ConvertTo-TeamViewerADCSecureString -Value $Configuration.ApiToken) -User $TV_User.id -Property @{ active = $false } | Out-Null

                    $Sync_Statistics.Deactivated++
                }
                catch {
                    Add-TeamViewerADCSyncLogLine "Failed to deactivate TV user $($TV_User.email): $_"

                    $Sync_Statistics.Failed++
                }
            }
            else {
                $Sync_Statistics.Deactivated++
            }
        }
    }

    $Sync_Stopwatch.Stop()
    Add-TeamViewerADCSyncLogLine 'Completed user synchronization.'

    Write-Output @{ Activity = 'SyncUser'; Statistics = $Sync_Statistics; Duration = $Sync_Stopwatch.Elapsed }
}
