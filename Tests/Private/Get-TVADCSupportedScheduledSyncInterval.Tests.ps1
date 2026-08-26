BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCSupportedScheduledSyncInterval.ps1"
}

Describe 'Get-TVADCSupportedScheduledSyncInterval' {
    It 'returns supported intervals' {
        $result = Get-TVADCSupportedScheduledSyncInterval
        $result | Should -Be @(4, 8, 16, 24)
    }
}
