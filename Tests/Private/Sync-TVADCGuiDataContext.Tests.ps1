Describe 'Sync-TVADCGuiDataContext' {
    It 'defines the function' {
        Get-Content -Path "$PSScriptRoot\..\..\Cmdlets\Private\Sync-TVADCGuiDataContext.ps1" -Raw | Should -Match 'function Sync-TVADCGuiDataContext'
    }
}
