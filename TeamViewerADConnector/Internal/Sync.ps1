# Copyright (c) 2018 TeamViewer GmbH
# See file LICENSE

function Write-SyncLog {
    param([Parameter(ValueFromPipeline)] $message, [Parameter()] $Extra)
    Write-Output -NoEnumerate @{Date = (Get-Date); Message = $message; Extra = $Extra}
}

function Format-SyncLog {
    Process {
        $entry = $_
        if ($entry -is [object] -And $entry -And $entry.Message) {
            "$("{0:yyyy-MM-dd HH:mm:ss}" -f $entry.Date) $($entry.Message)"
        }
        elseif ($entry -is [object] -And $entry -And $entry.Statistics) {
            "$($entry.Statistics | Format-Table -AutoSize -HideTableHeaders | Out-String)"
            "Duration: $($entry.Duration)"
        }
        else { $_ }
    }
}

function ConvertTo-SyncUpdateUserChangeset($userTV, $userAD) {
    $changeset = @{}
    if (!$userTV -Or !$userAD) {
        return $changeset
    }
    if ($userAD.name -ne $userTV.name) { $changeset.name = $userAD.name }
    if ($userAD.IsEnabled -ne $userTV.active) { $changeset.active = $userAD.IsEnabled }
    return $changeset
}

function Format-SyncUpdateUserChangeset {
    param([Parameter(ValueFromPipeline)] $changeset)
    $message = ""
    if ($changeset.name) { $message += "Changing name to '$($changeset.name)'. " }
    if ($changeset.active) { $message += "Changing account status to 'active'. " }
    "$message"
}

