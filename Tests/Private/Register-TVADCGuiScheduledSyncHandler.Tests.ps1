Describe 'Register-TVADCGuiScheduledSyncHandler' {
    It 'defines the function' {
        Get-Content -Path "$PSScriptRoot\..\..\Cmdlets\Private\Register-TVADCGuiScheduledSyncHandler.ps1" -Raw | Should -Match 'function Register-TVADCGuiScheduledSyncHandler'
    }
}
