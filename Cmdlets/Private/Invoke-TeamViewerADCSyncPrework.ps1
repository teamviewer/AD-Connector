. "$PSScriptRoot\ConvertTo-TeamViewerADCSecureString.ps1"

function Invoke-TeamViewerADCSyncPrework {
    [CmdletBinding()]

    [OutputType([void])]

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

    Add-TeamViewerADCSyncLogLine 'Fetching members of configured AD user groups...'
    Out-TeamViewerADCSyncProgress -Handler $Progress -Percent 5 -Operation 'GetActiveDirectoryGroupMembers'

    $AD_Users = New-Object -TypeName System.Collections.Generic.List[System.Object]
    $AD_UsersByEmail = @{ }
    $AD_UsersByGroup = @{ }
    $TV_UserGroups = @()
    $TV_UserGroupMembers = @{}
    $TV_ApiToken = ConvertTo-TeamViewerADCSecureString -Value $Configuration.ApiToken

    # Collect configured AD users and index them for later synchronization lookups.
    foreach ($AD_Group in $Configuration.ActiveDirectoryGroups) {
        Add-TeamViewerADCSyncLogLine "Fetching members of AD user group '$AD_Group'..."

        $AD_GroupUsers = @(Get-ActiveDirectoryGroupMember -AD_Root $Configuration.ActiveDirectoryRoot -Recursive $Configuration.RecursiveGroups -AD_Path $AD_Group)
        $AD_UsersByGroup[$AD_Group] = $AD_GroupUsers

        if ($AD_GroupUsers) {
            $AD_Users.AddRange($AD_GroupUsers)
        }

        foreach ($AD_GroupUser in $AD_GroupUsers) {
            $AD_UsersByEmail[$AD_GroupUser.Email] = $AD_GroupUser

            if ($Configuration.UseSecondaryEmails) {
                $AD_GroupUser.SecondaryEmails | ForEach-Object { $AD_UsersByEmail[$_] = $AD_GroupUser } | Out-Null
            }
        }

        Add-TeamViewerADCSyncLogLine "Retrieved $($AD_GroupUsers.Count) users from AD user group '$AD_Group'."
    }

    $AD_Users = ($AD_Users | Select-Object -Unique -Property `
        @{ Label = 'AsString'; Expression = { "$($_.Email)" }; }, `
        @{ Label = 'Value'; Expression = { $_ } } | Select-Object -ExpandProperty Value)

    $AD_GroupCount = ($Configuration.ActiveDirectoryGroups | Measure-Object).Count

    Add-TeamViewerADCSyncLogLine "Retrieved $($AD_Users.Count) unique users from $AD_GroupCount configured AD groups."

    # Load TV users and index them by email to match AD users efficiently.
    Out-TeamViewerADCSyncProgress -Handler $Progress -Percent 10 -Operation 'GetTeamViewerUsers'
    Add-TeamViewerADCSyncLogLine 'Fetching TV users...'

    $TV_Users = (Get-TeamViewerUser -ApiToken $TV_ApiToken -PropertiesToLoad 'All')
    Add-TeamViewerADCSyncLogLine "Retrieved $($TV_Users.Count) TV users."

    $TV_UsersByEmail = @{}

    if ($TV_Users -and $TV_Users.Count -gt 0) {
        foreach ($TV_User in $TV_Users) {
            if ($TV_User -and $TV_User.email) {
                $TV_UsersByEmail[$TV_User.email] = $TV_User
            }
        }
    }

    Add-TeamViewerADCSyncLogLine "Created table with $($TV_UsersByEmail.Count) TV users indexed by email."

    # When enabled, preload TV user groups and their memberships for user group synchronization.
    if ($Configuration.EnableUserGroupsSync) {
        Out-TeamViewerADCSyncProgress -Handler $Progress -Percent 20 -Operation 'GetTeamViewerUserGroups'
        Add-TeamViewerADCSyncLogLine 'Fetching list of TV user groups...'

        $TV_UserGroups = @(Get-TeamViewerUserGroup -ApiToken $TV_ApiToken)

        Add-TeamViewerADCSyncLogLine "Retrieved $($TV_UserGroups.Count) TV user groups."

        foreach ($UserGroup in $TV_UserGroups) {
            if ($null -eq $UserGroup) {
                continue
            }

            Add-TeamViewerADCSyncLogLine "Fetching members of TV user group '$($UserGroup.name)'..."

            $TV_UserGroupMembers = @(Get-TeamViewerUserGroupMember -ApiToken $TV_ApiToken -Id $UserGroup.id)

            Add-TeamViewerADCSyncLogLine "Retrieved $($TV_UserGroupMembers.Count) members of TV user group '$($UserGroup.name)'."

            $TV_UserGroupMembers[$UserGroup.id] = $TV_UserGroupMembers
        }
    }

    $Sync_Context.ActiveDirectoryUsers = $AD_Users
    $Sync_Context.ActiveDirectoryUsersByEmail = $AD_UsersByEmail
    $Sync_Context.ActiveDirectoryUsersByGroup = $AD_UsersByGroup
    $Sync_Context.TeamViewerUsersByEmail = $TV_UsersByEmail
    $Sync_Context.UserGroups = $TV_UserGroups
    $Sync_Context.UserGroupMembersByGroup = $TV_UserGroupMembers
}
