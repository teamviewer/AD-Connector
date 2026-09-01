BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCGuiSupportedLocale.ps1"
}

Describe 'Get-TVADCGuiSupportedLocale' {
    It 'returns array of locale codes' {
        $result = Get-TVADCGuiSupportedLocale
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Contain 'en'
    }
}
