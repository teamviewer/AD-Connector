Describe 'Invoke-TVADCGuiSync' {
    It 'source file exists' {
        Test-Path -Path "$PSScriptRoot\..\..\Cmdlets\Private\Invoke-TVADCGuiSync.ps1" | Should -Be $true
    }

    It 'defines the Invoke-TVADCGuiSync function' {
        $content = Get-Content -Path "$PSScriptRoot\..\..\Cmdlets\Private\Invoke-TVADCGuiSync.ps1" -Raw
        $content | Should -Match 'function Invoke-TVADCGuiSync'
    }
}
