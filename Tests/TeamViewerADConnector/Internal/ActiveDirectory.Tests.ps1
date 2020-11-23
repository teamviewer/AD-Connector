# Copyright (c) 2018-2020 TeamViewer Germany GmbH
# See file LICENSE

BeforeAll {
    . "$PSScriptRoot\..\..\..\TeamViewerADConnector\Internal\ActiveDirectory.ps1"
}

Describe 'Get-ActiveDirectoryGroup' {

    It 'Should create and call a DirectorySearcher' {
        $mockedDirectorySearcher = @{} | Add-Member -PassThru -MemberType ScriptMethod -Name "FindAll" -Value {
            return @(
                ([pscustomobject]@{} | Add-Member @{ Path = 'LDAP://TestPath3' } -PassThru),
                ([pscustomobject]@{} | Add-Member @{ Path = 'LDAP://TestPath1' } -PassThru),
                ([pscustomobject]@{} | Add-Member @{ Path = 'LDAP://TestPath2' } -PassThru)
            )
        }
        Mock New-Object { return $mockedDirectorySearcher } `
            -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectorySearcher' }
        Get-ActiveDirectoryGroup | Should -Be @( 'TestPath1', 'TestPath2', 'TestPath3' ) # Sorted
        Assert-MockCalled New-Object -Times 1 `
            -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectorySearcher' }
    }

    It 'Should set the optional search root' {
        $mockedDirectorySearcher = @{} | Add-Member -PassThru -MemberType ScriptMethod -Name "FindAll" -Value {
            return @()
        }
        Mock New-Object { return $mockedDirectorySearcher } `
            -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectorySearcher' }
        Mock New-Object { return 'Test123' } `
            -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectoryEntry' }
        Get-ActiveDirectoryGroup 'TestRoot'
        Assert-MockCalled New-Object -Times 1 -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectoryEntry' -And
            $ArgumentList -eq @('TestRoot')
        }
        $mockedDirectorySearcher.SearchRoot | Should -Be 'Test123'
    }

    It 'Should handle servernames in the LDAP path' {
        $mockedDirectorySearcher = @{} | Add-Member -PassThru -MemberType ScriptMethod -Name "FindAll" -Value {
            return @(
                ([pscustomobject]@{} | Add-Member @{ Path = 'LDAP://server1/TestPath1' } -PassThru),
                ([pscustomobject]@{} | Add-Member @{ Path = 'LDAP://some.server2.test/TestPath2' } -PassThru),
                ([pscustomobject]@{} | Add-Member @{ Path = 'LDAP://⌘.ws/TestPath3' } -PassThru),
                ([pscustomobject]@{} | Add-Member @{ Path = 'LDAP://127.0.0.1/TestPath4' } -PassThru)
                ([pscustomobject]@{} | Add-Member @{ Path = 'LDAP://server:1234/TestPath5' } -PassThru)
                ([pscustomobject]@{} | Add-Member @{ Path = 'GC://myglobalcatalog/TestPath6' } -PassThru)
            )
        }
        Mock New-Object { return $mockedDirectorySearcher } `
            -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectorySearcher' }
        Get-ActiveDirectoryGroup | Should -Be @( 'TestPath1', 'TestPath2', 'TestPath3', 'TestPath4', 'TestPath5', 'TestPath6' ) # Sorted
        Assert-MockCalled New-Object -Times 1 `
            -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectorySearcher' }
    }
}

