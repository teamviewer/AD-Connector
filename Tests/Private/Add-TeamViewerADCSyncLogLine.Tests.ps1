BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Add-TeamViewerADCSyncLogLine.ps1"
}

Describe 'Add-TeamViewerADCSyncLogLine' {
    It 'declares a hashtable output type' {
        $Command = Get-Command Add-TeamViewerADCSyncLogLine

        $Command.OutputType.Type | Should -Contain ([hashtable])
    }

    It 'requires a non-empty message from the pipeline' {
        $Command = Get-Command Add-TeamViewerADCSyncLogLine
        $MessageParameter = $Command.Parameters['Message']

        $MessageParameter.ParameterType | Should -Be ([string])
        $MessageParameter.Attributes.Mandatory | Should -Contain $true
        ($MessageParameter.Attributes | Where-Object { $_ -is [ValidateNotNullOrEmpty] }) | Should -Not -BeNullOrEmpty
        $MessageParameter.Attributes.ValueFromPipeline | Should -Contain $true
    }

    It 'emits a timestamped log record with the message and extra data' {
        $Extra = 'Additional context'
        $Before = Get-Date
        $Result = 'Test message' | Add-TeamViewerADCSyncLogLine -Extra $Extra
        $After = Get-Date

        $Result | Should -BeOfType ([hashtable])
        $Result.Message | Should -Be 'Test message'
        $Result.Extra | Should -Be $Extra
        $Result.Date | Should -BeOfType ([datetime])
        $Result.Date | Should -BeGreaterOrEqual $Before
        $Result.Date | Should -BeLessOrEqual $After
    }

    It 'accepts multiple messages from the pipeline' {
        $Results = 'First', 'Second' | Add-TeamViewerADCSyncLogLine

        $Results.Count | Should -Be 2
        $Results.Message | Should -Be @('First', 'Second')
    }

    It 'rejects an empty message' {
        { Add-TeamViewerADCSyncLogLine -Message '' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects a null message' {
        { Add-TeamViewerADCSyncLogLine -Message $null -ErrorAction Stop } | Should -Throw
    }
}
