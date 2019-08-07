# Copyright (c) 2018-2020 TeamViewer GmbH
# See file LICENSE

. "$PSScriptRoot\..\..\..\TeamViewerADConnector\Internal\Configuration.ps1"

Describe 'Confirm-Configuration' {

    It 'Should throw if DefaultPassword and SsoCustomerId are used in conjunction' {
        $input = @{
            UseDefaultPassword = $true; DefaultPassword = 'Test123'
            UseSsoCustomerId = $true; SsoCustomerId = 'TestCustomer'
        }
        { Confirm-Configuration $input } | Should -Throw
    }

    It 'Should throw if DefaultPassword and GeneratePassword are used in conjunction' {
        $input = @{
            UseGeneratedPassword = $true
            UseDefaultPassword = $true; DefaultPassword = 'Test123'
        }
        { Confirm-Configuration $input } | Should -Throw
    }

    It 'Should throw if SsoCustomerId and GeneratePassword are used in conjunction' {
        $input = @{
            UseGeneratedPassword = $true
            UseSsoCustomerId = $true; SsoCustomerId = 'TestCustomer'
        }
        { Confirm-Configuration $input } | Should -Throw
    }

    It 'Should throw if neither DefaultPassword, GeneratePassword nor SsoCustomerId are set' {
        $input = @{}
        { Confirm-Configuration $input } | Should -Throw
    }

    It 'Should throw if DefaultPassword is configured but empty' {
        $input = @{ UseDefaultPassword = $true; DefaultPassword = '' }
        { Confirm-Configuration $input } | Should -Throw
    }

    It 'Should throw if SsoCustomerId is configured by empty' {
        $input = @{ UseSsoCustomerId = $true; SsoCustomerId = '' }
        { Confirm-Configuration $input } | Should -Throw
    }
}
