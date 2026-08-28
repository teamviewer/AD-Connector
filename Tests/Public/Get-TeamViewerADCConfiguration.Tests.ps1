BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCConfigurationDefault.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Private\Import-TVADCConfiguration.ps1"
    . "$PSScriptRoot\..\..\Cmdlets\Public\Get-TeamViewerADCConfiguration.ps1"
}

Describe 'Get-TeamViewerADCConfiguration' {
    It 'declares an object output contract' {
        $CommandInfo = Get-Command -Name Get-TeamViewerADCConfiguration

        $CommandInfo.CmdletBinding | Should -BeTrue
        $CommandInfo.OutputType.Type | Should -Contain ([psobject])
    }

    It 'validates the configuration path with a script attribute' {
        $Parameter = (Get-Command Get-TeamViewerADCConfiguration).Parameters['Config_File']

        $Parameter.ParameterType | Should -Be ([string])
        @($Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] }).Count | Should -Be 1
    }

    It 'returns the configuration stored in the file, merged with defaults' {
        $ConfigFile = Join-Path -Path $TestDrive -ChildPath 'TeamViewerADC.json'
        @{ Api_Token = 'stored-token' } | ConvertTo-Json | Set-Content -Path $ConfigFile -Encoding UTF8

        $Configuration = Get-TeamViewerADCConfiguration -Config_File $ConfigFile

        $Configuration.Api_Token | Should -Be 'stored-token'
        $Configuration.Api_Uri | Should -Be 'https://webapi.teamviewer.com/api/v1'
        $Configuration.Filename | Should -Be $ConfigFile
    }

    It 'rejects a configuration path that does not exist' {
        $MissingFile = Join-Path -Path $TestDrive -ChildPath 'Missing.json'

        { Get-TeamViewerADCConfiguration -Config_File $MissingFile -ErrorAction Stop } | Should -Throw
    }
}
