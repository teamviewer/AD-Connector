BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCGuiLocale.ps1"
}

Describe 'Get-TVADCGuiLocale' {
    It 'is defined as a function' {
        Get-Command -Name Get-TVADCGuiLocale | Should -Not -BeNullOrEmpty
    }

    It 'accepts a culture parameter' {
        (Get-Command -Name Get-TVADCGuiLocale).Parameters.ContainsKey('culture') | Should -Be $true
    }
}
