# Copyright (c) 2018-2020 TeamViewer GmbH
# See file LICENSE

BeforeAll {
    . "$PSScriptRoot\..\..\..\TeamViewerADConnector\Internal\Configuration.ps1"
}

Describe 'Confirm-Configuration' {

    It 'Should throw if DefaultPassword and SsoCustomerId are used in conjunction' {
        $inputData = @{
            UseDefaultPassword = $true; DefaultPassword = 'Test123'
            UseSsoCustomerId = $true; SsoCustomerId = 'TestCustomer'
        }
        { Confirm-Configuration $inputData } | Should -Throw
    }

    It 'Should throw if DefaultPassword and GeneratePassword are used in conjunction' {
        $inputData = @{
            UseGeneratedPassword = $true
            UseDefaultPassword = $true; DefaultPassword = 'Test123'
        }
        { Confirm-Configuration $inputData } | Should -Throw
    }

    It 'Should throw if SsoCustomerId and GeneratePassword are used in conjunction' {
        $inputData = @{
            UseGeneratedPassword = $true
            UseSsoCustomerId = $true; SsoCustomerId = 'TestCustomer'
        }
        { Confirm-Configuration $inputData } | Should -Throw
    }

    It 'Should throw if neither DefaultPassword, GeneratePassword nor SsoCustomerId are set' {
        $inputData = @{}
        { Confirm-Configuration $inputData } | Should -Throw
    }

    It 'Should throw if DefaultPassword is configured but empty' {
        $inputData = @{ UseDefaultPassword = $true; DefaultPassword = '' }
        { Confirm-Configuration $inputData } | Should -Throw
    }

    It 'Should throw if SsoCustomerId is configured by empty' {
        $inputData = @{ UseSsoCustomerId = $true; SsoCustomerId = '' }
        { Confirm-Configuration $inputData } | Should -Throw
    }
}
