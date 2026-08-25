BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\ConvertTo-TeamViewerADCSyncUpdateUserChangeset.ps1"
}

Describe 'ConvertTo-TeamViewerADCSyncUpdateUserChangeset' {
    It 'returns an empty changeset when either user is missing' {
        (ConvertTo-TeamViewerADCSyncUpdateUserChangeset -TV_User $null -AD_User ([pscustomobject]@{})).Count | Should -Be 0
        (ConvertTo-TeamViewerADCSyncUpdateUserChangeset -TV_User ([pscustomobject]@{}) -AD_User $null).Count | Should -Be 0
    }

    It 'returns an empty changeset when users are unchanged' {
        $TV_User = [pscustomobject]@{ name = 'Alex Doe'; active = $true }
        $AD_User = [pscustomobject]@{ name = 'Alex Doe'; IsEnabled = $true }

        (ConvertTo-TeamViewerADCSyncUpdateUserChangeset -TV_User $TV_User -AD_User $AD_User).Count | Should -Be 0
    }

    It 'includes a changed name' {
        $TV_User = [pscustomobject]@{ name = 'Alex Doe'; active = $true }
        $AD_User = [pscustomobject]@{ name = 'Alex Smith'; IsEnabled = $true }

        $Result = ConvertTo-TeamViewerADCSyncUpdateUserChangeset -TV_User $TV_User -AD_User $AD_User

        $Result.name | Should -Be 'Alex Smith'
        $Result.ContainsKey('active') | Should -BeFalse
    }

    It 'includes a changed account status' {
        $TV_User = [pscustomobject]@{ name = 'Alex Doe'; active = $true }
        $AD_User = [pscustomobject]@{ name = 'Alex Doe'; IsEnabled = $false }

        $Result = ConvertTo-TeamViewerADCSyncUpdateUserChangeset -TV_User $TV_User -AD_User $AD_User

        $Result.active | Should -BeFalse
        $Result.ContainsKey('name') | Should -BeFalse
    }
}
