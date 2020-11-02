# Copyright (c) 2018-2020 TeamViewer GmbH
# See file LICENSE

function Write-SyncLog {
    param([Parameter(ValueFromPipeline)] $message, [Parameter()] $Extra)
    Process {
        Write-Output -InputObject @{Date = (Get-Date); Message = $message; Extra = $Extra } -NoEnumerate
    }
}

function Format-SyncLog {
    Process {
        $entry = $_
        if ($entry -is [object] -And $entry -And $entry.Message) {
            "$("{0:yyyy-MM-dd HH:mm:ss}" -f $entry.Date) $($entry.Message)"
        }
        elseif ($entry -is [object] -And $entry -And $entry.Activity -And $entry.Statistics) {
            "$($entry.Statistics | Format-Table -AutoSize -HideTableHeaders | Out-String)"
            "Duration $($entry.Activity): $($entry.Duration)"
        }
        else { $_ }
    }
}

function Write-SyncProgress {
    param($Handler, $PercentComplete, $CurrentOperation)
    (& $Handler $PercentComplete $CurrentOperation) | Out-Null
}

function ConvertTo-SyncUpdateUserChangeset($userTV, $userAD) {
    $changeset = @{ }
    if (!$userTV -Or !$userAD) {
        return $changeset
    }
    if ($userAD.name -ne $userTV.name) { $changeset.name = $userAD.name }
    if ($userAD.IsEnabled -ne $userTV.active) { $changeset.active = $userAD.IsEnabled }
    return $changeset
}

function Format-SyncUpdateUserChangeset {
    param([Parameter(ValueFromPipeline)] $changeset)
    Process {
        $message = ""
        if ($changeset.name) { $message += "Changing name to '$($changeset.name)'. " }
        if ($changeset.active) { $message += "Changing account status to 'active'. " }
        "$message"
    }
}

function Invoke-SyncPrework($syncContext, $configuration, $progressHandler) {
    # Fetch users from configured AD groups.
    # Map the AD user objects to all their email addresses.
    Write-SyncLog "Fetching members of configured Active Directory groups:"
    Write-SyncProgress -Handler $progressHandler -PercentComplete 5 -CurrentOperation 'GetActiveDirectoryGroupMembers'
    $usersAD = New-Object -TypeName System.Collections.Generic.List[System.Object]
    $usersADByEmail = @{ }
    $usersADByGroup = @{ }
    ForEach ($adGroup in $configuration.ActiveDirectoryGroups) {
        Write-SyncLog "Fetching members of Active Directory group '$adGroup'"
        $adGroupUsers = @(Get-ActiveDirectoryGroupMember $configuration.ActiveDirectoryRoot $configuration.RecursiveGroups $adGroup)
        $usersADByGroup[$adGroup] = $adGroupUsers
        if ($adGroupUsers) { $usersAD.AddRange($adGroupUsers) }
        ForEach ($adGroupUser in $adGroupUsers) {
            $usersADByEmail[$adGroupUser.Email] = $adGroupUser
            if ($configuration.UseSecondaryEmails) {
                $adGroupUser.SecondaryEmails | ForEach-Object { $usersADByEmail[$_] = $adGroupUser } | Out-Null
            }
        }
        Write-SyncLog "Retrieved $($adGroupUsers.Count) users from Active Directory group '$adGroup'"
    }

    # Filter only unique (email) AD users
    $usersAD = ($usersAD | Select-Object -Unique -Property `
        @{ Label = "AsString"; Expression = { "$($_.Email)" }; }, `
        @{ Label = "Value"; Expression = { $_ } } | Select-Object -ExpandProperty Value)
    $adGroupsCount = ($configuration.ActiveDirectoryGroups | Measure-Object).Count
    Write-SyncLog "Retrieved $($usersAD.Count) unique users from $adGroupsCount configured Active Directory groups."

    # Fetch users from the configured TeamViewer company.
    # Users are mapped to their email addresses.
    Write-SyncProgress -Handler $progressHandler -PercentComplete 10 'GetTeamViewerUsers'
    Write-SyncLog "Fetching TeamViewer company users"
    $usersTVByEmail = (Get-TeamViewerUser $configuration.ApiToken)
    Write-SyncLog "Retrieved $($usersTVByEmail.Count) TeamViewer company users"

    if ($configuration.EnableConditionalAccessSync) {
        # Fetch available conditional access groups
        Write-SyncProgress -Handler $progressHandler -PercentComplete 15 'GetTeamViewerConditionalAccess'
        Write-SyncLog "Fetching TeamViewer conditional access groups."
        $groupsCA = @(Get-TeamViewerConditionalAccessGroup $configuration.ApiToken)
        Write-SyncLog "Retrieved $($groupsCA.Count) TeamViewer conditional access groups."

        # Fetch users per group
        $usersCAByGroup = @{}
        ForEach ($groupCA in $groupsCA) {
            Write-SyncLog "Fetching members of TeamViewer conditional access group '$($groupCA.name)'"
            $usersCA = @(Get-TeamViewerConditionalAccessGroupUser $configuration.ApiToken $groupCA.id)
            Write-SyncLog "Retrieved $($usersCA.Count) members of TeamViewer conditional access group '$($groupCA.name)'"
            $usersCAByGroup[$groupCA.id] = $usersCA
        }
    }

    $syncContext.UsersActiveDirectory = $usersAD
    $syncContext.UsersActiveDirectoryByEmail = $usersADByEmail
    $syncContext.UsersActiveDirectoryByGroup = $usersADByGroup
    $syncContext.UsersTeamViewerByEmail = $usersTVByEmail
    $syncContext.GroupsConditionalAccess = $groupsCA
    $syncContext.UsersConditionalAccessByGroup = $usersCAByGroup
}

