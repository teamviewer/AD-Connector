BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Import-TVADCConfiguration.ps1"
}

Describe 'Import-TVADCConfiguration' {
    It 'declares an object output contract' {
        $CommandInfo = Get-Command -Name Import-TVADCConfiguration

        $CommandInfo.OutputType.Type | Should -Contain ([psobject])
    }

    It 'retains the source configuration path for later saves' {
        $SourceConfigFile = Join-Path -Path $TestDrive -ChildPath 'TeamViewerADC.json'

        @{ Api_Token = 'test-token' } | ConvertTo-Json | Set-Content -Path $SourceConfigFile -Encoding UTF8

        $ConfigContent = Import-TVADCConfiguration -Config_File $SourceConfigFile

        $ConfigContent.Filename | Should -Be $SourceConfigFile
    }

    It 'preserves configured values and adds the established defaults' {
        $SourceConfigFile = Join-Path -Path $TestDrive -ChildPath 'TeamViewerADC.json'

        @{ Api_Token = 'test-token' } | ConvertTo-Json | Set-Content -Path $SourceConfigFile -Encoding UTF8

        $ConfigContent = Import-TVADCConfiguration -Config_File $SourceConfigFile

        $ConfigContent.Api_Token | Should -Be 'test-token'
        $ConfigContent.ActiveDirectory_Groups | Should -BeNullOrEmpty
        $ConfigContent.Use_DefaultPassword | Should -BeTrue
        $ConfigContent.Use_GeneratedPassword | Should -BeFalse
        $ConfigContent.Environment | Should -Be 'global'
        $ConfigContent.PSObject.Properties.Name | Should -Not -Contain 'ApiToken'
    }

    It 'adds every established default to an empty configuration' {
        $SourceConfigFile = Join-Path -Path $TestDrive -ChildPath 'Empty.json'
        '{}' | Set-Content -Path $SourceConfigFile -Encoding UTF8

        $ConfigContent = Import-TVADCConfiguration -Config_File $SourceConfigFile

        $ConfigContent.Environment | Should -Be 'global'
        $ConfigContent.Api_Token | Should -Be ''
        $ConfigContent.TestRun | Should -BeTrue
        $ConfigContent.ActiveDirectory_Root | Should -Be ''
        $ConfigContent.ActiveDirectory_Groups | Should -BeNullOrEmpty
        $ConfigContent.User_Language | Should -Be 'en'
        $ConfigContent.User_MeetingLicenseKey | Should -Be ''
        $ConfigContent.User_DefaultPassword | Should -Be ''
        $ConfigContent.Sso_CustomerId | Should -Be ''
        $ConfigContent.Use_DefaultPassword | Should -BeTrue
        $ConfigContent.Use_GeneratedPassword | Should -BeFalse
        $ConfigContent.Use_SsoCustomerId | Should -BeFalse
        $ConfigContent.Sync_DeactivateUsers | Should -BeTrue
        $ConfigContent.Sync_UseSecondaryEmails | Should -BeTrue
        $ConfigContent.Sync_IncludeUserGroups | Should -BeFalse
        $ConfigContent.Sync_RecursiveUserGroups | Should -BeTrue
    }

    It 'preserves configured values without replacing them with defaults' {
        $SourceConfigFile = Join-Path -Path $TestDrive -ChildPath 'Configured.json'
        $ConfiguredValues = @{
            Environment              = 'preview'
            Api_Token                = 'configured-token'
            TestRun                  = $false
            ActiveDirectory_Root     = 'LDAP://DC=example,DC=com'
            ActiveDirectory_Groups   = @('GroupA', 'GroupB')
            User_Language            = 'de'
            Use_DefaultPassword      = $false
            Use_GeneratedPassword    = $true
            Use_SsoCustomerId        = $true
            Sync_DeactivateUsers     = $false
            Sync_UseSecondaryEmails  = $false
            Sync_IncludeUserGroups   = $true
            Sync_RecursiveUserGroups = $false
        }
        $ConfiguredValues | ConvertTo-Json | Set-Content -Path $SourceConfigFile -Encoding UTF8

        $ConfigContent = Import-TVADCConfiguration -Config_File $SourceConfigFile

        $ConfigContent.Environment | Should -Be 'preview'
        $ConfigContent.Api_Token | Should -Be 'configured-token'
        $ConfigContent.TestRun | Should -BeFalse
        $ConfigContent.ActiveDirectory_Groups | Should -Be @('GroupA', 'GroupB')
        $ConfigContent.User_Language | Should -Be 'de'
        $ConfigContent.Use_DefaultPassword | Should -BeFalse
        $ConfigContent.Use_GeneratedPassword | Should -BeTrue
        $ConfigContent.Use_SsoCustomerId | Should -BeTrue
        $ConfigContent.Sync_DeactivateUsers | Should -BeFalse
        $ConfigContent.Sync_UseSecondaryEmails | Should -BeFalse
        $ConfigContent.Sync_IncludeUserGroups | Should -BeTrue
        $ConfigContent.Sync_RecursiveUserGroups | Should -BeFalse
    }

    It 'rejects a configuration path that does not exist' {
        $MissingConfigFile = Join-Path -Path $TestDrive -ChildPath 'Missing.json'

        { Import-TVADCConfiguration -Config_File $MissingConfigFile -ErrorAction Stop } | Should -Throw
    }

    It 'rejects a directory as the configuration path' {
        { Import-TVADCConfiguration -Config_File $TestDrive -ErrorAction Stop } | Should -Throw
    }

    It 'propagates malformed JSON errors' {
        $SourceConfigFile = Join-Path -Path $TestDrive -ChildPath 'Malformed.json'
        '{ invalid json' | Set-Content -Path $SourceConfigFile -Encoding UTF8

        { Import-TVADCConfiguration -Config_File $SourceConfigFile -ErrorAction Stop } | Should -Throw
    }

    It 'declares a string configuration path parameter' {
        $CommandInfo = Get-Command -Name Import-TVADCConfiguration
        $Parameter = $CommandInfo.Parameters['Config_File']

        $CommandInfo.CmdletBinding | Should -BeTrue
        $Parameter.ParameterType | Should -Be ([string])
        @($Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] }).Count | Should -Be 1
    }
}
