# Copyright (c) 2018 TeamViewer GmbH
# See file LICENSE

. "$PSScriptRoot\..\..\..\TeamViewerADConnector\Internal\ActiveDirectory.ps1"

Describe 'Get-ActiveDirectoryGroup' {

    It 'Should create and call a DirectorySearcher' {
        $mockedDirectorySearcher = @{} | Add-Member -PassThru -MemberType ScriptMethod -Name "FindAll" -Value {
            return @(
                (@{} | Add-Member @{ Path = 'LDAP://TestPath3' } -PassThru),
                (@{} | Add-Member @{ Path = 'LDAP://TestPath1' } -PassThru),
                (@{} | Add-Member @{ Path = 'LDAP://TestPath2' } -PassThru)
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
                (@{} | Add-Member @{ Path = 'LDAP://server1/TestPath1' } -PassThru),
                (@{} | Add-Member @{ Path = 'LDAP://some.server2.test/TestPath2' } -PassThru),
                (@{} | Add-Member @{ Path = 'LDAP://⌘.ws/TestPath3' } -PassThru),
                (@{} | Add-Member @{ Path = 'LDAP://127.0.0.1/TestPath4' } -PassThru)
                (@{} | Add-Member @{ Path = 'LDAP://server:1234/TestPath5' } -PassThru)
                (@{} | Add-Member @{ Path = 'GC://myglobalcatalog/TestPath6' } -PassThru)
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

    function Add-TestUser($mail, $name, $uac, $proxyaddr) {
        return @{} | Add-Member -PassThru @{ Properties = @{
                mail = $mail; name = $name; useraccountcontrol = @($uac); proxyaddresses = $proxyaddr
            }
        }
    }

    It 'Should return a list of active AD users' {
        $mockedDirectorySearcher = @{
            PropertiesToLoad = (New-Object System.Collections.ArrayList)
        } | Add-Member -PassThru -MemberType ScriptMethod -Name "FindAll" -Value {
            return @(
                (Add-TestUser 'user3@example.test' 'User 3' 1)
                (Add-TestUser 'user1@example.test' 'User 1' 1)
                (Add-TestUser 'user2@example.test' 'User 2' 1)
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
                (Add-TestUser 'active@example.test' 'Active User' 1)
                (Add-TestUser 'inactive@example.test' 'Inactive User' 2)
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
                (Add-TestUser 'primary@example.test' 'Test User' 1 'smtp:secondary@example.test')
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
                (Add-TestUser 'primary@example.test' 'Test User' 1 'smtp:secondary@example.test  ')
            )
        }
        Mock New-Object { return $mockedDirectorySearcher } `
            -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectorySearcher' }
        $result = @(Get-ActiveDirectoryGroupMember $null $true 'TestPath')
        $result.Length | Should -Be 1
        $result[0].SecondaryEmails | Should -Be @('secondary@example.test')
    }
}
