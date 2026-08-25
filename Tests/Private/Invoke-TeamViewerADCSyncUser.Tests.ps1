BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\ConvertTo-TeamViewerADCSyncUpdateUserChangeset.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Private\Format-TeamViewerADCSyncUpdateUserChangeset.ps1"

    function Add-TeamViewerADCSyncLogLine {
        param($Message, $Extra)
        $null = $Message, $Extra
    }
    function Out-TeamViewerADCSyncProgress {
        param($Handler, $Percent, $Operation)
        $null = $Handler, $Percent, $Operation
    }
    function Resolve-TeamViewerADCTeamViewerAccount {
        param($Sync_Context, $Configuration, $AD_User)
        $null = $Sync_Context, $Configuration, $AD_User
        $script:ResolvedUser
    }
    function Set-TeamViewerUser {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test double does not change state.')]
        param($ApiToken, $UserId, $User, $Active, $Name, $Property)
        $null = $ApiToken, $UserId, $User, $Active, $Name, $Property
    }
    function New-TeamViewerUser {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test double does not change state.')]
        param($ApiToken, $Email, $Name, [securestring]$Password, [bool]$WithoutPassword, [securestring]$SsoCustomerIdentifier, $Culture, $MeetingLicenseKey)
        $null = $ApiToken, $Email, $Name, $Password, $WithoutPassword, $SsoCustomerIdentifier, $Culture, $MeetingLicenseKey
        $script:CreatedUser
    }
    function Get-TeamViewerAccount {
        param($ApiToken)
        $null = $ApiToken
        $script:CurrentAccount
    }

    . "$PSScriptRoot\..\..\Cmdlets\Private\Invoke-TeamViewerADCSyncUser.ps1"
}

