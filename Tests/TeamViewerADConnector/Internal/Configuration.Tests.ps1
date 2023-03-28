# Copyright (c) 2018-2023 TeamViewer Germany GmbH
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

    It 'Should throw if MeetingLicenseKey is set, but not a valid guid' -ForEach @(
        @{ MeetingLicenseKey = '1234-5678-90' }
        @{ MeetingLicenseKey = 'Core' }
    ) {
        $inputData = @{ MeetingLicenseKey = $MeetingLicenseKey; UseGeneratedPassword = $true }
        { Confirm-Configuration $inputData } | Should -Throw
    }

    It 'Should not throw if MeetingLicenseKey is empty or valid guid' -ForEach @(
        @{ MeetingLicenseKey = '4d00238a-9391-44cd-88ab-631194a97de5'}
        @{ MeetingLicenseKey = '{3D4E067E-68DB-4E18-BAF6-146780DBA174}'}
        @{ MeetingLicenseKey = ''}
    ) {
        $inputData = @{ MeetingLicenseKey = $MeetingLicenseKey; UseGeneratedPassword = $true }
        { Confirm-Configuration $inputData } | Should -Not -Throw
    }
}
