BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Format-TVADCSyncLog.ps1"
}

Describe 'Format-TVADCSyncLog' {
    It 'formats a log entry with its timestamp and message' {
        $Date = [datetime]'2024-01-02 03:04:05'

        $Result = [pscustomobject]@{ Date = $Date; Message = 'Started' } | Format-TVADCSyncLog

        $Result | Should -Be '2024-01-02 03:04:05 Started'
    }

    It 'formats an empty log message instead of passing the entry through' {
        $Date = [datetime]'2024-01-02 03:04:05'

        $Result = [pscustomobject]@{ Date = $Date; Message = '' } | Format-TVADCSyncLog

        $Result | Should -Be '2024-01-02 03:04:05 '
    }

    It 'uses the current date when a log entry has no date' {
        Mock Get-Date { [datetime]'2024-06-07 08:09:10' }

        $Result = [pscustomobject]@{ Message = 'Started' } | Format-TVADCSyncLog

        $Result | Should -Be '2024-06-07 08:09:10 Started'
        Should -Invoke Get-Date -Exactly 1
    }

    It 'formats a synchronization summary without table padding' {
        $Result = [pscustomobject]@{
            Activity   = 'Total'
            Statistics = [pscustomobject]@{ Added = 2; Updated = 1 }
            Duration   = [timespan]::FromSeconds(3)
        } | Format-TVADCSyncLog

        $Result[0] | Should -Match '2'
        $Result[0] | Should -Match '1'
        $Result[1] | Should -Be 'Duration Total: 00:00:03'
    }

    It 'passes unrelated input through unchanged' {
        $InputObject = [pscustomobject]@{ Value = 'unchanged' }

        $Result = $InputObject | Format-TVADCSyncLog

        $Result | Should -Be $InputObject
    }

    It 'formats each pipeline input independently' {
        $Date = [datetime]'2024-01-02 03:04:05'
        $Result = @(
            [pscustomobject]@{ Date = $Date; Message = 'Started' }
            [pscustomobject]@{ Date = $Date; Message = 'Finished' }
        ) | Format-TVADCSyncLog

        $Result | Should -HaveCount 2
        $Result[0] | Should -Be '2024-01-02 03:04:05 Started'
        $Result[1] | Should -Be '2024-01-02 03:04:05 Finished'
    }

    It 'rejects null input' {
        { Format-TVADCSyncLog -InputObject $null -ErrorAction Stop } | Should -Throw
    }

    It 'declares mandatory validated pipeline input' {
        $Parameter = (Get-Command Format-TVADCSyncLog).Parameters['InputObject']

        $Parameter.Attributes.Mandatory | Should -Contain $true
        $Parameter.Attributes.ValueFromPipeline | Should -Contain $true
        @($Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] }).Count | Should -Be 1
    }
}
