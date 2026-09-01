Describe 'Get-TVADCGuiConfigurationGroup' {
    It 'defines the function' {
        Get-Content -Path "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCGuiConfigurationGroup.ps1" -Raw | Should -Match 'function Get-TVADCGuiConfigurationGroup'
    }
}
