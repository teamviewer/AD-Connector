BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Test-TVADCConfiguration.ps1"
}

Describe 'Test-TVADCConfiguration' {
    It 'declares a void output contract' {
        $CommandInfo = Get-Command -Name Test-TVADCConfiguration

        $CommandInfo.OutputType.Type | Should -Contain ([void])
        $CommandInfo.CmdletBinding | Should -BeTrue
        $ConfigContentParameter = $CommandInfo.Parameters['Configuration']
        $ConfigContentParameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory
        } | Should -Not -BeNullOrEmpty
    }

    It 'accepts a valid generated-password configuration' {
        $ValidConfiguration = [pscustomobject]@{
            Use_DefaultPassword    = $false
            Use_GeneratedPassword  = $true
            Use_SsoCustomerId      = $false
            User_MeetingLicenseKey = ''
        }

        { Test-TVADCConfiguration -Configuration $ValidConfiguration } | Should -Not -Throw
        @(Test-TVADCConfiguration -Configuration $ValidConfiguration) | Should -BeNullOrEmpty
    }

    It 'accepts valid default-password and SSO configurations' -ForEach @(
        @{
            Use_DefaultPassword   = $true
            Use_GeneratedPassword = $false
            Use_SsoCustomerId     = $false
            User_DefaultPassword  = 'test-password'
        }
        @{
            Use_DefaultPassword   = $false
            Use_GeneratedPassword = $false
            Use_SsoCustomerId     = $true
            Sso_CustomerId        = 'customer-id'
        }
    ) {
        $ValidConfiguration = [pscustomobject]$_

        { Test-TVADCConfiguration -Configuration $ValidConfiguration } | Should -Not -Throw
    }

    It 'accepts a configuration without a meeting license key' {
        $ValidConfiguration = [pscustomobject]@{
            Use_DefaultPassword    = $false
            Use_GeneratedPassword  = $true
            Use_SsoCustomerId      = $false
            User_MeetingLicenseKey = $null
        }

        { Test-TVADCConfiguration -Configuration $ValidConfiguration } | Should -Not -Throw
    }

    It 'rejects configurations with zero or multiple account modes enabled' -ForEach @(
        @{ Use_DefaultPassword = $false; Use_GeneratedPassword = $false; Use_SsoCustomerId = $false }
        @{ Use_DefaultPassword = $true; Use_GeneratedPassword = $true; Use_SsoCustomerId = $false }
        @{ Use_DefaultPassword = $true; Use_GeneratedPassword = $false; Use_SsoCustomerId = $true }
        @{ Use_DefaultPassword = $false; Use_GeneratedPassword = $true; Use_SsoCustomerId = $true }
    ) {
        $InvalidConfiguration = [pscustomobject]$_

        { Test-TVADCConfiguration -Configuration $InvalidConfiguration } | Should -Throw
    }

    It 'rejects an empty dependent account value' -ForEach @(
        @{
            Use_DefaultPassword   = $true
            Use_GeneratedPassword = $false
            Use_SsoCustomerId     = $false
            User_DefaultPassword  = ' '
        }
        @{
            Use_DefaultPassword   = $false
            Use_GeneratedPassword = $false
            Use_SsoCustomerId     = $true
            Sso_CustomerId        = ''
        }
    ) {
        $InvalidConfiguration = [pscustomobject]$_

        { Test-TVADCConfiguration -Configuration $InvalidConfiguration } | Should -Throw
    }

    It 'rejects whitespace in the SSO customer identifier' {
        $InvalidConfiguration = [pscustomobject]@{
            Use_DefaultPassword   = $false
            Use_GeneratedPassword = $false
            Use_SsoCustomerId     = $true
            Sso_CustomerId        = "`t `n"
        }

        { Test-TVADCConfiguration -Configuration $InvalidConfiguration } | Should -Throw
    }

    It 'reports the account-mode validation error' {
        $InvalidConfiguration = [pscustomobject]@{
            Use_DefaultPassword   = $false
            Use_GeneratedPassword = $false
            Use_SsoCustomerId     = $false
        }

        try {
            Test-TVADCConfiguration -Configuration $InvalidConfiguration
        }
        catch {
            $_.Exception.Message | Should -Be "One of the parameters 'Use_DefaultPassword', 'Use_SsoCustomerId' or 'Use_GeneratedPassword' must be set in the configuration. "
        }
    }

    It 'rejects an invalid meeting license key' {
        $InvalidConfiguration = [pscustomobject]@{
            Use_DefaultPassword    = $false
            Use_GeneratedPassword  = $true
            Use_SsoCustomerId      = $false
            User_MeetingLicenseKey = 'not-a-guid'
        }

        { Test-TVADCConfiguration -Configuration $InvalidConfiguration } | Should -Throw
    }

    It 'accepts a valid meeting license key' {
        $ValidConfiguration = [pscustomobject]@{
            Use_DefaultPassword    = $false
            Use_GeneratedPassword  = $true
            Use_SsoCustomerId      = $false
            User_MeetingLicenseKey = '4d00238a-9391-44cd-88ab-631194a97de5'
        }

        { Test-TVADCConfiguration -Configuration $ValidConfiguration } | Should -Not -Throw
    }

    It 'rejects null configuration content' {
        { Test-TVADCConfiguration -Configuration $null -ErrorAction Stop } | Should -Throw
    }

    It 'declares Configuration as a mandatory object parameter' {
        $Parameter = (Get-Command Test-TVADCConfiguration).Parameters['Configuration']

        $Parameter.ParameterType | Should -Be ([object])
        $Parameter.Attributes.Mandatory | Should -Contain $true
        @($Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] }).Count | Should -Be 1
    }
}