function Invoke-Sync($configuration, $notificationHandler) {
    $statistics = @{ Created = 0; Updated = 0; NotChanged = 0; Deactivated = 0; Failed = 0; }

    Write-SyncLog "Starting Active Directory user synchronization."
    Write-SyncLog "Version $ScriptVersion ($([environment]::OSVersion.VersionString), PS $($PSVersionTable.PSVersion))"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    if ($configuration.TestRun) {
        Write-SyncLog "Mode 'Test Run' is active. Information of your TeamViewer account will not be modified!"
    }

    if (!$notificationHandler) { $notificationHandler = {} }

    # Fetch users from configured AD groups.
    # Map the AD user objects to all their email addresses.
    $usersAD = New-Object -TypeName System.Collections.Generic.List[System.Object]
    $usersADEmailMap = @{}
    $count = 1; $adGroupsCount = ($configuration.ActiveDirectoryGroups | Measure-Object).Count
    ForEach ($adGroup in $configuration.ActiveDirectoryGroups) {
        (& $notificationHandler (5.0 * ($count / $adGroupsCount)) 'GetActiveDirectoryGroupMembers'); $count++
        Write-SyncLog "Fetching members of Active Directory group '$adGroup'"
        $adGroupUsers = @(Get-ActiveDirectoryGroupMember $configuration.ActiveDirectoryRoot $configuration.RecursiveGroups $adGroup)
        if ($adGroupUsers) { $usersAD.AddRange($adGroupUsers) }
        ForEach ($adGroupUser in $adGroupUsers) {
            $usersADEmailMap[$adGroupUser.Email] = $adGroupUser
            if ($configuration.UseSecondaryEmails) {
                $adGroupUser.SecondaryEmails | ForEach-Object { $usersADEmailMap[$_] = $adGroupUser } | Out-Null
            }
        }
        Write-SyncLog "Retrieved $($adGroupUsers.Count) users from Active Directory group '$adGroup'"
    }
    # Filter only unique (email) AD users
    $usersAD = ($usersAD | Select-Object -Unique -Property `
        @{ Label = "AsString"; Expression = {"$($_.Email)"}; }, `
        @{ Label = "Value"; Expression = {$_} } | `
            Select-Object -ExpandProperty Value)
    Write-SyncLog "Retrieved $($usersAD.Count) unique users from $adGroupsCount configured Active Directory groups."

    # Fetch users from the configured TeamViewer company.
    # Users are mapped to their email addresses.
    (& $notificationHandler 10 'GetTeamViewerUsers')
    Write-SyncLog "Fetching TeamViewer company users"
    $usersTV = (Get-TeamViewerUser $configuration.ApiToken)
    Write-SyncLog "Retrieved $($usersTV.Count) TeamViewer company users"

    # Create/Update users in the TeamViewer company
    (& $notificationHandler 50 'CreateUpdateUser' $user)
    ForEach ($user in $usersAD) {
        $userTv = $usersTV[$user.email]
        if (!$userTv -and $configuration.UseSecondaryEmails) {
            $userTv = $user.SecondaryEmails | ForEach-Object { $usersTV[$_] } | Select-Object -First 1
        }
        if ($userTv -and $userTv.active -and $userTv.name -eq $user.name) {
            Write-SyncLog "No changes for user $($user.email). Skipping."
            $statistics.NotChanged++
        }
        elseif ($userTv) {
            $changeset = (ConvertTo-SyncUpdateUserChangeset $userTv $user)
            Write-SyncLog "Updating user $($user.email): $($changeset | Format-SyncUpdateUserChangeset)" -Extra $changeset
            if (!$configuration.TestRun) {
                $updatedUser = $user.Clone()
                $updatedUser.active = $true
                try {
                    Edit-TeamViewerUser $configuration.ApiToken $userTv.id $updatedUser | Out-Null
                    $statistics.Updated++
                }
                catch {
                    Write-SyncLog "Failed to update TeamViewer user $($user.email): $_"
                    $statistics.Failed++
                }
            }
            else { $statistics.Updated++ }
        }
        else {
            Write-SyncLog "Creating user $($user.email)"
            if (!$configuration.TestRun) {
                $newUser = $user.Clone()
                $newUser.language = $configuration.UserLanguage
                if ($configuration.UseDefaultPassword) {
                    $newUser.password = $configuration.DefaultPassword
                }
                if ($configuration.UseGeneratedPassword) {
                    $newUser.password = ""
                }
                if ($configuration.UseSsoCustomerId) {
                    $newUser.sso_customer_id = $configuration.SsoCustomerId;
                }
                try {
                    Add-TeamViewerUser $configuration.ApiToken $newUser | Out-Null
                    $statistics.Created++
                }
                catch {
                    Write-SyncLog "Failed to create TeamViewer user $($user.email): $_"
                    $statistics.Failed++
                }
            }
            else { $statistics.Created++ }
        }
    }

    # Deactivate TeamViewer users (if configured)
    (& $notificationHandler 80 'DeactivateUser' $user)
    if ($configuration.DeactivateUsers) {
        # Try to fetch the account information of the configured TeamViewer API token.
        # This information is used to not accidentially deactivate the token owner,
        # which would block further processing of the script.
        Write-SyncLog "Trying to fetch account information of configured TeamViewer API token"
        $currentAccount = Get-TeamViewerAccount $configuration.ApiToken -NoThrow
        if (!$currentAccount) {
            Write-SyncLog "Unable to determine token account information. Please check API token permissions."
        }

        $usersUnknown = ($usersTV.Values | Where-Object { !$usersADEmailMap[$_.email] -And $_.active })
        ForEach ($user in $usersUnknown) {
            if ($currentAccount -And $currentAccount.email -eq $user.email) {
                Write-SyncLog "Skipping deactivation of TeamViewer user $($user.email), because it owns the configured TeamViewer API token."
                continue
            }

            Write-SyncLog "Deactivating TeamViewer user $($user.email)"
            if (!$configuration.TestRun) {
                try {
                    Disable-TeamViewerUser $configuration.ApiToken $user.id | Out-Null
                    $statistics.Deactivated++
                }
                catch {
                    Write-SyncLog "Failed to deactivate TeamViewer user $($user.email): $_"
                    $statistics.Failed++
                }
            }
            else { $statistics.Deactivated++ }
        }
    }

    # We're done here
    $stopwatch.Stop()
    (& $notificationHandler 100 'Completed')
    Write-SyncLog "Finished Active Directory user synchronization"

    # Return some statistics
    Write-Output @{
        Statistics = $statistics
        Duration   = $stopwatch.Elapsed
    }
}
