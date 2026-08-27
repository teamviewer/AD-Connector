BeforeAll {
    function Add-TVADCSyncLogLine {
        param($Message)
        $null = $Message
    }
    function Invoke-TVADCSyncPrework {
        param($Sync_Context, $Configuration, $Progress)
        $null = $Sync_Context, $Configuration, $Progress
    }
    function Invoke-TVADCSyncUser {
        param($Sync_Context, $Configuration, $Progress)
        $null = $Sync_Context, $Configuration, $Progress
    }
    function Invoke-TVADCSyncUserGroup {
        param($Sync_Context, $Configuration, $Progress)
        $null = $Sync_Context, $Configuration, $Progress
    }
    function Out-TVADCSyncProgress {
        param($Handler, $Percent, $Operation)
        $null = $Handler, $Percent, $Operation
    }
    function Set-TeamViewerAPIUri {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test double does not change state.')]
        param($NewUri, $Default)
        $null = $NewUri, $Default
    }

    . "$PSScriptRoot\..\..\Cmdlets\Private\Invoke-TVADCSync.ps1"
}

Describe 'Invoke-TVADCSync' {
    BeforeEach {
        Mock Add-TVADCSyncLogLine
        Mock Invoke-TVADCSyncPrework
        Mock Invoke-TVADCSyncUser { @{ Activity = 'SyncUser'; Statistics = @{}; Duration = [timespan]::Zero } }
        Mock Invoke-TVADCSyncUserGroup { @{ Activity = 'SyncUserGroups'; Statistics = @{}; Duration = [timespan]::Zero } }
        Mock Out-TVADCSyncProgress
        Mock Set-TeamViewerAPIUri
    }

    It 'declares the expected advanced function contract' {
        $CommandInfo = Get-Command -Name Invoke-TVADCSync
        $ConfigurationParameter = $CommandInfo.Parameters['Configuration']
        $ProgressParameter = $CommandInfo.Parameters['Progress']

        $CommandInfo.CmdletBinding | Should -BeTrue
        $CommandInfo.OutputType.Type | Should -Contain ([hashtable])
        $ConfigurationParameter.ParameterType | Should -Be ([object])
        $ConfigurationParameter.Attributes.Mandatory | Should -Contain $true
        ($ConfigurationParameter.Attributes | Where-Object { $_ -is [ValidateNotNullOrEmpty] }) | Should -Not -BeNullOrEmpty
        $ProgressParameter.ParameterType | Should -Be ([object])
        $ProgressParameter.Attributes.Mandatory | Should -Contain $true
        ($ProgressParameter.Attributes | Where-Object { $_ -is [ValidateNotNullOrEmpty] }) | Should -Not -BeNullOrEmpty
    }

    It 'runs the sync steps and reports completion progress' {
        $Configuration = [pscustomobject]@{ TestRun = $false; Sync_SyncUserGroups = $false }
        $Progress = { }

        $Result = Invoke-TVADCSync -Configuration $Configuration -Progress $Progress

        $Result[-1].Activity | Should -Be 'Total'
        $Result[-1].Statistics | Should -BeOfType ([hashtable])
        $Result[-1].Duration | Should -BeOfType ([timespan])
        Should -Invoke Invoke-TVADCSyncPrework -Times 1 -Exactly
        Should -Invoke Invoke-TVADCSyncUser -Times 1 -Exactly
        Should -Invoke Invoke-TVADCSyncUserGroup -Times 0 -Exactly
        Should -Invoke Out-TVADCSyncProgress -Times 1 -Exactly -ParameterFilter {
            $Handler -eq $Progress -and $Percent -eq 100 -and $Operation -eq 'Completed synchronization.'
        }
    }

    It 'uses the default API URI when Api_Uri is not configured' {
        $Configuration = [pscustomobject]@{ TestRun = $false; Sync_SyncUserGroups = $false; Api_Uri = '' }

        Invoke-TVADCSync -Configuration $Configuration -Progress { } | Out-Null

        Should -Invoke Set-TeamViewerAPIUri -Times 1 -Exactly -ParameterFilter { $Default -eq $true }
    }

    It 'applies the configured Api_Uri' {
        $Configuration = [pscustomobject]@{ TestRun = $false; Sync_SyncUserGroups = $false; Api_Uri = 'https://webapi.teamviewer.com/api/v1' }

        Invoke-TVADCSync -Configuration $Configuration -Progress { } | Out-Null

        Should -Invoke Set-TeamViewerAPIUri -Times 1 -Exactly -ParameterFilter { $NewUri -eq 'https://webapi.teamviewer.com/api/v1' }
    }
}
