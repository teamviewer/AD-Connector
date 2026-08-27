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

    . "$PSScriptRoot\..\..\Cmdlets\Private\Invoke-TVADCSync.ps1"
}

Describe 'Invoke-TVADCSync' {
    BeforeEach {
        Mock Add-TVADCSyncLogLine
        Mock Invoke-TVADCSyncPrework
        Mock Invoke-TVADCSyncUser { @{ Activity = 'SyncUser'; Statistics = @{}; Duration = [timespan]::Zero } }
        Mock Invoke-TVADCSyncUserGroup { @{ Activity = 'SyncUserGroups'; Statistics = @{}; Duration = [timespan]::Zero } }
        Mock Out-TVADCSyncProgress
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
        $Configuration = [pscustomobject]@{ TestRun = $false; Sync_IncludeUserGroups = $false }
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
}
