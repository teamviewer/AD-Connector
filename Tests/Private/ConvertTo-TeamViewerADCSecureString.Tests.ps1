BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\ConvertTo-TeamViewerADCSecureString.ps1"
}

Describe 'ConvertTo-TeamViewerADCSecureString' {
    It 'returns a read-only secure string with the supplied value' {
        $SecureString = ConvertTo-TeamViewerADCSecureString -Value 'test-value'

        $SecureString | Should -BeOfType [securestring]
        $SecureString.Length | Should -Be 10
        $SecureString.IsReadOnly() | Should -BeTrue

        $Bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        try {
            [Runtime.InteropServices.Marshal]::PtrToStringBSTR($Bstr) | Should -Be 'test-value'
        }
        finally {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Bstr)
        }
    }
}