Describe 'Get-ActiveDirectoryGroupMember' {
    BeforeAll {
        function Add-TestUser($mail, $name, $uac, $proxyaddr) {
            return @{} | Add-Member -PassThru @{ Properties = @{
                    mail = $mail; name = $name; useraccountcontrol = @($uac); proxyaddresses = $proxyaddr
                }
            }
        }
    }

    It 'Should return a list of active AD users' {
        $mockedDirectorySearcher = @{
            PropertiesToLoad = (New-Object System.Collections.ArrayList)
        } | Add-Member -PassThru -MemberType ScriptMethod -Name "FindAll" -Value {
            return @(
                (Add-TestUser -mail 'user3@example.test' -name 'User 3' -uac 1)
                (Add-TestUser -mail 'user1@example.test' -name 'User 1' -uac 1)
                (Add-TestUser -mail 'user2@example.test' -name 'User 2' -uac 1)
            )
        }
        Mock New-Object { return $mockedDirectorySearcher } `
            -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectorySearcher' }
        $result = @(Get-ActiveDirectoryGroupMember $null $true 'TestPath')
        $result.Length | Should -Be 3
        $result[0].Email | Should -Be 'user3@example.test'
        $result[0].Name | Should -Be 'User 3'
        $result[0].IsEnabled | Should -Be $true
        $result[1].Email | Should -Be 'user1@example.test'
        $result[2].Email | Should -Be 'user2@example.test'
    }

    It 'Should ignore inactive AD users' {
        $mockedDirectorySearcher = @{
            PropertiesToLoad = (New-Object System.Collections.ArrayList)
        } | Add-Member -PassThru -MemberType ScriptMethod -Name "FindAll" -Value {
            return @(
                (Add-TestUser -mail 'active@example.test' -name 'Active User' -uac 1)
                (Add-TestUser -mail 'inactive@example.test' -name 'Inactive User' -uac 2)
            )
        }
        Mock New-Object { return $mockedDirectorySearcher } `
            -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectorySearcher' }
        $result = @(Get-ActiveDirectoryGroupMember $null $true 'TestPath')
        $result.Length | Should -Be 1
        $result[0].Email | Should -Be 'active@example.test'
    }

    It 'Should parse secondary email addresses' {
        $mockedDirectorySearcher = @{
            PropertiesToLoad = (New-Object System.Collections.ArrayList)
        } | Add-Member -PassThru -MemberType ScriptMethod -Name "FindAll" -Value {
            return @(
                (Add-TestUser -mail 'primary@example.test' -name 'Test User' -uac 1 `
                    -proxyaddr 'smtp:secondary@example.test')
            )
        }
        Mock New-Object { return $mockedDirectorySearcher } `
            -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectorySearcher' }
        $result = @(Get-ActiveDirectoryGroupMember $null $true 'TestPath')
        $result.Length | Should -Be 1
        $result[0].Email | Should -Be 'primary@example.test'
        $result[0].SecondaryEmails | Should -Be @('secondary@example.test')
    }

    It 'Should ignore trailing whitespace in secondary email addresses' {
        $mockedDirectorySearcher = @{
            PropertiesToLoad = (New-Object System.Collections.ArrayList)
        } | Add-Member -PassThru -MemberType ScriptMethod -Name "FindAll" -Value {
            return @(
                (Add-TestUser -mail 'primary@example.test' -name 'Test User' -uac 1 `
                    -proxyaddr 'smtp:secondary@example.test  ')
            )
        }
        Mock New-Object { return $mockedDirectorySearcher } `
            -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectorySearcher' }
        $result = @(Get-ActiveDirectoryGroupMember $null $true 'TestPath')
        $result.Length | Should -Be 1
        $result[0].SecondaryEmails | Should -Be @('secondary@example.test')
    }
}

Describe 'Select-ActiveDirectoryCommonName' {

    It 'Should return the common name of a distinguished name' {
        # From https://msdn.microsoft.com/en-us/windows/desktop/aa366101:
        $result = 'CN=Jeff Smith,OU=Sales,DC=Fabrikam,DC=COM' | Select-ActiveDirectoryCommonName
        $result | Should -Be 'Jeff Smith'

        $result = 'CN=Karen Berge,CN=admin,DC=corp,DC=Fabrikam,DC=COM' | Select-ActiveDirectoryCommonName
        $result | Should -Be 'Karen Berge'
    }

    It 'Should handle escaped characters' -TestCases @(
        @{ TestString = 'CN=Foo\, Bar,OU=Test'; ExpectedResult = 'Foo, Bar' },
        @{ TestString = 'CN=Foo\+ Bar,OU=Test'; ExpectedResult = 'Foo+ Bar' },
        @{ TestString = 'CN=Foo\" Bar,OU=Test'; ExpectedResult = 'Foo" Bar' },
        @{ TestString = 'CN=Foo\\ Bar,OU=Test'; ExpectedResult = 'Foo\ Bar' },
        @{ TestString = 'CN=Foo\< Bar,OU=Test'; ExpectedResult = 'Foo< Bar' },
        @{ TestString = 'CN=Foo\> Bar,OU=Test'; ExpectedResult = 'Foo> Bar' },
        @{ TestString = 'CN=Foo\; Bar,OU=Test'; ExpectedResult = 'Foo; Bar' },
        @{ TestString = 'CN=Foo\= Bar,OU=Test'; ExpectedResult = 'Foo= Bar' },
        @{ TestString = 'CN=Foo\/ Bar,OU=Test'; ExpectedResult = 'Foo/ Bar' }
    ) {
        $result = $TestString | Select-ActiveDirectoryCommonName
        $result | Should -Be $ExpectedResult
    }

    It 'Should handle empty strings' {
        $result = '' | Select-ActiveDirectoryCommonName
        $result | Should -BeNull
    }

    It 'Should handle input without common name' {
        $result = 'Foo Bar Invalid String' | Select-ActiveDirectoryCommonName
        $result | Should -BeNull
    }
}
