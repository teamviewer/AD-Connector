Describe 'Register-TVADCGuiTokenHandler' {
    It 'defines the function' {
        Get-Content -Path "$PSScriptRoot\..\..\Cmdlets\Private\Register-TVADCGuiTokenHandler.ps1" -Raw | Should -Match 'function Register-TVADCGuiTokenHandler'
    }
}
