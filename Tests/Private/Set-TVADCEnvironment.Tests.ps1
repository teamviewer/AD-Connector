BeforeAll {
    function Set-TeamViewerAPIUri {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test double does not change state.')]
        param($NewUri, $Default)
        $null = $NewUri, $Default
    }

    . "$PSScriptRoot\..\..\Cmdlets\Private\Set-TVADCEnvironment.ps1"
}

Describe 'Set-TVADCEnvironment' {
    BeforeEach {
        Mock Set-TeamViewerAPIUri
    }

    It 'requires Configuration parameter' {
        $params = (Get-Command -Name Set-TVADCEnvironment).Parameters
        $params['Configuration'].Attributes.Mandatory | Should -Be $true
    }

    It 'rejects a null configuration' {
        {
            Set-TVADCEnvironment -Configuration $null -ErrorAction Stop
        } | Should -Throw
    }

    It 'sets US endpoint when environment is us' {
        Set-TVADCEnvironment -Configuration ([pscustomobject]@{ Environment = 'us' })
        Should -Invoke Set-TeamViewerAPIUri -ParameterFilter { $NewUri -eq 'https://webapi.us.teamviewer.com/api/v1' }
    }

    It 'sets default endpoint for other environments' {
        Set-TVADCEnvironment -Configuration ([pscustomobject]@{ Environment = 'eu' })
        Should -Invoke Set-TeamViewerAPIUri -ParameterFilter { $Default -eq $true }
    }
}
