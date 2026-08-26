Describe 'New-TVADCGuiConfigurationData' {
    It 'defines the function' {
        Get-Content -Path "$PSScriptRoot\..\..\Cmdlets\Private\New-TVADCGuiConfigurationData.ps1" -Raw | Should -Match 'function New-TVADCGuiConfigurationData'
    }
}
