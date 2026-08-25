BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Select-TeamViewerADCActiveDirectoryCommonName.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Private\Resolve-TeamViewerADCTeamViewerAccount.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Private\Split-TeamViewerADCUserGroupMemberId.ps1"

    function Add-TeamViewerADCSyncLogLine {
        param($Message)
        $null = $Message
    }
    function Out-TeamViewerADCSyncProgress {
        param($Handler, $Percent, $Operation)
        $null = $Handler, $Percent, $Operation
    }
    function New-TeamViewerUserGroup {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test double does not change state.')]
        param($ApiToken, $Name)
        $null = $ApiToken, $Name
    }
    function Add-TeamViewerUserGroupMember {
        param($ApiToken, $UserGroupId, $AccountIds)
        $null = $ApiToken, $UserGroupId, $AccountIds
    }
    function Remove-TeamViewerUserGroupMember {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test double does not change state.')]
        param($ApiToken, $UserGroupId, $AccountIds)
        $null = $ApiToken, $UserGroupId, $AccountIds
    }

    . "$PSScriptRoot\..\..\Cmdlets\Private\Invoke-TeamViewerADCSyncUserGroup.ps1"
}

Describe 'Invoke-TeamViewerADCSyncUserGroup' {
    BeforeEach {
        $script:ResolvedUsers = @()
        $script:CreatedUserGroup = [pscustomobject]@{ id = 'new-group'; name = 'Engineering' }

        Mock Resolve-TeamViewerADCTeamViewerAccount {
            $script:ResolvedUsers
        }
        Mock Add-TeamViewerADCSyncLogLine
        Mock Out-TeamViewerADCSyncProgress
        Mock New-TeamViewerUserGroup {
            $script:CreatedUserGroup
        }
        Mock Add-TeamViewerUserGroupMember
        Mock Remove-TeamViewerUserGroupMember
    }

    It 'declares the expected advanced function parameters' {
        $CommandInfo = Get-Command -Name Invoke-TeamViewerADCSyncUserGroup

        $CommandInfo.CmdletBinding | Should -BeTrue
        $CommandInfo.Parameters.Keys | Should -Contain 'Sync_Context'
        $CommandInfo.Parameters.Keys | Should -Contain 'Configuration'
        $CommandInfo.Parameters.Keys | Should -Contain 'Progress'
        @($CommandInfo.Parameters.Values | ForEach-Object { $_.Attributes } | Where-Object { $_.Mandatory }).Count | Should -Be 3
    }

    It 'adds missing users and removes stale TeamViewer group members' {
        $script:ResolvedUsers = @(
            [pscustomobject]@{ id = 'u101'; email = 'new@example.com' }
            [pscustomobject]@{ id = 'u202'; email = 'existing@example.com' }
        )
        $Sync_Context = [pscustomobject]@{
            UserGroups                  = @([pscustomobject]@{ id = 'group-1'; name = 'Engineering' })
            ActiveDirectoryUsersByGroup = @{ 'CN=Engineering,DC=example,DC=com' = @([pscustomobject]@{ Email = 'new@example.com' }) }
            UserGroupMembersByGroup     = @{ 'group-1' = @(
                    [pscustomobject]@{ AccountId = '202'; name = 'existing@example.com' }
                    [pscustomobject]@{ AccountId = '303'; name = 'stale@example.com' }
                )
            }
        }
        $Configuration = [pscustomobject]@{
            ActiveDirectoryGroups = @('CN=Engineering,DC=example,DC=com')
            ApiToken              = 'test-token'
            TestRun               = $false
        }

        $Result = Invoke-TeamViewerADCSyncUserGroup -Sync_Context $Sync_Context -Configuration $Configuration -Progress { }

        $Result.Activity | Should -Be 'SyncUserGroups'
        $Result.Statistics.CreatedGroups | Should -Be 0
        $Result.Statistics.AddedMembers | Should -Be 1
        $Result.Statistics.RemovedMembers | Should -Be 1
        $Result.Statistics.NotChanged | Should -Be 1
        $Result.Statistics.Failed | Should -Be 0
        Should -Invoke Add-TeamViewerUserGroupMember -Times 1 -Exactly -ParameterFilter {
            $UserGroupId -eq 'group-1' -and $AccountIds -contains '101'
        }
        Should -Invoke Remove-TeamViewerUserGroupMember -Times 1 -Exactly -ParameterFilter {
            $UserGroupId -eq 'group-1' -and $AccountIds -contains '303'
        }
    }

    It 'creates a missing TeamViewer group before synchronizing members' {
        $script:ResolvedUsers = @([pscustomobject]@{ id = 'u101'; email = 'new@example.com' })
        $Sync_Context = [pscustomobject]@{
            UserGroups                  = @()
            ActiveDirectoryUsersByGroup = @{ 'CN=Engineering,DC=example,DC=com' = @([pscustomobject]@{ Email = 'new@example.com' }) }
            UserGroupMembersByGroup     = @{}
        }
        $Configuration = [pscustomobject]@{
            ActiveDirectoryGroups = @('CN=Engineering,DC=example,DC=com')
            ApiToken              = 'test-token'
            TestRun               = $false
        }

        $Result = Invoke-TeamViewerADCSyncUserGroup -Sync_Context $Sync_Context -Configuration $Configuration -Progress { }

        $Result.Statistics.CreatedGroups | Should -Be 1
        $Result.Statistics.AddedMembers | Should -Be 1
        Should -Invoke New-TeamViewerUserGroup -Times 1 -Exactly -ParameterFilter { $Name -eq 'Engineering' }
        Should -Invoke Add-TeamViewerUserGroupMember -Times 1 -Exactly
    }

    It 'reports planned changes without calling mutation APIs during a test run' {
        $script:ResolvedUsers = @([pscustomobject]@{ id = 'u101'; email = 'new@example.com' })
        $Sync_Context = [pscustomobject]@{
            UserGroups                  = @()
            ActiveDirectoryUsersByGroup = @{ 'CN=Engineering,DC=example,DC=com' = @([pscustomobject]@{ Email = 'new@example.com' }) }
            UserGroupMembersByGroup     = @{}
        }
        $Configuration = [pscustomobject]@{
            ActiveDirectoryGroups = @('CN=Engineering,DC=example,DC=com')
            ApiToken              = 'test-token'
            TestRun               = $true
        }

        $Result = Invoke-TeamViewerADCSyncUserGroup -Sync_Context $Sync_Context -Configuration $Configuration -Progress { }

        $Result.Statistics.CreatedGroups | Should -Be 1
        $Result.Statistics.AddedMembers | Should -Be 1
        Should -Invoke New-TeamViewerUserGroup -Times 0 -Exactly
        Should -Invoke Add-TeamViewerUserGroupMember -Times 0 -Exactly
        Should -Invoke Remove-TeamViewerUserGroupMember -Times 0 -Exactly
    }

    It 'counts failed add and remove operations' {
        $script:ResolvedUsers = @([pscustomobject]@{ id = 'u101'; email = 'new@example.com' })
        Mock Add-TeamViewerUserGroupMember { throw 'add failed' }
        Mock Remove-TeamViewerUserGroupMember { throw 'remove failed' }
        $Sync_Context = [pscustomobject]@{
            UserGroups                  = @([pscustomobject]@{ id = 'group-1'; name = 'Engineering' })
            ActiveDirectoryUsersByGroup = @{ 'CN=Engineering,DC=example,DC=com' = @([pscustomobject]@{ Email = 'new@example.com' }) }
            UserGroupMembersByGroup     = @{ 'group-1' = @([pscustomobject]@{ AccountId = '303'; name = 'stale@example.com' }) }
        }
        $Configuration = [pscustomobject]@{
            ActiveDirectoryGroups = @('CN=Engineering,DC=example,DC=com')
            ApiToken              = 'test-token'
            TestRun               = $false
        }

        $Result = Invoke-TeamViewerADCSyncUserGroup -Sync_Context $Sync_Context -Configuration $Configuration -Progress { }

        $Result.Statistics.AddedMembers | Should -Be 0
        $Result.Statistics.RemovedMembers | Should -Be 0
        $Result.Statistics.Failed | Should -Be 2
    }
}
