Describe 'Invoke-TVADCGuiConfiguration' {
    It 'source file exists' {
        Test-Path -Path "$PSScriptRoot\..\..\Cmdlets\Private\Invoke-TVADCGuiConfiguration.ps1" | Should -Be $true
    }

    It 'defines the Invoke-TVADCGuiConfiguration function' {
        $content = Get-Content -Path "$PSScriptRoot\..\..\Cmdlets\Private\Invoke-TVADCGuiConfiguration.ps1" -Raw
        $content | Should -Match 'function Invoke-TVADCGuiConfiguration'
    }

    It 'does not install a scheduled task when the log directory is invalid' {
        $content = Get-Content -Path "$PSScriptRoot\..\..\Cmdlets\Private\Register-TVADCGuiScheduledSyncHandler.ps1" -Raw

        $content | Should -Match '(?s)if \(-not \(Test-Path -PathType ''Container'' \$Window\.DataContext\.ScheduledSyncData\.LogDirectory\)\) \{.*?LogDirectoryWarning.*?return.*?\}.*?New-TeamViewerADCScheduledTask'
    }
}
