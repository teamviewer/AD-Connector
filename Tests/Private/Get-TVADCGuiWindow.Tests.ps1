BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCGuiWindow.ps1"
}

Describe 'Get-TVADCGuiWindow' {
    It 'is defined as a function' {
        Get-Command -Name Get-TVADCGuiWindow | Should -Not -BeNullOrEmpty
    }

    It 'accepts a File parameter' {
        (Get-Command -Name Get-TVADCGuiWindow).Parameters.ContainsKey('File') | Should -Be $true
    }
}