Describe 'Invoke-TeamViewerADCSyncUser' {
    BeforeEach {
        $script:ResolvedUser = $null
        $script:ResolveCall = 0
        $script:CreatedUser = [pscustomobject]@{ Email = 'created@example.com'; id = 'u300'; active = $true; name = 'Created User' }
        $script:CurrentAccount = $null

        Mock Add-TeamViewerADCSyncLogLine
        Mock Out-TeamViewerADCSyncProgress
        Mock Resolve-TeamViewerADCTeamViewerAccount {
            param($Sync_Context, $Configuration, $AD_User)
            $null = $Sync_Context, $Configuration, $AD_User
            $script:ResolveCall++
            $script:ResolvedUser
        }
        Mock Set-TeamViewerUser
        Mock New-TeamViewerUser { $script:CreatedUser }
        Mock Get-TeamViewerAccount { $script:CurrentAccount }
    }

    It 'declares the expected advanced function contract' {
        $CommandInfo = Get-Command -Name Invoke-TeamViewerADCSyncUser

        $CommandInfo.CmdletBinding | Should -BeTrue
        $CommandInfo.OutputType.Type | Should -Contain ([hashtable])
        @($CommandInfo.Parameters.Values | ForEach-Object { $_.Attributes } | Where-Object { $_.Mandatory }).Count | Should -Be 3
        $CommandInfo.Parameters['Progress'].ParameterType | Should -Be ([object])
    }

    It 'creates missing users with configured optional values' {
        $ADUser = [pscustomobject]@{ Email = 'new@example.com'; Name = 'New User'; IsEnabled = $true }
        $Sync_Context = [pscustomobject]@{
            ActiveDirectoryUsers        = @($ADUser)
            TeamViewerUsersByEmail      = @{}
            ActiveDirectoryUsersByEmail = @{ 'new@example.com' = $ADUser }
        }
        $Configuration = [pscustomobject]@{
            ApiToken             = 'test-token'
            TestRun              = $false
            UseDefaultPassword   = $false
            UseGeneratedPassword = $true
            UseSsoCustomerId     = $false
            UserLanguage         = 'de'
            MeetingLicenseKey    = 'meeting-key'
            DeactivateUsers      = $false
        }

        $Result = Invoke-TeamViewerADCSyncUser -Sync_Context $Sync_Context -Configuration $Configuration -Progress { }

        $Result.Activity | Should -Be 'SyncUser'
        $Result.Statistics.Created | Should -Be 1
        $Result.Statistics.Updated | Should -Be 0
        $Result.Statistics.Failed | Should -Be 0
        Should -Invoke New-TeamViewerUser -Times 1 -Exactly -ParameterFilter {
            $Email -eq 'new@example.com' -and $Name -eq 'New User' -and $WithoutPassword -eq $true -and
            $Culture -eq 'de' -and $MeetingLicenseKey -eq 'meeting-key'
        }
        $Sync_Context.TeamViewerUsersByEmail['created@example.com'].id | Should -Be 'u300'
    }

    It 'updates changed users and counts unchanged users' {
        $ADUsers = @(
            [pscustomobject]@{ Email = 'changed@example.com'; Name = 'Changed Name'; IsEnabled = $true }
            [pscustomobject]@{ Email = 'same@example.com'; Name = 'Same Name'; IsEnabled = $true }
        )
        $script:ResolvedUser = [pscustomobject]@{ id = 'u101'; email = 'changed@example.com'; name = 'Old Name'; active = $true }
        $Sync_Context = [pscustomobject]@{
            ActiveDirectoryUsers        = $ADUsers
            TeamViewerUsersByEmail      = @{}
            ActiveDirectoryUsersByEmail = @{
                'changed@example.com' = $ADUsers[0]
                'same@example.com'    = $ADUsers[1]
            }
        }
        $Configuration = [pscustomobject]@{ ApiToken = 'test-token'; TestRun = $false; DeactivateUsers = $false }
        Mock Resolve-TeamViewerADCTeamViewerAccount {
            $script:ResolveCall++
            if ($script:ResolveCall -eq 1) {
                $script:ResolvedUser
            }
            else {
                [pscustomobject]@{ id = 'u202'; email = 'same@example.com'; name = 'Same Name'; active = $true }
            }
        }

        $Result = Invoke-TeamViewerADCSyncUser -Sync_Context $Sync_Context -Configuration $Configuration -Progress { }

        $Result.Statistics.Updated | Should -Be 1
        $Result.Statistics.NotChanged | Should -Be 1
        Should -Invoke Set-TeamViewerUser -Times 1 -Exactly -ParameterFilter {
            $UserId -eq 'u101' -and $Name -eq 'Changed Name'
        }
    }

    It 'deactivates unknown active users but skips the API token owner' {
        $UnknownUser = [pscustomobject]@{ id = 'u303'; email = 'unknown@example.com'; active = $true; name = 'Unknown' }
        $OwnerUser = [pscustomobject]@{ id = 'u404'; email = 'owner@example.com'; active = $true; name = 'Owner' }
        $Sync_Context = [pscustomobject]@{
            ActiveDirectoryUsers        = @()
            TeamViewerUsersByEmail      = @{
                $UnknownUser.email = $UnknownUser
                $OwnerUser.email   = $OwnerUser
            }
            ActiveDirectoryUsersByEmail = @{}
        }
        $script:CurrentAccount = [pscustomobject]@{ email = 'owner@example.com' }
        $Configuration = [pscustomobject]@{ ApiToken = 'test-token'; TestRun = $false; DeactivateUsers = $true }

        $Result = Invoke-TeamViewerADCSyncUser -Sync_Context $Sync_Context -Configuration $Configuration -Progress { }

        $Result.Statistics.Deactivated | Should -Be 1
        Should -Invoke Get-TeamViewerAccount -Times 1 -Exactly
        Should -Invoke Set-TeamViewerUser -Times 1 -Exactly -ParameterFilter {
            $User -eq 'u303' -and $Property.active -eq $false
        }
    }

    It 'reports planned changes without calling mutation APIs during a test run' {
        $ADUser = [pscustomobject]@{ Email = 'new@example.com'; Name = 'New User'; IsEnabled = $true }
        $UnknownUser = [pscustomobject]@{ id = 'u303'; email = 'unknown@example.com'; active = $true; name = 'Unknown' }
        $Sync_Context = [pscustomobject]@{
            ActiveDirectoryUsers        = @($ADUser)
            TeamViewerUsersByEmail      = @{ $UnknownUser.email = $UnknownUser }
            ActiveDirectoryUsersByEmail = @{}
        }
        $Configuration = [pscustomobject]@{ ApiToken = 'test-token'; TestRun = $true; DeactivateUsers = $true }

        $Result = Invoke-TeamViewerADCSyncUser -Sync_Context $Sync_Context -Configuration $Configuration -Progress { }

        $Result.Statistics.Created | Should -Be 1
        $Result.Statistics.Deactivated | Should -Be 1
        Should -Invoke New-TeamViewerUser -Times 0 -Exactly
        Should -Invoke Set-TeamViewerUser -Times 0 -Exactly
        Should -Invoke Get-TeamViewerAccount -Times 0 -Exactly
    }

    It 'counts failed create, update, and deactivation operations' {
        $ADUser = [pscustomobject]@{ Email = 'user@example.com'; Name = 'User'; IsEnabled = $true }
        $ExistingUser = [pscustomobject]@{ id = 'u101'; email = 'user@example.com'; name = 'Old User'; active = $true }
        $UnknownUser = [pscustomobject]@{ id = 'u303'; email = 'unknown@example.com'; active = $true; name = 'Unknown' }
        $Sync_Context = [pscustomobject]@{
            ActiveDirectoryUsers        = @($ADUser)
            TeamViewerUsersByEmail      = @{ $UnknownUser.email = $UnknownUser }
            ActiveDirectoryUsersByEmail = @{ $ADUser.Email = $ADUser }
        }
        $Configuration = [pscustomobject]@{ ApiToken = 'test-token'; TestRun = $false; DeactivateUsers = $true }
        Mock Resolve-TeamViewerADCTeamViewerAccount { $ExistingUser }
        Mock Set-TeamViewerUser { throw 'update failed' }
        Mock Get-TeamViewerAccount { throw 'account lookup failed' }

        $Result = Invoke-TeamViewerADCSyncUser -Sync_Context $Sync_Context -Configuration $Configuration -Progress { }

        $Result.Statistics.Failed | Should -Be 2
        $Result.Statistics.Updated | Should -Be 0
    }
}