function Invoke-SyncUser($syncContext, $configuration, $progressHandler) {
    Write-SyncLog "Starting Active Directory user synchronization."
    if ($configuration.TestRun) {
        Write-SyncLog "Mode 'Test Run' is active. Information of your TeamViewer account will not be modified!"
    }

    $statistics = @{ Created = 0; Updated = 0; NotChanged = 0; Deactivated = 0; Failed = 0; }
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Create/Update users in the TeamViewer company
    Write-SyncProgress -Handler $progressHandler -PercentComplete 50 -CurrentOperation 'CreateUpdateUser'
    ForEach ($userAd in $syncContext.UsersActiveDirectory) {
        $userTv = $syncContext.UsersTeamViewerByEmail[$userAd.email]
        if (!$userTv -and $configuration.UseSecondaryEmails) {
            $userTv = $userAd.SecondaryEmails | ForEach-Object { $syncContext.UsersTeamViewerByEmail[$_] } | Select-Object -First 1
        }
        if ($userTv -and $userTv.active -and $userTv.name -eq $userAd.name) {
            Write-SyncLog "No changes for user $($userAd.email). Skipping."
            $statistics.NotChanged++
        }
        elseif ($userTv) {
            $changeset = (ConvertTo-SyncUpdateUserChangeset $userTv $userAd)
            Write-SyncLog "Updating user $($userAd.email): $($changeset | Format-SyncUpdateUserChangeset)" -Extra $changeset
            if (!$configuration.TestRun) {
                $updatedUser = $userAd.Clone()
                $updatedUser.active = $true
                try {
                    Edit-TeamViewerUser $configuration.ApiToken $userTv.id $updatedUser | Out-Null
                    $statistics.Updated++
                }
                catch {
                    Write-SyncLog "Failed to update TeamViewer user $($userAd.email): $_"
                    $statistics.Failed++
                }
            }
            else { $statistics.Updated++ }
        }
        else {
            Write-SyncLog "Creating user $($userAd.email)"
            if (!$configuration.TestRun) {
                $newUser = $userAd.Clone()
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
                    $addedUser = (Add-TeamViewerUser $configuration.ApiToken $newUser)
                    $newUser.id = $addedUser.id
                    $syncContext.UsersTeamViewerByEmail[$newUser.email] = $newUser
                    $statistics.Created++
                }
                catch {
                    Write-SyncLog "Failed to create TeamViewer user $($userAd.email): $_"
                    $statistics.Failed++
                }
            }
            else {
                $syncContext.UsersTeamViewerByEmail[$userAd.email] = @{ id = 'u0'; email = $userAd.email }
                $statistics.Created++
            }
        }
    }

    # Deactivate TeamViewer users (if configured)
    Write-SyncProgress -Handler $progressHandler -PercentComplete 60 -CurrentOperation 'DeactivateUser'
    if ($configuration.DeactivateUsers) {
        # Try to fetch the account information of the configured TeamViewer API token.
        # This information is used to not accidentially deactivate the token owner,
        # which would block further processing of the script.
        Write-SyncLog "Trying to fetch account information of configured TeamViewer API token"
        $currentAccount = Get-TeamViewerAccount $configuration.ApiToken -NoThrow
        if (!$currentAccount) {
            Write-SyncLog "Unable to determine token account information. Please check API token permissions."
        }

        $usersUnknown = ($syncContext.UsersTeamViewerByEmail.Values | Where-Object { !$syncContext.UsersActiveDirectoryByEmail[$_.email] -And $_.active })
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

    $stopwatch.Stop()
    Write-SyncLog "Completed Active Directory user synchronization"

    # Return some statistics
    Write-Output @{
        Activity   = 'SyncUser'
        Statistics = $statistics
        Duration   = $stopwatch.Elapsed
    }
}

