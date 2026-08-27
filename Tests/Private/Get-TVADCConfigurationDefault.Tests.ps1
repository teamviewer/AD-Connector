BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCConfigurationDefault.ps1"
}

Describe 'Get-TVADCConfigurationDefault' {
    It 'declares a hashtable output contract' {
        $CommandInfo = Get-Command -Name Get-TVADCConfigurationDefault

        $CommandInfo.CmdletBinding | Should -BeTrue
        $CommandInfo.OutputType.Type | Should -Contain ([hashtable])
    }

    It 'returns the established default configuration' {
        $Defaults = Get-TVADCConfigurationDefault

        $Defaults | Should -BeOfType ([hashtable])
        $Defaults.Api_Uri | Should -Be 'https://webapi.teamviewer.com/api/v1'
        $Defaults.Api_Token | Should -Be ''
        $Defaults.TestRun | Should -BeTrue
        $Defaults.ActiveDirectory_Root | Should -Be ''
        $Defaults.ActiveDirectory_Groups | Should -BeNullOrEmpty
        $Defaults.User_Language | Should -Be 'en'
        $Defaults.User_MeetingLicenseKey | Should -Be ''
        $Defaults.User_DefaultPassword | Should -Be ''
        $Defaults.Sso_CustomerId | Should -Be ''
        $Defaults.Use_DefaultPassword | Should -BeFalse
        $Defaults.Use_GeneratedPassword | Should -BeTrue
        $Defaults.Use_SsoCustomerId | Should -BeFalse
        $Defaults.Sync_DeactivateUsers | Should -BeTrue
        $Defaults.Sync_UseSecondaryEmails | Should -BeTrue
        $Defaults.Sync_SyncUserGroups | Should -BeFalse
        $Defaults.Sync_RecursiveUserGroups | Should -BeTrue
    }

    It 'returns an independent copy on each call' {
        $First = Get-TVADCConfigurationDefault
        $First.Api_Token = 'mutated'

        (Get-TVADCConfigurationDefault).Api_Token | Should -Be ''
    }
}
