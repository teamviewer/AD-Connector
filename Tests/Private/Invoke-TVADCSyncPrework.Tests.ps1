BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Invoke-TVADCSyncPrework.ps1"

    # Mock dependencies
    function Add-TVADCSyncLogLine {
        param($Message, $Extra)
        $null = $Message, $Extra
    }

    function Out-TVADCSyncProgress {
        param($Handler, $Percent, $Operation)
        $null = $Handler, $Percent, $Operation
    }

    function Get-TVADCActiveDirectoryGroupMember {
        param($AD_Root, $Recursive, $AD_Path)
        $null = $AD_Root, $Recursive, $AD_Path
        $script:MockADUsers
    }

    function ConvertTo-TVADCSecureString {
        param($Value)
        $null = $Value
        [securestring]::new()
    }

    function Get-TeamViewerUser {
        param($ApiToken, $PropertiesToLoad)
        $null = $ApiToken, $PropertiesToLoad
        $script:MockTVUsers
    }

    function Get-TeamViewerUserGroup {
        param($ApiToken)
        $null = $ApiToken
        $script:MockUserGroups
    }

    function Get-TeamViewerUserGroupMember {
        param($ApiToken, $Id)
        $null = $ApiToken, $Id
        $script:MockUserGroupMembers
    }
}

Describe 'Invoke-TVADCSyncPrework' {
    BeforeEach {
        $script:MockADUsers = @()
        $script:MockTVUsers = @()
        $script:MockUserGroups = @()
        $script:MockUserGroupMembers = @()

        Mock Add-TVADCSyncLogLine
        Mock Out-TVADCSyncProgress
        Mock Get-TVADCActiveDirectoryGroupMember { $script:MockADUsers }
        Mock ConvertTo-TVADCSecureString { [securestring]::new() }
        Mock Get-TeamViewerUser { $script:MockTVUsers }
        Mock Get-TeamViewerUserGroup { $script:MockUserGroups }
        Mock Get-TeamViewerUserGroupMember { $script:MockUserGroupMembers }
    }

    It 'requires Sync_Context parameter' {
        $params = (Get-Command -Name Invoke-TVADCSyncPrework).Parameters
        $params.ContainsKey('Sync_Context') | Should -Be $true
        $params['Sync_Context'].Attributes.Mandatory | Should -Be $true
    }

    It 'requires Configuration parameter' {
        $params = (Get-Command -Name Invoke-TVADCSyncPrework).Parameters
        $params.ContainsKey('Configuration') | Should -Be $true
        $params['Configuration'].Attributes.Mandatory | Should -Be $true
    }

    It 'requires Progress parameter' {
        $params = (Get-Command -Name Invoke-TVADCSyncPrework).Parameters
        $params.ContainsKey('Progress') | Should -Be $true
        $params['Progress'].Attributes.Mandatory | Should -Be $true
    }

    It 'populates Sync_Context with ActiveDirectoryUsers' {
        $context = @{ Initialized = $true }
        $config = @{
            ActiveDirectory_Root     = 'DC=Example,DC=COM'
            ActiveDirectory_Groups   = @('CN=Group1,OU=Groups,DC=Example,DC=COM')
            Api_Token                = 'test-token'
            Sync_RecursiveUserGroups = $false
            Sync_UseSecondaryEmails  = $false
            Sync_SyncUserGroups      = $false
        }
        $progress = @{ Initialized = $true }

        $script:MockADUsers = @(@{ Email = 'user1@example.com'; SecondaryEmails = @() })

        Invoke-TVADCSyncPrework -Sync_Context $context -Configuration $config -Progress $progress

        $context.ActiveDirectoryUsers | Should -Not -BeNullOrEmpty
    }

    It 'populates Sync_Context with TeamViewerUsersByEmail' {
        $context = @{ Initialized = $true }
        $config = @{
            ActiveDirectory_Root     = 'DC=Example,DC=COM'
            ActiveDirectory_Groups   = @('CN=Group1,OU=Groups,DC=Example,DC=COM')
            Api_Token                = 'test-token'
            Sync_RecursiveUserGroups = $false
            Sync_UseSecondaryEmails  = $false
            Sync_SyncUserGroups      = $false
        }
        $progress = @{ Initialized = $true }

        $script:MockTVUsers = @(@{ email = 'tvuser@example.com'; id = 'u123' })

        Invoke-TVADCSyncPrework -Sync_Context $context -Configuration $config -Progress $progress

        $context.TeamViewerUsersByEmail | Should -Not -BeNullOrEmpty
    }

    It 'calls Add-TVADCSyncLogLine with appropriate messages' {
        $context = @{ Initialized = $true }
        $config = @{
            ActiveDirectory_Root     = 'DC=Example,DC=COM'
            ActiveDirectory_Groups   = @('CN=Group1,OU=Groups,DC=Example,DC=COM')
            Api_Token                = 'test-token'
            Sync_RecursiveUserGroups = $false
            Sync_UseSecondaryEmails  = $false
            Sync_SyncUserGroups      = $false
        }
        $progress = @{ Initialized = $true }

        Invoke-TVADCSyncPrework -Sync_Context $context -Configuration $config -Progress $progress

        Should -Invoke -CommandName Add-TVADCSyncLogLine -Times 1 -Scope It
    }
}