function Invoke-SyncConditionalAccess($syncContext, $configuration, $progressHandler) {
    Write-SyncLog "Starting TeamViewer conditional access group synchronization"
    if ($configuration.TestRun) {
        Write-SyncLog "Mode 'Test Run' is active. Information of your TeamViewer conditional access groups will not be modified!"
    }

    $statistics = @{ CreatedGroups = 0; AddedMembers = 0; RemovedMembers = 0; NotChanged = 0; Failed = 0; }
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Write-SyncProgress -Handler $progressHandler -PercentComplete 80 -CurrentOperation 'ConditionalAccess'
    ForEach ($adGroup in $configuration.ActiveDirectoryGroups) {
        $adGroupName = ($adGroup | Select-ActiveDirectoryCommonName)
        $caGroup = ($syncContext.GroupsConditionalAccess | Where-Object { $_.name -eq $adGroupName } | Select-Object -First 1)

        # Try to create the conditional access group, if not exists
        if (!$caGroup) {
            Write-SyncLog "Creating conditional access group '$adGroupName'"
            if (!$configuration.TestRun) {
                try {
                    $caGroup = (Add-TeamViewerConditionalAccessGroup $configuration.ApiToken $adGroupName)
                    $statistics.CreatedGroups++
                }
                catch {
                    Write-SyncLog "Failed to create conditional access group '$adGroupName': $_"
                    $statistics.Failed++
                    Continue;
                }
            } else {
                $caGroup = @{ id = "$(New-Guid)"; name = $adGroupName; }
                $statistics.CreatedGroups++
            }
        }

        $usersAd = @($syncContext.UsersActiveDirectoryByGroup[$adGroup]) | Where-Object { $_ }
        $usersCa = @($syncContext.UsersConditionalAccessByGroup[$caGroup.id]) | Where-Object { $_ }

        # Map the AD group users to a TeamViewer users
        $usersTv = @($usersAd | ForEach-Object {
            $userAd = $_
            $userTv = $syncContext.UsersTeamViewerByEmail[$userAd.email]
            if (!$userTv -and $configuration.UseSecondaryEmails) {
                $userTv = $userAd.SecondaryEmails | ForEach-Object { $syncContext.UsersTeamViewerByEmail[$_] } | Select-Object -First 1
            }
            return $userTv
        }) | Where-Object { $_ }

        # Add missing members to the conditional access group
        $usersToAdd = @()
        ForEach ($userTv in $usersTv) {
            $userCa = ($usersCa | Where-Object { $_ -Eq $userTv.id })
            if (!$userCa) {
                Write-SyncLog "User '$($userTv.email)' will be added to conditional access group '$($caGroup.name)'"
                $usersToAdd += $userTv.id
            }
            else {
                Write-SyncLog "User '$($userTv.email)' is already member of conditional access group '$($caGroup.name)'. Skipping."
                $statistics.NotChanged++
            }
        }
        Write-SyncLog "Adding $($usersToAdd.Count) users to conditional access group '$($caGroup.name)'"
        if (!$configuration.TestRun -And $usersToAdd.Count -Gt 0) {
            try {
                (Add-TeamViewerConditionalAccessGroupUser $configuration.ApiToken $caGroup.id $usersToAdd) | Out-Null
                $statistics.AddedMembers += $usersToAdd.Count
            }
            catch {
                Write-SyncLog "Failed to add members to conditional access group '$($caGroup.name)': $_"
                $statistics.Failed += $usersToAdd.Count
            }
        }
        else { $statistics.AddedMembers += $usersToAdd.Count }

        # Remove unknown users from the conditional access group
        $usersToRemove = @()
        ForEach ($userCa in $usersCa) {
            $userTv = ($usersTv | Where-Object { $_.id -Eq $userCa })
            if (!$userTv) {
                Write-SyncLog "User '$($userCa)' will be removed from conditional access group '$($caGroup.name)'"
                $usersToRemove += $userCa
            }
        }
        Write-SyncLog "Removing $($usersToRemove.Count) users from conditional access group '$($caGroup.name)'"
        if (!$configuration.TestRun -And $usersToRemove.Count -Gt 0) {
            try {
                (Remove-TeamViewerConditionalAccessGroupUser $configuration.ApiToken $caGroup.id $usersToRemove) | Out-Null
                $statistics.RemovedMembers += $usersToRemove.Count
            }
            catch {
                Write-SyncLog "Failed to remove members from conditional access group '$($caGroup.name)': $_"
                $statistics.Failed += $usersToRemove.Count
            }
        }
        else { $statistics.RemovedMembers += $usersToRemove.Count }
    }

    $stopwatch.Stop()
    Write-SyncLog "Completed TeamViewer conditional access group synchronization"

    # Return some statistics
    Write-Output @{
        Activity   = 'SyncConditionalAccess'
        Statistics = $statistics
        Duration   = $stopwatch.Elapsed
    }
}

function Invoke-Sync($configuration, $progressHandler) {
    Write-SyncLog ("-" * 50)
    Write-SyncLog "Starting synchronization run"
    Write-SyncLog "Version $ScriptVersion ($([environment]::OSVersion.VersionString), PS $($PSVersionTable.PSVersion))"

    if ($configuration.TestRun) {
        Write-SyncLog "Mode 'Test Run' is active!"
    }

    if (!$progressHandler) { $progressHandler = { } }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $syncContext = @{ }
    Invoke-SyncPrework -syncContext $syncContext -configuration $configuration -progressHandler $progressHandler
    Invoke-SyncUser -syncContext $syncContext -configuration $configuration -progressHandler $progressHandler
    if ($configuration.EnableConditionalAccessSync) {
        Invoke-SyncConditionalAccess -syncContext $syncContext -configuration $configuration -progressHandler $progressHandler
    }

    # We're done here
    $stopwatch.Stop()
    Write-SyncProgress -Handler $progressHandler -PercentComplete 100 'Completed'

    # Return some statistics
    Write-Output @{
        Activity   = 'Total'
        Statistics = @{}
        Duration   = $stopwatch.Elapsed
    }
}
