# Copyright (c) 2018 TeamViewer GmbH
# See file LICENSE

function Get-ActiveDirectoryGroupMember($root, $recursive, $path) {}
function Get-TeamViewerUser($accessToken) {}
function Add-TeamViewerUser($accessToken, $user) {}
function Edit-TeamViewerUser($accessToken, $userId, $user) {}
function Disable-TeamViewerUser($accessToken, $userId) {}
function Get-TeamViewerAccount($accessToken, [switch]$NoThrow) {}

. "$PSScriptRoot\..\..\..\TeamViewerADConnector\Internal\Sync.ps1"

Describe 'Invoke-Sync' {

    Mock Write-Synclog {}

    It 'Should get all configured AD groups' {
        Mock Get-ActiveDirectoryGroupMember {}
        $configuration = @{ ActiveDirectoryGroups = @('Group1', 'Group2', 'Group3') }
        Invoke-Sync $configuration {}
        Assert-MockCalled Get-ActiveDirectoryGroupMember -Times 1 -ParameterFilter { $path -eq 'Group1' }
        Assert-MockCalled Get-ActiveDirectoryGroupMember -Times 1 -ParameterFilter { $path -eq 'Group2' }
        Assert-MockCalled Get-ActiveDirectoryGroupMember -Times 1 -ParameterFilter { $path -eq 'Group3' }
    }

    It 'Should get all TeamViewer company members' {
        Mock Get-TeamViewerUser {}
        $configuration = @{ ApiToken = 'TestApiToken' }
        Invoke-Sync $configuration {}
        Assert-MockCalled Get-TeamViewerUser -Times 1 -ParameterFilter { $accessToken -eq 'TestApiToken' }
    }

    It 'Should create TeamViewer users from AD groups members' {
        Mock Get-ActiveDirectoryGroupMember {
            return @(
                @{ Email = 'user1@example.test'; Name = 'Test User 1'; IsEnabled = $true },
                @{ Email = 'user2@example.test'; Name = 'Test User 2'; IsEnabled = $true }
            )
        }
        Mock Get-TeamViewerUser {
            return @{
                'user1@example.test' = @{ email = 'user1@example.test'; name = 'Test User 1'; active = $true }
            }
        }
        Mock Add-TeamViewerUser {}
        $configuration = @{ ActiveDirectoryGroups = @('Group1') }
        Invoke-Sync $configuration {}
        Assert-MockCalled Add-TeamViewerUser -Times 1
        Assert-MockCalled Add-TeamViewerUser -Times 1 `
            -ParameterFilter { $user -And $user.email -eq 'user2@example.test' }
    }

    It 'Should update existing TeamViewer users from AD groups members' {
        Mock Get-ActiveDirectoryGroupMember {
            return @(@{ Email = 'user1@example.test'; Name = 'New Name'; IsEnabled = $true })
        }
        Mock Get-TeamViewerUser {
            return @{
                'user1@example.test' = @{ id = '123'; email = 'user1@example.test'; name = 'Old Name'; active = $true }
            }
        }
        Mock Edit-TeamViewerUser {}
        $configuration = @{ ActiveDirectoryGroups = @('Group1') }
        Invoke-Sync $configuration {}
        Assert-MockCalled Edit-TeamViewerUser -Times 1 `
            -ParameterFilter { $user -And $user.Name -eq 'New Name' -And $userId -eq 123 }
    }

    It 'Should deactivate unknown TeamViewer users' {
        Mock Get-ActiveDirectoryGroupMember {
            return @(@{ Email = 'user2@example.test'; Name = 'User 2'; IsEnabled = $true })
        }
        Mock Get-TeamViewerUser {
            return @{
                'user1@example.test' = @{ id = '123'; email = 'user1@example.test'; name = 'User 1'; active = $true }
                'user2@example.test' = @{ id = '456'; email = 'user2@example.test'; name = 'User 2'; active = $true }
            }
        }
        Mock Disable-TeamViewerUser {}
        $configuration = @{ ActiveDirectoryGroups = @('Group1'); DeactivateUsers = $true }
        Invoke-Sync $configuration {}
        Assert-MockCalled Disable-TeamViewerUser -Times 1 -ParameterFilter { $userId -eq 123 }
    }

    It 'Should not deactivate the token account' {
        Mock Get-ActiveDirectoryGroupMember {
            return @()
        }
        Mock Get-TeamViewerUser {
            return @{
                'user1@example.test' = @{ id = '123'; email = 'user1@example.test'; name = 'User 1'; active = $true }
            }
        }
        Mock Get-TeamViewerAccount {
            return @{ userid = '123'; email = 'user1@example.test'; name = 'User 1' }
        }
        Mock Disable-TeamViewerUser {}
        $configuration = @{ ActiveDirectoryGroups = @('Group1'); DeactivateUsers = $true }
        Invoke-Sync $configuration {}
        Assert-MockCalled Get-TeamViewerAccount -Times 1 -Scope It
        Assert-MockCalled Disable-TeamViewerUser -Times 0 -Scope It
    }

    Context 'Account Types' {
        Mock Get-ActiveDirectoryGroupMember {
            return @(
                @{ Email = 'user1@example.test'; Name = 'Test User 1'; IsEnabled = $true }
            )
        }
        Mock Get-TeamViewerUser {
            return @{}
        }
        Mock Add-TeamViewerUser {}

        It 'Should create TeamViewer users with predefined password' {
            $configuration = @{
                UseDefaultPassword    = $true
                DefaultPassword       = 'testpassword'
                ActiveDirectoryGroups = @('Group1')
            }
            Invoke-Sync $configuration {}
            Assert-MockCalled Add-TeamViewerUser -Times 1
            Assert-MockCalled Add-TeamViewerUser -Times 1 `
                -ParameterFilter { $user -And $user.password -eq 'testpassword' }
        }

        It 'Should create TeamViewer users with generated password' {
            $configuration = @{
                UseGeneratedPassword  = $true
                ActiveDirectoryGroups = @('Group1')
            }
            Invoke-Sync $configuration {}
            Assert-MockCalled Add-TeamViewerUser -Times 1
            Assert-MockCalled Add-TeamViewerUser -Times 1 `
                -ParameterFilter { $user -And $user.password -eq '' }
        }

        It 'Should create TeamViewer users that use Single Sign-On' {
            $configuration = @{
                UseSsoCustomerId      = $true
                SsoCustomerId         = 'testcustomeridentifier'
                ActiveDirectoryGroups = @('Group1')
            }
            Invoke-Sync $configuration {}
            Assert-MockCalled Add-TeamViewerUser -Times 1
            Assert-MockCalled Add-TeamViewerUser -Times 1 `
                -ParameterFilter { $user -And $user.sso_customer_id -eq 'testcustomeridentifier' }
        }
    }

    Context 'Secondary Email Addresses' {
        Mock Get-ActiveDirectoryGroupMember {
            return @(@{
                    Email           = 'user1@example.test'
                    Name            = 'User 1'
                    IsEnabled       = $true
                    SecondaryEmails = @('user1_secondary@example.test')
                })
        }
        Mock Get-TeamViewerUser {
            return @{
                'user1_secondary@example.test' = @{ id = '123'; email = 'user1_secondary@example.test'; name = 'User 1'; active = $true }
            }
        }
        Mock Add-TeamViewerUser {}
        Mock Edit-TeamViewerUser {}
        Mock Disable-TeamViewerUser {}

        It 'Should match users with secondary email address' {
            $configuration = @{
                UseSecondaryEmails    = $true
                UseGeneratedPassword  = $true
                DeactivateUsers       = $true
                ActiveDirectoryGroups = @('Group1')
            }
            Invoke-Sync $configuration {}
            # Users are the same, so no add/update/disable
            Assert-MockCalled Add-TeamViewerUser -Times 0 -Scope It
            Assert-MockCalled Edit-TeamViewerUser -Times 0 -Scope It
            Assert-MockCalled Disable-TeamViewerUser -Times 0 -Scope It
        }

        It 'Should not match users with secondary email address if not configured' {
            $configuration = @{
                UseSecondaryEmails    = $false
                UseGeneratedPassword  = $true
                DeactivateUsers       = $true
                ActiveDirectoryGroups = @('Group1')
            }
            Invoke-Sync $configuration {}
            # Would create a new user and disable the existing one
            Assert-MockCalled Add-TeamViewerUser -Times 1 -Scope It
            Assert-MockCalled Disable-TeamViewerUser -Times 1 -Scope It
        }
    }
}

Describe 'ConvertTo-SyncUpdateUserChangeset' {

    It 'Should create a hash with all changes' {
        $userTv = @{
            active = $false
            name   = 'Old Name'
        }
        $userAD = @{
            IsEnabled = $true
            Name      = 'New Name'
        }
        $changeset = (ConvertTo-SyncUpdateUserChangeset $userTv $userAD)
        $changeset | Should -BeOfType 'System.Collections.Hashtable'
        $changeset.name | Should -Be 'New Name'
        $changeset.active | Should -Be $true
    }

    It 'Should create a hash with only changed fields' {
        $userTv = @{
            active = $true
            name   = 'Old Name'
        }
        $userAD = @{
            IsEnabled = $true
            Name      = 'New Name'
        }
        $changeset = (ConvertTo-SyncUpdateUserChangeset $userTv $userAD)
        $changeset | Should -BeOfType 'System.Collections.Hashtable'
        $changeset.name | Should -Be 'New Name'
        $changeset.active | Should -BeNullOrEmpty
    }

    It 'Should create a hash that indicates user activation' {
        $userTv = @{
            active = $false
            name   = 'Name'
        }
        $userAD = @{
            IsEnabled = $true
            Name      = 'Name'
        }
        $changeset = (ConvertTo-SyncUpdateUserChangeset $userTv $userAD)
        $changeset | Should -BeOfType 'System.Collections.Hashtable'
        $changeset.name | Should -BeNullOrEmpty
        $changeset.active | Should -Be $true
    }
}