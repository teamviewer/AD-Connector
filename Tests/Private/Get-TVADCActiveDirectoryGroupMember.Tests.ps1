BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCActiveDirectoryGroupMember.ps1"
}

Describe 'Get-TVADCActiveDirectoryGroupMember' {
    It 'declares correct output type' {
        $CommandInfo = Get-Command -Name Get-TVADCActiveDirectoryGroupMember

        $CommandInfo.OutputType.Type | Should -Contain ([psobject[]])
    }

    It 'requires mandatory AD_Root parameter' {
        $CommandInfo = Get-Command -Name Get-TVADCActiveDirectoryGroupMember

        $AD_RootParameter = $CommandInfo.Parameters['AD_Root']

        $AD_RootParameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory
        } | Should -Not -BeNullOrEmpty
    }

    It 'requires mandatory AD_Path parameter' {
        $CommandInfo = Get-Command -Name Get-TVADCActiveDirectoryGroupMember

        $AD_PathParameter = $CommandInfo.Parameters['AD_Path']

        $AD_PathParameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory
        } | Should -Not -BeNullOrEmpty
    }

    It 'has optional Recursive parameter with correct type' {
        $CommandInfo = Get-Command -Name Get-TVADCActiveDirectoryGroupMember

        $RecursiveParameter = $CommandInfo.Parameters['Recursive']

        $RecursiveParameter | Should -Not -BeNullOrEmpty
        $RecursiveParameter.ParameterType | Should -Be ([bool])
    }

    It 'has optional Limit parameter with a non-negative range' {
        $CommandInfo = Get-Command -Name Get-TVADCActiveDirectoryGroupMember

        $LimitParameter = $CommandInfo.Parameters['Limit']

        $LimitParameter | Should -Not -BeNullOrEmpty
        $LimitParameter.ParameterType | Should -Be ([int])
        $LimitParameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ValidateRangeAttribute]
        } | Should -Not -BeNullOrEmpty
    }

    It 'validates AD_Root is not null' {
        $CommandInfo = Get-Command -Name Get-TVADCActiveDirectoryGroupMember

        $AD_RootParameter = $CommandInfo.Parameters['AD_Root']

        $AD_RootParameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute]
        } | Should -Not -BeNullOrEmpty
    }

    It 'validates AD_Path is not null' {
        $CommandInfo = Get-Command -Name Get-TVADCActiveDirectoryGroupMember

        $AD_PathParameter = $CommandInfo.Parameters['AD_Path']

        $AD_PathParameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute]
        } | Should -Not -BeNullOrEmpty
    }

    It 'rejects null AD_Root with validation error' {
        { Get-TVADCActiveDirectoryGroupMember -AD_Root $null -AD_Path 'CN=Group,OU=Groups,DC=example,DC=com' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects null AD_Path with validation error' {
        { Get-TVADCActiveDirectoryGroupMember -AD_Root 'LDAP://DC=example,DC=com' -AD_Path $null -ErrorAction Stop } | Should -Throw
    }

    It 'has [CmdletBinding()] attribute' {
        $CommandInfo = Get-Command -Name Get-TVADCActiveDirectoryGroupMember

        $CommandInfo.CmdletBinding | Should -Be $true
    }

    It 'configures the searcher and maps enabled members' {
        $MockDirectoryEntry = [pscustomobject]@{ DistinguishedName = 'LDAP://DC=example,DC=com' }
        $MockPropertiesToLoad = New-Object System.Collections.Specialized.StringCollection
        $MockDirectorySearcher = [pscustomobject]@{
            SearchRoot       = $null
            Filter           = $null
            PropertiesToLoad = $MockPropertiesToLoad
            PageSize         = 0
            SizeLimit        = 0
        }

        $MockDirectorySearcher | Add-Member -MemberType ScriptMethod -Name FindAll -Value {
            return @(
                [pscustomobject]@{
                    Properties = [pscustomobject]@{
                        userPrincipalName  = @('alice@contoso.com')
                        name               = @('Alice Example')
                        mail               = @('alice@example.com')
                        userAccountControl = @(0)
                        proxyAddresses     = @('SMTP:alice@example.com', 'smtp:alice.alias@example.com', 'smtp:alice.alias@example.com', 'x500:legacy')
                    }
                }
            )
        }

        Mock New-Object -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectorySearcher' } -MockWith { $MockDirectorySearcher }
        Mock New-Object -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectoryEntry' } -MockWith { $MockDirectoryEntry }

        $Result = Get-TVADCActiveDirectoryGroupMember -AD_Root 'LDAP://DC=example,DC=com' -AD_Path 'CN=Group,DC=example,DC=com' -Limit 50

        $MockDirectorySearcher.SearchRoot | Should -Be $MockDirectoryEntry
        $MockDirectorySearcher.Filter | Should -Be '(&(objectClass=user)(memberOf=CN=Group,DC=example,DC=com))'
        $MockDirectorySearcher.PropertiesToLoad | Should -Contain 'userPrincipalName'
        $MockDirectorySearcher.PropertiesToLoad | Should -Contain 'name'
        $MockDirectorySearcher.PropertiesToLoad | Should -Contain 'mail'
        $MockDirectorySearcher.PropertiesToLoad | Should -Contain 'userAccountControl'
        $MockDirectorySearcher.PropertiesToLoad | Should -Contain 'proxyAddresses'
        $MockDirectorySearcher.PageSize | Should -Be 1000
        $MockDirectorySearcher.SizeLimit | Should -Be 50

        $Result | Should -HaveCount 1
        $Result[0].Email | Should -Be 'alice@contoso.com'
        $Result[0].Name | Should -Be 'Alice Example'
        $Result[0].IsEnabled | Should -BeTrue
        $Result[0].SecondaryEmails | Should -Be @('alice@example.com', 'alice.alias@example.com')
    }

    It 'uses the recursive membership filter when requested' {
        $MockDirectoryEntry = [pscustomobject]@{ DistinguishedName = 'LDAP://DC=example,DC=com' }
        $MockDirectorySearcher = [pscustomobject]@{
            SearchRoot       = $null
            Filter           = $null
            PropertiesToLoad = New-Object System.Collections.Specialized.StringCollection
            PageSize         = 0
            SizeLimit        = 0
        }
        $MockDirectorySearcher | Add-Member -MemberType ScriptMethod -Name FindAll -Value { return @() }

        Mock New-Object -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectorySearcher' } -MockWith { $MockDirectorySearcher }
        Mock New-Object -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectoryEntry' } -MockWith { $MockDirectoryEntry }

        Get-TVADCActiveDirectoryGroupMember -AD_Root 'LDAP://DC=example,DC=com' -AD_Path 'CN=Group,DC=example,DC=com' -Recursive $true

        $MockDirectorySearcher.Filter | Should -Be '(&(objectClass=user)(memberOf:1.2.840.113556.1.4.1941:=CN=Group,DC=example,DC=com))'
    }

    It 'excludes disabled and users without a valid external email address' {
        $MockDirectoryEntry = [pscustomobject]@{ DistinguishedName = 'LDAP://DC=example,DC=com' }
        $MockDirectorySearcher = [pscustomobject]@{
            SearchRoot       = $null
            Filter           = $null
            PropertiesToLoad = New-Object System.Collections.Specialized.StringCollection
            PageSize         = 0
            SizeLimit        = 0
        }

        $MockDirectorySearcher | Add-Member -MemberType ScriptMethod -Name FindAll -Value {
            return @(
                [pscustomobject]@{ Properties = [pscustomobject]@{ name = @('Disabled'); mail = @('disabled@example.com'); userPrincipalName = @('disabled@contoso.com'); userAccountControl = @(2); proxyAddresses = @() } }
                [pscustomobject]@{ Properties = [pscustomobject]@{ name = @('No Email'); mail = @(''); userPrincipalName = @(''); userAccountControl = @(0); proxyAddresses = @() } }
                [pscustomobject]@{ Properties = [pscustomobject]@{ name = @('Local Domain'); mail = @('local@contoso.local'); userPrincipalName = @('local@contoso.local'); userAccountControl = @(0); proxyAddresses = @('SMTP:local.alias@contoso.local') } }
                [pscustomobject]@{ Properties = [pscustomobject]@{ name = @('Invalid Email'); mail = @('not-an-email'); userPrincipalName = @('invalid@contoso'); userAccountControl = @(0); proxyAddresses = @() } }
                [pscustomobject]@{ Properties = [pscustomobject]@{ name = @('Valid'); mail = @('valid@example.com'); userPrincipalName = @(''); userAccountControl = @(0); proxyAddresses = @() } }
            )
        }

        Mock New-Object -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectorySearcher' } -MockWith { $MockDirectorySearcher }
        Mock New-Object -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectoryEntry' } -MockWith { $MockDirectoryEntry }

        $Result = Get-TVADCActiveDirectoryGroupMember -AD_Root 'LDAP://DC=example,DC=com' -AD_Path 'CN=Group,DC=example,DC=com'

        $Result | Should -HaveCount 1
        $Result[0].Name | Should -Be 'Valid'
    }
}
