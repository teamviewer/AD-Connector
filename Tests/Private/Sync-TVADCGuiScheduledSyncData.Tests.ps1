Describe 'Sync-TVADCGuiScheduledSyncData' {
    It 'defines the function' {
        Get-Content -Path "$PSScriptRoot\..\..\Cmdlets\Private\Sync-TVADCGuiScheduledSyncData.ps1" -Raw | Should -Match 'function Sync-TVADCGuiScheduledSyncData'
    }
}
