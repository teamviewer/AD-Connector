BeforeAll {
    function Add-TeamViewerADCSyncLogLine {
        param($Message)
        $null = $Message
    }
    function Invoke-TeamViewerADCSyncPrework {
        param($Sync_Context, $Configuration, $Progress)
        $null = $Sync_Context, $Configuration, $Progress
    }
    function Invoke-TeamViewerADCSyncUser {
        param($Sync_Context, $Configuration, $Progress)
        $null = $Sync_Context, $Configuration, $Progress
    }
    function Invoke-TeamViewerADCSyncUserGroup {
        param($Sync_Context, $Configuration, $Progress)
        $null = $Sync_Context, $Configuration, $Progress
    }
    function Out-TeamViewerADCSyncProgress {
        param($Handler, $Percent, $Operation)
        $null = $Handler, $Percent, $Operation
    }

    . "$PSScriptRoot\..\..\Cmdlets\Private\Invoke-TeamViewerADCSync.ps1"
}

Describe 'Invoke-TeamViewerADCSync' {
    BeforeEach {
        Mock Add-TeamViewerADCSyncLogLine
        Mock Invoke-TeamViewerADCSyncPrework
        Mock Invoke-TeamViewerADCSyncUser { @{ Activity = 'SyncUser'; Statistics = @{}; Duration = [timespan]::Zero } }
        Mock Invoke-TeamViewerADCSyncUserGroup { @{ Activity = 'SyncUserGroups'; Statistics = @{}; Duration = [timespan]::Zero } }
        Mock Out-TeamViewerADCSyncProgress
    }

    It 'declares the expected advanced function contract' {
        $CommandInfo = Get-Command -Name Invoke-TeamViewerADCSync
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
        $Configuration = [pscustomobject]@{ TestRun = $false; EnableUserGroupsSync = $false }
        $Progress = { }

        $Result = Invoke-TeamViewerADCSync -Configuration $Configuration -Progress $Progress

        $Result[-1].Activity | Should -Be 'Total'
        $Result[-1].Statistics | Should -BeOfType ([hashtable])
        $Result[-1].Duration | Should -BeOfType ([timespan])
        Should -Invoke Invoke-TeamViewerADCSyncPrework -Times 1 -Exactly
        Should -Invoke Invoke-TeamViewerADCSyncUser -Times 1 -Exactly
        Should -Invoke Invoke-TeamViewerADCSyncUserGroup -Times 0 -Exactly
        Should -Invoke Out-TeamViewerADCSyncProgress -Times 1 -Exactly -ParameterFilter {
            $Handler -eq $Progress -and $Percent -eq 100 -and $Operation -eq 'Completed synchronization.'
        }
    }
}
