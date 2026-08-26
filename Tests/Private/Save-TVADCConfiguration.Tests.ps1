BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Save-TVADCConfiguration.ps1"
}

Describe 'Save-TVADCConfiguration' {
    It 'declares a void output contract' {
        $CommandInfo = Get-Command -Name Save-TVADCConfiguration

        $CommandInfo.OutputType.Type | Should -Contain ([void])
        $ConfigContentParameter = $CommandInfo.Parameters['Configuration']
        $ConfigContentParameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory
        } | Should -Not -BeNullOrEmpty
    }

    It 'writes configuration properties to the configured file without Filename metadata' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'TeamViewerADC.json'

        $ConfigContent = [pscustomobject]@{
            Api_Token             = 'test-token'
            Use_GeneratedPassword = $true
            Filename              = $ConfigFile
        }

        $Result = @(Save-TVADCConfiguration -Configuration $ConfigContent)

        $Result | Should -BeNullOrEmpty
        $SavedConfig = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        $SavedConfig.Api_Token | Should -Be 'test-token'
        $SavedConfig.Use_GeneratedPassword | Should -BeTrue
        $SavedConfig.PSObject.Properties.Name | Should -Not -Contain 'Filename'
    }

    It 'round-trips arrays and Unicode values' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'Unicode.json'
        $UnicodeGroup = "M$([char]252)nchen"
        $ConfigContent = [pscustomobject]@{
            User_Language          = 'de'
            ActiveDirectory_Groups = @($UnicodeGroup, 'Group')
            Filename               = $ConfigFile
        }

        Save-TVADCConfiguration -Configuration $ConfigContent

        $SavedConfig = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        $SavedConfig.User_Language | Should -Be 'de'
        $SavedConfig.ActiveDirectory_Groups | Should -Be @($UnicodeGroup, 'Group')
    }

    It 'overwrites an existing configuration file' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'Overwrite.json'
        'old content' | Set-Content -Path $ConfigFile -Encoding UTF8
        $ConfigContent = [pscustomobject]@{
            Api_Token = 'new-token'
            Filename  = $ConfigFile
        }

        Save-TVADCConfiguration -Configuration $ConfigContent

        $SavedConfig = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        $SavedConfig.Api_Token | Should -Be 'new-token'
    }

    It 'rejects configuration content without a Filename destination' {
        $ConfigContent = [pscustomobject]@{ Api_Token = 'test-token' }

        { Save-TVADCConfiguration -Configuration $ConfigContent -ErrorAction Stop } | Should -Throw
    }

    It 'declares a mandatory object configuration parameter with null validation' {
        $CommandInfo = Get-Command -Name Save-TVADCConfiguration
        $Parameter = $CommandInfo.Parameters['Configuration']

        $CommandInfo.CmdletBinding | Should -BeTrue
        $Parameter.ParameterType | Should -Be ([object])
        $Parameter.Attributes.Mandatory | Should -Contain $true
        @($Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] }).Count | Should -Be 1
    }

    It 'rejects a null configuration object' {
        { Save-TVADCConfiguration -Configuration $null } | Should -Throw
    }
}
