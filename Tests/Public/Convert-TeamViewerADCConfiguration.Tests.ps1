BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCConfigurationDefault.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Private\Save-TVADCConfiguration.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Public\Convert-TeamViewerADCConfiguration.ps1"

    $Script:LegacyConfiguration = @{
        ApiToken              = 'legacy-token'
        ActiveDirectoryRoot   = 'LDAP://DC=example,DC=com'
        ActiveDirectoryGroups = @('GroupA', 'GroupB')
        UserLanguage          = 'de'
        UseDefaultPassword    = $false
        DefaultPassword       = 'legacy-password'
        UseSsoCustomerId      = $false
        UseGeneratedPassword  = $true
        SsoCustomerId         = 'legacy-customer'
        TestRun               = $false
        DeactivateUsers       = $false
        RecursiveGroups       = $false
        UseSecondaryEmails    = $false
        EnableUserGroupsSync  = $true
        MeetingLicenseKey     = '4d00238a-9391-44cd-88ab-631194a97de5'
        Environment           = 'us'
    }
}

Describe 'Convert-TeamViewerADCConfiguration' {
    It 'declares a ShouldProcess-enabled object contract' {
        $CommandInfo = Get-Command -Name Convert-TeamViewerADCConfiguration

        $CommandInfo.CmdletBinding | Should -BeTrue
        $CommandInfo.OutputType.Type | Should -Contain ([psobject])
        $CommandInfo.Parameters.ContainsKey('WhatIf') | Should -BeTrue
    }

    It 'maps every legacy field to the current configuration format' {
        $SourceFile = Join-Path -Path $TestDrive -ChildPath 'Legacy.json'
        $DestinationFile = Join-Path -Path $TestDrive -ChildPath 'Converted\TeamViewerADC.json'
        $LegacyConfiguration | ConvertTo-Json | Set-Content -Path $SourceFile -Encoding UTF8

        Convert-TeamViewerADCConfiguration -Path $SourceFile -Destination $DestinationFile

        $Converted = Get-Content -Path $DestinationFile -Raw | ConvertFrom-Json
        $Converted.Api_Token | Should -Be 'legacy-token'
        $Converted.ActiveDirectory_Root | Should -Be 'LDAP://DC=example,DC=com'
        $Converted.ActiveDirectory_Groups | Should -Be @('GroupA', 'GroupB')
        $Converted.User_Language | Should -Be 'de'
        $Converted.Use_DefaultPassword | Should -BeFalse
        $Converted.User_DefaultPassword | Should -Be 'legacy-password'
        $Converted.Use_SsoCustomerId | Should -BeFalse
        $Converted.Use_GeneratedPassword | Should -BeTrue
        $Converted.Sso_CustomerId | Should -Be 'legacy-customer'
        $Converted.TestRun | Should -BeFalse
        $Converted.Sync_DeactivateUsers | Should -BeFalse
        $Converted.Sync_RecursiveUserGroups | Should -BeFalse
        $Converted.Sync_UseSecondaryEmails | Should -BeFalse
        $Converted.Sync_SyncUserGroups | Should -BeTrue
        $Converted.User_MeetingLicenseKey | Should -Be '4d00238a-9391-44cd-88ab-631194a97de5'
        $Converted.Api_Uri | Should -Be 'https://webapi.teamviewer.com/api/v1'
        $Converted.PSObject.Properties.Name | Should -Not -Contain 'Filename'
        $Converted.PSObject.Properties.Name | Should -Not -Contain 'ApiToken'
    }

    It 'applies defaults for legacy fields that are absent' {
        $SourceFile = Join-Path -Path $TestDrive -ChildPath 'Partial.json'
        $DestinationFile = Join-Path -Path $TestDrive -ChildPath 'Partial-converted.json'
        @{ ApiToken = 'partial-token' } | ConvertTo-Json | Set-Content -Path $SourceFile -Encoding UTF8

        Convert-TeamViewerADCConfiguration -Path $SourceFile -Destination $DestinationFile

        $Converted = Get-Content -Path $DestinationFile -Raw | ConvertFrom-Json
        $Converted.Api_Token | Should -Be 'partial-token'
        $Converted.Api_Uri | Should -Be 'https://webapi.teamviewer.com/api/v1'
        $Converted.Use_DefaultPassword | Should -BeFalse
        $Converted.Sync_RecursiveUserGroups | Should -BeTrue
    }

    It 'leaves the default API URI when the legacy environment is not us' {
        $SourceFile = Join-Path -Path $TestDrive -ChildPath 'GlobalEnv.json'
        $DestinationFile = Join-Path -Path $TestDrive -ChildPath 'GlobalEnv-converted.json'
        @{ ApiToken = 'token'; Environment = 'global' } | ConvertTo-Json | Set-Content -Path $SourceFile -Encoding UTF8

        Convert-TeamViewerADCConfiguration -Path $SourceFile -Destination $DestinationFile

        (Get-Content -Path $DestinationFile -Raw | ConvertFrom-Json).Api_Uri | Should -Be 'https://webapi.teamviewer.com/api/v1'
    }

    It 'rejects a source path that does not exist' {
        $MissingFile = Join-Path -Path $TestDrive -ChildPath 'Missing.json'
        $DestinationFile = Join-Path -Path $TestDrive -ChildPath 'Unused.json'

        { Convert-TeamViewerADCConfiguration -Path $MissingFile -Destination $DestinationFile -ErrorAction Stop } | Should -Throw
    }

    It 'does not write the destination when -WhatIf is supplied' {
        $SourceFile = Join-Path -Path $TestDrive -ChildPath 'WhatIf-source.json'
        $DestinationFile = Join-Path -Path $TestDrive -ChildPath 'WhatIf-destination.json'
        @{ ApiToken = 'token' } | ConvertTo-Json | Set-Content -Path $SourceFile -Encoding UTF8

        Convert-TeamViewerADCConfiguration -Path $SourceFile -Destination $DestinationFile -WhatIf

        Test-Path -Path $DestinationFile | Should -BeFalse
    }

    It 'returns the converted configuration with -PassThru' {
        $SourceFile = Join-Path -Path $TestDrive -ChildPath 'PassThru-source.json'
        $DestinationFile = Join-Path -Path $TestDrive -ChildPath 'PassThru-destination.json'
        @{ ApiToken = 'passthru-token' } | ConvertTo-Json | Set-Content -Path $SourceFile -Encoding UTF8

        $Result = Convert-TeamViewerADCConfiguration -Path $SourceFile -Destination $DestinationFile -PassThru

        $Result.Api_Token | Should -Be 'passthru-token'
        $Result.Filename | Should -Be $DestinationFile
    }
}
