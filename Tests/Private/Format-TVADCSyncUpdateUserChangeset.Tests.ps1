BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Format-TVADCSyncUpdateUserChangeset.ps1"
}

Describe 'Format-TVADCSyncUpdateUserChangeset' {
    It 'formats a name change' {
        $Result = [pscustomobject]@{ name = 'New Name' } | Format-TVADCSyncUpdateUserChangeset

        $Result | Should -Be "Changing name to 'New Name'. "
    }

    It 'formats an activation change' {
        $Result = [pscustomobject]@{ active = $true } | Format-TVADCSyncUpdateUserChangeset

        $Result | Should -Be "Changing account status to 'active'. "
    }

    It 'formats a deactivation change' {
        $Result = [pscustomobject]@{ active = $false } | Format-TVADCSyncUpdateUserChangeset

        $Result | Should -Be "Changing account status to 'inactive'. "
    }

    It 'formats name and status changes in a single message' {
        $Result = [pscustomobject]@{ name = 'New Name'; active = $false } | Format-TVADCSyncUpdateUserChangeset

        $Result | Should -Be "Changing name to 'New Name'. Changing account status to 'inactive'. "
    }

    It 'returns an empty message for an empty changeset' {
        $Result = [pscustomobject]@{} | Format-TVADCSyncUpdateUserChangeset

        $Result | Should -Be ''
    }

    It 'ignores an empty name while formatting a status change' {
        $Result = [pscustomobject]@{ name = ''; active = $true } | Format-TVADCSyncUpdateUserChangeset

        $Result | Should -Be "Changing account status to 'active'. "
    }

    It 'formats each pipeline input independently' {
        $Result = @(
            [pscustomobject]@{ name = 'First Name' }
            [pscustomobject]@{ active = $true }
        ) | Format-TVADCSyncUpdateUserChangeset

        $Result | Should -HaveCount 2
        $Result[0] | Should -Be "Changing name to 'First Name'. "
        $Result[1] | Should -Be "Changing account status to 'active'. "
    }

    It 'declares the changeset as mandatory pipeline input' {
        $Parameter = (Get-Command Format-TVADCSyncUpdateUserChangeset).Parameters['InputObject']

        $Parameter.Attributes.Mandatory | Should -Contain $true
        $Parameter.Attributes.ValueFromPipeline | Should -Contain $true
        @($Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] }).Count | Should -Be 1
    }

    It 'rejects null input' {
        { Format-TVADCSyncUpdateUserChangeset -InputObject $null -ErrorAction Stop } | Should -Throw
    }
}
