BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Split-TeamViewerADCUserGroupMemberId.ps1"
}

Describe 'Split-TeamViewerADCUserGroupMemberId' {
    It 'declares pipeline input and its output type' {
        $CommandInfo = Get-Command -Name Split-TeamViewerADCUserGroupMemberId

        $InputParameter = $CommandInfo.Parameters['InputObject']

        $CommandInfo.CmdletBinding | Should -BeTrue
        $CommandInfo.OutputType.Type | Should -Contain ([System.Array])

        $InputParameter.Attributes.Mandatory | Should -Contain $true
        $InputParameter.Attributes.ValueFromPipeline | Should -Contain $true
    }

    It 'uses a default batch size of 100' {
        $InputIds = 1..101

        $Result = @($InputIds | Split-TeamViewerADCUserGroupMemberId)

        $Result | Should -HaveCount 2
        $Result[0].Count | Should -Be 100
        $Result[1].Count | Should -Be 1
    }

    It 'splits pipeline input into ordered batches' {
        $InputIds = 1..5

        $Result = @($InputIds | Split-TeamViewerADCUserGroupMemberId -Size 2)

        $Result | Should -HaveCount 3
        $Result[0] | Should -Be ([int[]](1, 2))
        $Result[1] | Should -Be ([int[]](3, 4))
        $Result[2] | Should -Be ([int[]](5))
    }

    It 'does not emit an empty trailing batch at an exact boundary' {
        $InputIds = 1..4

        $Result = @($InputIds | Split-TeamViewerADCUserGroupMemberId -Size 2)

        $Result | Should -HaveCount 2
        $Result[0].Count | Should -Be 2
        $Result[1].Count | Should -Be 2
    }

    It 'preserves each batch as an ArrayList' {
        $Result = @((1..3) | Split-TeamViewerADCUserGroupMemberId -Size 2)

        $Result[0] -is [System.Collections.ArrayList] | Should -BeTrue
        $Result[1] -is [System.Collections.ArrayList] | Should -BeTrue
    }

    It 'rejects a non-positive batch size' {
        { Split-TeamViewerADCUserGroupMemberId -InputObject 1 -Size 0 -ErrorAction Stop } | Should -Throw
        { Split-TeamViewerADCUserGroupMemberId -InputObject 1 -Size -1 -ErrorAction Stop } | Should -Throw
    }

    It 'rejects null and empty input' {
        { Split-TeamViewerADCUserGroupMemberId -InputObject $null -ErrorAction Stop } | Should -Throw
        { Split-TeamViewerADCUserGroupMemberId -InputObject '' -ErrorAction Stop } | Should -Throw
    }
}
