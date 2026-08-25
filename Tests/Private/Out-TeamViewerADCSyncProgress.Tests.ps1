BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Out-TeamViewerADCSyncProgress.ps1"
}

Describe 'Out-TeamViewerADCSyncProgress' {
    It 'declares an advanced void function' {
        $Command = Get-Command Out-TeamViewerADCSyncProgress

        $Command.CmdletBinding | Should -BeTrue
        $Command.OutputType.Type | Should -Contain ([void])
    }

    It 'requires a scriptblock handler and a percentage' {
        $Command = Get-Command Out-TeamViewerADCSyncProgress
        $HandlerParameter = $Command.Parameters['Handler']
        $PercentParameter = $Command.Parameters['Percent']
        $OperationParameter = $Command.Parameters['Operation']

        $HandlerParameter.ParameterType | Should -Be ([scriptblock])
        $HandlerParameter.Attributes.Mandatory | Should -Contain $true
        ($HandlerParameter.Attributes | Where-Object { $_ -is [ValidateNotNullOrEmpty] }) | Should -Not -BeNullOrEmpty
        $PercentParameter.ParameterType | Should -Be ([int])
        $PercentParameter.Attributes.Mandatory | Should -Contain $true
        ($PercentParameter.Attributes | Where-Object { $_ -is [ValidateRange] }) | Should -Not -BeNullOrEmpty
        $OperationParameter.ParameterType | Should -Be ([string])
        $OperationParameter.Attributes.Mandatory | Should -Not -Contain $true
    }

    It 'forwards the percentage and operation to the handler' {
        $Calls = [System.Collections.Generic.List[object]]::new()
        $Handler = {
            param($Percent, $Operation)

            $Calls.Add(@($Percent, $Operation))
        }.GetNewClosure()

        Out-TeamViewerADCSyncProgress -Handler $Handler -Percent 42 -Operation 'SyncUsers'

        $Calls.Count | Should -Be 1
        $Calls[0] | Should -Be @(42, 'SyncUsers')
    }

    It 'does not emit handler output' {
        $Result = Out-TeamViewerADCSyncProgress -Handler { 'handler output' } -Percent 0

        $Result | Should -BeNullOrEmpty
    }

    It 'accepts the completion boundaries' {
        { Out-TeamViewerADCSyncProgress -Handler { } -Percent 0 } | Should -Not -Throw
        { Out-TeamViewerADCSyncProgress -Handler { } -Percent 100 } | Should -Not -Throw
    }

    It 'rejects an invalid percentage or null handler' {
        { Out-TeamViewerADCSyncProgress -Handler { } -Percent -1 -ErrorAction Stop } | Should -Throw
        { Out-TeamViewerADCSyncProgress -Handler { } -Percent 101 -ErrorAction Stop } | Should -Throw
        { Out-TeamViewerADCSyncProgress -Handler $null -Percent 50 -ErrorAction Stop } | Should -Throw
    }
}
