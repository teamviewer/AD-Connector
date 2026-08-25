BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Test-TeamViewerADCConfiguration.ps1"
}

Describe 'Test-TeamViewerADCConfiguration' {
    It 'declares a void output contract' {
        $CommandInfo = Get-Command -Name Test-TeamViewerADCConfiguration

        $CommandInfo.OutputType.Type | Should -Contain ([void])
        $CommandInfo.CmdletBinding | Should -BeTrue
        $ConfigContentParameter = $CommandInfo.Parameters['Config_Content']
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

        { Test-TeamViewerADCConfiguration -Config_Content $ValidConfiguration } | Should -Not -Throw
        @(Test-TeamViewerADCConfiguration -Config_Content $ValidConfiguration) | Should -BeNullOrEmpty
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

        { Test-TeamViewerADCConfiguration -Config_Content $ValidConfiguration } | Should -Not -Throw
    }

    It 'accepts a configuration without a meeting license key' {
        $ValidConfiguration = [pscustomobject]@{
            Use_DefaultPassword    = $false
            Use_GeneratedPassword  = $true
            Use_SsoCustomerId      = $false
            User_MeetingLicenseKey = $null
        }

        { Test-TeamViewerADCConfiguration -Config_Content $ValidConfiguration } | Should -Not -Throw
    }

    It 'rejects configurations with zero or multiple account modes enabled' -ForEach @(
        @{ Use_DefaultPassword = $false; Use_GeneratedPassword = $false; Use_SsoCustomerId = $false }
        @{ Use_DefaultPassword = $true; Use_GeneratedPassword = $true; Use_SsoCustomerId = $false }
        @{ Use_DefaultPassword = $true; Use_GeneratedPassword = $false; Use_SsoCustomerId = $true }
        @{ Use_DefaultPassword = $false; Use_GeneratedPassword = $true; Use_SsoCustomerId = $true }
    ) {
        $InvalidConfiguration = [pscustomobject]$_

        { Test-TeamViewerADCConfiguration -Config_Content $InvalidConfiguration } | Should -Throw
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

        { Test-TeamViewerADCConfiguration -Config_Content $InvalidConfiguration } | Should -Throw
    }

    It 'rejects whitespace in the SSO customer identifier' {
        $InvalidConfiguration = [pscustomobject]@{
            Use_DefaultPassword   = $false
            Use_GeneratedPassword = $false
            Use_SsoCustomerId     = $true
            Sso_CustomerId        = "`t `n"
        }

        { Test-TeamViewerADCConfiguration -Config_Content $InvalidConfiguration } | Should -Throw
    }

    It 'reports the account-mode validation error' {
        $InvalidConfiguration = [pscustomobject]@{
            Use_DefaultPassword   = $false
            Use_GeneratedPassword = $false
            Use_SsoCustomerId     = $false
        }

        try {
            Test-TeamViewerADCConfiguration -Config_Content $InvalidConfiguration
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

        { Test-TeamViewerADCConfiguration -Config_Content $InvalidConfiguration } | Should -Throw
    }

    It 'accepts a valid meeting license key' {
        $ValidConfiguration = [pscustomobject]@{
            Use_DefaultPassword    = $false
            Use_GeneratedPassword  = $true
            Use_SsoCustomerId      = $false
            User_MeetingLicenseKey = '4d00238a-9391-44cd-88ab-631194a97de5'
        }

        { Test-TeamViewerADCConfiguration -Config_Content $ValidConfiguration } | Should -Not -Throw
    }

    It 'rejects null configuration content' {
        { Test-TeamViewerADCConfiguration -Config_Content $null -ErrorAction Stop } | Should -Throw
    }

    It 'declares Config_Content as a mandatory object parameter' {
        $Parameter = (Get-Command Test-TeamViewerADCConfiguration).Parameters['Config_Content']

        $Parameter.ParameterType | Should -Be ([object])
        $Parameter.Attributes.Mandatory | Should -Contain $true
        @($Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] }).Count | Should -Be 1
    }
}
