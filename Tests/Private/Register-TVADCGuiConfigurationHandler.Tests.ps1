Describe 'Register-TVADCGuiConfigurationHandler' {
    It 'defines the function' {
        Get-Content -Path "$PSScriptRoot\..\..\Cmdlets\Private\Register-TVADCGuiConfigurationHandler.ps1" -Raw | Should -Match 'function Register-TVADCGuiConfigurationHandler'
    }
}
