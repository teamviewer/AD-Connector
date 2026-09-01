<#
.NOTES
PSScriptAnalyzer suppression: ConvertTo-SecureString with -AsPlainText is acceptable in test files
for creating test data with known values.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCConfigurationDefault.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Private\Save-TVADCConfiguration.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Private\Test-TVADCConfiguration.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Public\New-TeamViewerADCConfiguration.ps1"
}

Describe 'New-TeamViewerADCConfiguration' {
    It 'declares a ShouldProcess-enabled object contract' {
        $CommandInfo = Get-Command -Name New-TeamViewerADCConfiguration

        $CommandInfo.CmdletBinding | Should -BeTrue
        $CommandInfo.OutputType.Type | Should -Contain ([psobject])
        $CommandInfo.Parameters.ContainsKey('WhatIf') | Should -BeTrue
        $CommandInfo.Parameters.ContainsKey('Confirm') | Should -BeTrue
    }

    It 'validates the Api_Uri parameter with a script attribute' {
        $Parameter = (Get-Command New-TeamViewerADCConfiguration).Parameters['Api_Uri']

        @($Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] }).Count | Should -Be 1
    }

    It 'validates the User_MeetingLicenseKey parameter with a script attribute' {
        $Parameter = (Get-Command New-TeamViewerADCConfiguration).Parameters['User_MeetingLicenseKey']

        @($Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] }).Count | Should -Be 1
    }

    It 'creates a new configuration file with all defaults' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'New\TeamViewerADC.json'

        New-TeamViewerADCConfiguration -Config_File $ConfigFile

        Test-Path -Path $ConfigFile | Should -BeTrue
        $SavedConfig = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        $SavedConfig.Api_Uri | Should -Be 'https://webapi.teamviewer.com/api/v1'
        $SavedConfig.TestRun | Should -BeTrue
        $SavedConfig.Use_GeneratedPassword | Should -BeTrue
        $SavedConfig.PSObject.Properties.Name | Should -Not -Contain 'Filename'
    }

    It 'creates a new configuration with custom values' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'Custom\TeamViewerADC.json'

        New-TeamViewerADCConfiguration -Config_File $ConfigFile -Api_Token 'custom-token' -ActiveDirectory_Groups @('GroupA', 'GroupB') -TestRun $false

        Test-Path -Path $ConfigFile | Should -BeTrue
        $SavedConfig = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        $SavedConfig.Api_Token | Should -Be 'custom-token'
        $SavedConfig.ActiveDirectory_Groups | Should -Be @('GroupA', 'GroupB')
        $SavedConfig.TestRun | Should -BeFalse
    }

    It 'rejects if the configuration file already exists without -Force' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'Existing.json'
        @{ Api_Token = 'existing' } | ConvertTo-Json | Set-Content -Path $ConfigFile -Encoding UTF8

        { New-TeamViewerADCConfiguration -Config_File $ConfigFile -ErrorAction Stop } | Should -Throw -ExpectedMessage '*already exists*'
    }

    It 'overwrites the configuration file with -Force' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'Force.json'
        @{ Api_Token = 'old-token' } | ConvertTo-Json | Set-Content -Path $ConfigFile -Encoding UTF8

        New-TeamViewerADCConfiguration -Config_File $ConfigFile -Api_Token 'new-token' -Force

        $SavedConfig = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        $SavedConfig.Api_Token | Should -Be 'new-token'
    }

    It 'does not write the configuration when -WhatIf is supplied' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'WhatIf.json'

        New-TeamViewerADCConfiguration -Config_File $ConfigFile -Api_Token 'unused' -WhatIf

        Test-Path -Path $ConfigFile | Should -BeFalse
    }

    It 'returns the resulting configuration with -PassThru' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'PassThru.json'

        $Result = New-TeamViewerADCConfiguration -Config_File $ConfigFile -Api_Token 'passthru-token' -PassThru

        $Result | Should -Not -BeNullOrEmpty
        $Result.Api_Token | Should -Be 'passthru-token'
        $Result.Filename | Should -Be $ConfigFile
    }

    It 'does not return output by default' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'NoOutput.json'

        $Result = New-TeamViewerADCConfiguration -Config_File $ConfigFile -Api_Token 'token'

        $Result | Should -BeNullOrEmpty
    }

    It 'creates parent directories automatically' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'Deep\Nested\Structure\TeamViewerADC.json'

        New-TeamViewerADCConfiguration -Config_File $ConfigFile

        Test-Path -Path $ConfigFile | Should -BeTrue
        Test-Path -Path (Split-Path -Path $ConfigFile -Parent) -PathType Container | Should -BeTrue
    }

    It 'validates the configuration before writing' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'Invalid.json'

        # All three password methods disabled should fail validation
        { New-TeamViewerADCConfiguration -Config_File $ConfigFile -Use_DefaultPassword $false -Use_GeneratedPassword $false -Use_SsoCustomerId $false -ErrorAction Stop } | Should -Throw
    }

    It 'rejects an invalid meeting license key' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'License.json'

        { New-TeamViewerADCConfiguration -Config_File $ConfigFile -User_MeetingLicenseKey 'not-a-guid' -ErrorAction Stop } | Should -Throw
    }

    It 'accepts a valid meeting license key' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'ValidLicense.json'

        New-TeamViewerADCConfiguration -Config_File $ConfigFile -User_MeetingLicenseKey '4d00238a-9391-44cd-88ab-631194a97de5'

        (Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json).User_MeetingLicenseKey | Should -Be '4d00238a-9391-44cd-88ab-631194a97de5'
    }

    It 'accepts a secure string password' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'SecurePassword.json'
        $SecurePassword = ConvertTo-SecureString -String 'password123' -AsPlainText -Force

        New-TeamViewerADCConfiguration -Config_File $ConfigFile -Use_DefaultPassword $true -Use_GeneratedPassword $false -User_DefaultPassword $SecurePassword

        Test-Path -Path $ConfigFile | Should -BeTrue
    }

    It 'uses the default configuration file path when not specified' {
        # Get the expected default path from the module directory
        $DefaultPath = Join-Path -Path (Split-Path -Path (Get-Command New-TeamViewerADCConfiguration).ScriptBlock.File) -ChildPath 'Config\TeamViewerADC.json'

        # Create a temporary config directory structure to test with
        $ConfigDir = Split-Path -Path $DefaultPath -Parent
        if (-not (Test-Path -Path $ConfigDir -PathType Container)) {
            New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
        }

        try {
            New-TeamViewerADCConfiguration

            Test-Path -Path $DefaultPath | Should -BeTrue
        }
        finally {
            # Clean up
            if (Test-Path -Path $DefaultPath) {
                Remove-Item -Path $DefaultPath -Force
            }
        }
    }

    It 'applies multiple configuration settings in a single call' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'Multi.json'

        New-TeamViewerADCConfiguration -Config_File $ConfigFile `
            -Api_Uri 'https://webapi.teamviewer.com/api/v1' `
            -Api_Token 'multi-token' `
            -ActiveDirectory_Root 'DC=contoso,DC=com' `
            -User_Language 'de' `
            -Sync_DeactivateUsers $false `
            -Sync_IncludeUserGroups $true

        $SavedConfig = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        $SavedConfig.Api_Token | Should -Be 'multi-token'
        $SavedConfig.ActiveDirectory_Root | Should -Be 'DC=contoso,DC=com'
        $SavedConfig.User_Language | Should -Be 'de'
        $SavedConfig.Sync_DeactivateUsers | Should -BeFalse
        $SavedConfig.Sync_IncludeUserGroups | Should -BeTrue
    }
}
