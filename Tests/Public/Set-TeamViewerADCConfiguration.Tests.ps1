BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCConfigurationDefault.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Private\Import-TVADCConfiguration.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Private\Save-TVADCConfiguration.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Public\Set-TeamViewerADCConfiguration.ps1"
}

Describe 'Set-TeamViewerADCConfiguration' {
    It 'declares a ShouldProcess-enabled object contract' {
        $CommandInfo = Get-Command -Name Set-TeamViewerADCConfiguration

        $CommandInfo.CmdletBinding | Should -BeTrue
        $CommandInfo.OutputType.Type | Should -Contain ([psobject])
        $CommandInfo.Parameters.ContainsKey('WhatIf') | Should -BeTrue
    }

    It 'validates the Api_Uri parameter with a script attribute' {
        $Parameter = (Get-Command Set-TeamViewerADCConfiguration).Parameters['Api_Uri']

        @($Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] }).Count | Should -Be 1
    }

    It 'creates a new configuration file with defaults and the requested setting' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'New\TeamViewerADC.json'

        Set-TeamViewerADCConfiguration -Config_File $ConfigFile -Api_Token 'new-token'

        Test-Path -Path $ConfigFile | Should -BeTrue
        $SavedConfig = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        $SavedConfig.Api_Token | Should -Be 'new-token'
        $SavedConfig.Api_Uri | Should -Be 'https://webapi.teamviewer.com/api/v1'
        $SavedConfig.PSObject.Properties.Name | Should -Not -Contain 'Filename'
    }

    It 'updates a single setting while preserving existing values' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'Existing.json'
        @{ Api_Token = 'keep-token'; TestRun = $true } | ConvertTo-Json | Set-Content -Path $ConfigFile -Encoding UTF8

        Set-TeamViewerADCConfiguration -Config_File $ConfigFile -TestRun $false

        $SavedConfig = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        $SavedConfig.Api_Token | Should -Be 'keep-token'
        $SavedConfig.TestRun | Should -BeFalse
    }

    It 'applies multiple settings in a single call' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'Multi.json'

        Set-TeamViewerADCConfiguration -Config_File $ConfigFile -Api_Uri 'https://webapi.teamviewer.com/api/v1' -ActiveDirectory_Groups @('GroupA', 'GroupB') -Use_GeneratedPassword $true

        $SavedConfig = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        $SavedConfig.Api_Uri | Should -Be 'https://webapi.teamviewer.com/api/v1'
        $SavedConfig.ActiveDirectory_Groups | Should -Be @('GroupA', 'GroupB')
        $SavedConfig.Use_GeneratedPassword | Should -BeTrue
    }

    It 'uses default configurations when called without parameters' {
        Mock Save-TVADCConfiguration {
            param($Configuration)

            $script:SavedConfiguration = $Configuration
        }

        Set-TeamViewerADCConfiguration

        $script:SavedConfiguration.Api_Uri | Should -Be 'https://webapi.teamviewer.com/api/v1'
        $script:SavedConfiguration.TestRun | Should -BeTrue
        $script:SavedConfiguration.Use_GeneratedPassword | Should -BeTrue
        $script:SavedConfiguration.User_DefaultPassword | Should -Be ''
    }

    It 'rejects an invalid meeting license key' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'License.json'

        { Set-TeamViewerADCConfiguration -Config_File $ConfigFile -User_MeetingLicenseKey 'not-a-guid' } | Should -Throw
    }

    It 'accepts a valid meeting license key' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'ValidLicense.json'

        Set-TeamViewerADCConfiguration -Config_File $ConfigFile -User_MeetingLicenseKey '4d00238a-9391-44cd-88ab-631194a97de5'

        (Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json).User_MeetingLicenseKey | Should -Be '4d00238a-9391-44cd-88ab-631194a97de5'
    }

    It 'does not write the configuration when -WhatIf is supplied' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'WhatIf.json'

        Set-TeamViewerADCConfiguration -Config_File $ConfigFile -Api_Token 'unused' -WhatIf

        Test-Path -Path $ConfigFile | Should -BeFalse
    }

    It 'returns the resulting configuration with -PassThru' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'PassThru.json'

        $Result = Set-TeamViewerADCConfiguration -Config_File $ConfigFile -Api_Token 'passthru-token' -PassThru

        $Result.Api_Token | Should -Be 'passthru-token'
        $Result.Filename | Should -Be $ConfigFile
    }
}
