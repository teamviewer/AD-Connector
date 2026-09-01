Describe 'Register-TVADCGuiGroupFiltering' {
    It 'defines the function' {
        Get-Content -Path "$PSScriptRoot\..\..\Cmdlets\Private\Register-TVADCGuiGroupFiltering.ps1" -Raw | Should -Match 'function Register-TVADCGuiGroupFiltering'
    }
}
