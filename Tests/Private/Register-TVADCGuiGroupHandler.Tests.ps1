Describe 'Register-TVADCGuiGroupHandler' {
    It 'defines the function' {
        Get-Content -Path "$PSScriptRoot\..\..\Cmdlets\Private\Register-TVADCGuiGroupHandler.ps1" -Raw | Should -Match 'function Register-TVADCGuiGroupHandler'
    }
}
