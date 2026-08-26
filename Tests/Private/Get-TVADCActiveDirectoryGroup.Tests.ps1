BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Get-TVADCActiveDirectoryGroup.ps1"
}

Describe 'Get-TVADCActiveDirectoryGroup' {
    It 'declares correct output type' {
        $CommandInfo = Get-Command -Name Get-TVADCActiveDirectoryGroup

        $CommandInfo.OutputType.Type | Should -Contain ([string[]])
    }

    It 'requires mandatory AD_Root parameter' {
        $CommandInfo = Get-Command -Name Get-TVADCActiveDirectoryGroup
        $AD_RootParameter = $CommandInfo.Parameters['AD_Root']

        $AD_RootParameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory
        } | Should -Not -BeNullOrEmpty
    }

    It 'has a Limit parameter with default value of 2500' {
        $CommandInfo = Get-Command -Name Get-TVADCActiveDirectoryGroup
        $LimitParameter = $CommandInfo.Parameters['Limit']

        $LimitParameter | Should -Not -BeNullOrEmpty
        $LimitParameter.ParameterType | Should -Be ([int])
    }

    It 'validates AD_Root is not null' {
        $CommandInfo = Get-Command -Name Get-TVADCActiveDirectoryGroup
        $AD_RootParameter = $CommandInfo.Parameters['AD_Root']

        $AD_RootParameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute]
        } | Should -Not -BeNullOrEmpty
    }

    It 'returns an empty array when no groups are found' {
        # Create a mock DirectoryEntry
        $MockDirectoryEntry = New-Object psobject
        $MockDirectoryEntry | Add-Member -MemberType NoteProperty -Name SearchRoot -Value $null

        # Create a mock DirectorySearcher
        $MockDirectorySearcher = New-Object psobject
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name SearchRoot -Value $null
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name Filter -Value $null
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name SizeLimit -Value 0
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name PropertiesToLoad -Value (New-Object System.Collections.Specialized.StringCollection)
        $MockDirectorySearcher | Add-Member -MemberType ScriptMethod -Name FindAll -Value { return @() }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectorySearcher'
        } -MockWith { return $MockDirectorySearcher }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
        } -MockWith { return $MockDirectoryEntry }

        Mock -CommandName New-Object -MockWith {
            if ($TypeName -eq 'System.Collections.Specialized.StringCollection') {
                return New-Object System.Collections.Specialized.StringCollection
            }
            return $null
        }

        $Result = Get-TVADCActiveDirectoryGroup -AD_Root 'LDAP://DC=example,DC=com'

        $Result | Should -BeNullOrEmpty
    }

    It 'extracts LDAP paths and returns sorted group names' {
        $MockDirectoryEntry = New-Object psobject
        $MockDirectorySearcher = New-Object psobject
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name SearchRoot -Value $null
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name Filter -Value $null
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name SizeLimit -Value 0
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name PropertiesToLoad -Value (New-Object System.Collections.Specialized.StringCollection)
        $MockDirectorySearcher | Add-Member -MemberType ScriptMethod -Name FindAll -Value {
            return @(
                [pscustomobject]@{ Path = 'LDAP://CN=ZebraGroup,OU=Groups,DC=example,DC=com' }
                [pscustomobject]@{ Path = 'LDAP://dc01.example.com/CN=AlphaGroup,OU=Groups,DC=example,DC=com' }
                [pscustomobject]@{ Path = 'GC://dc01.example.com/CN=BetaGroup,OU=Groups,DC=example,DC=com' }
            )
        }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectorySearcher'
        } -MockWith { return $MockDirectorySearcher }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
        } -MockWith { return $MockDirectoryEntry }

        Mock -CommandName New-Object -MockWith {
            if ($TypeName -eq 'System.Collections.Specialized.StringCollection') {
                return New-Object System.Collections.Specialized.StringCollection
            }
            return $null
        }

        $Result = Get-TVADCActiveDirectoryGroup -AD_Root 'LDAP://DC=example,DC=com'

        $Result | Should -HaveCount 3
        $Result[0] | Should -Be 'CN=AlphaGroup,OU=Groups,DC=example,DC=com'
        $Result[1] | Should -Be 'CN=BetaGroup,OU=Groups,DC=example,DC=com'
        $Result[2] | Should -Be 'CN=ZebraGroup,OU=Groups,DC=example,DC=com'
    }

    It 'assigns AD_Root to the DirectorySearcher search root' {
        $MockDirectoryEntry = [pscustomobject]@{ DistinguishedName = 'LDAP://DC=example,DC=com' }
        $MockDirectorySearcher = [pscustomobject]@{
            SearchRoot = $null
            Filter     = $null
            SizeLimit  = 0
        }
        $MockDirectorySearcher | Add-Member -MemberType ScriptMethod -Name FindAll -Value { return @() }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectorySearcher'
        } -MockWith { return $MockDirectorySearcher }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
        } -MockWith { return $MockDirectoryEntry }

        Get-TVADCActiveDirectoryGroup -AD_Root 'LDAP://DC=example,DC=com'

        $MockDirectorySearcher.SearchRoot | Should -Be $MockDirectoryEntry
        Should -Invoke New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectoryEntry' -and
            $ArgumentList -contains 'LDAP://DC=example,DC=com'
        } -Exactly 1
    }

    It 'extracts paths from search results' {
        $MockDirectoryEntry = New-Object psobject
        $MockDirectorySearcher = New-Object psobject
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name SearchRoot -Value $null
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name Filter -Value $null
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name SizeLimit -Value 0
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name PropertiesToLoad -Value (New-Object System.Collections.Specialized.StringCollection)
        $MockDirectorySearcher | Add-Member -MemberType ScriptMethod -Name FindAll -Value {
            return @(
                [pscustomobject]@{ Path = 'LDAP://CN=GroupA,OU=Groups,DC=example,DC=com' }
                [pscustomobject]@{ Path = 'LDAP://CN=GroupB,OU=Groups,DC=example,DC=com' }
            )
        }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectorySearcher'
        } -MockWith { return $MockDirectorySearcher }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
        } -MockWith { return $MockDirectoryEntry }

        Mock -CommandName New-Object -MockWith {
            if ($TypeName -eq 'System.Collections.Specialized.StringCollection') {
                return New-Object System.Collections.Specialized.StringCollection
            }
            return $null
        }

        $Result = Get-TVADCActiveDirectoryGroup -AD_Root 'LDAP://DC=example,DC=com'

        # Should extract paths and return 2 results
        $Result | Should -HaveCount 2
    }

    It 'passes the Limit parameter to DirectorySearcher.SizeLimit' {
        $MockDirectoryEntry = New-Object psobject
        $MockDirectorySearcher = New-Object psobject
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name SearchRoot -Value $null
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name Filter -Value $null
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name SizeLimit -Value 0
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name PropertiesToLoad -Value (New-Object System.Collections.Specialized.StringCollection)
        $MockDirectorySearcher | Add-Member -MemberType ScriptMethod -Name FindAll -Value { return @() }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectorySearcher'
        } -MockWith { return $MockDirectorySearcher }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
        } -MockWith { return $MockDirectoryEntry }

        Mock -CommandName New-Object -MockWith {
            if ($TypeName -eq 'System.Collections.Specialized.StringCollection') {
                return New-Object System.Collections.Specialized.StringCollection
            }
            return $null
        }

        Get-TVADCActiveDirectoryGroup -AD_Root 'LDAP://DC=example,DC=com' -Limit 5000

        $MockDirectorySearcher.SizeLimit | Should -Be 5000
    }

    It 'uses default Limit of 2500 when not specified' {
        $MockDirectoryEntry = New-Object psobject
        $MockDirectorySearcher = New-Object psobject
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name SearchRoot -Value $null
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name Filter -Value $null
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name SizeLimit -Value 0
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name PropertiesToLoad -Value (New-Object System.Collections.Specialized.StringCollection)
        $MockDirectorySearcher | Add-Member -MemberType ScriptMethod -Name FindAll -Value { return @() }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectorySearcher'
        } -MockWith { return $MockDirectorySearcher }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
        } -MockWith { return $MockDirectoryEntry }

        Mock -CommandName New-Object -MockWith {
            if ($TypeName -eq 'System.Collections.Specialized.StringCollection') {
                return New-Object System.Collections.Specialized.StringCollection
            }
            return $null
        }

        Get-TVADCActiveDirectoryGroup -AD_Root 'LDAP://DC=example,DC=com'

        $MockDirectorySearcher.SizeLimit | Should -Be 2500
    }

    It 'sets filter to group object class query' {
        $MockDirectoryEntry = New-Object psobject
        $MockDirectorySearcher = New-Object psobject
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name SearchRoot -Value $null
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name Filter -Value $null
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name SizeLimit -Value 0
        $MockDirectorySearcher | Add-Member -MemberType NoteProperty -Name PropertiesToLoad -Value (New-Object System.Collections.Specialized.StringCollection)
        $MockDirectorySearcher | Add-Member -MemberType ScriptMethod -Name FindAll -Value { return @() }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectorySearcher'
        } -MockWith { return $MockDirectorySearcher }

        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
        } -MockWith { return $MockDirectoryEntry }

        Mock -CommandName New-Object -MockWith {
            if ($TypeName -eq 'System.Collections.Specialized.StringCollection') {
                return New-Object System.Collections.Specialized.StringCollection
            }
            return $null
        }

        Get-TVADCActiveDirectoryGroup -AD_Root 'LDAP://DC=example,DC=com'

        $MockDirectorySearcher.Filter | Should -Be '(&(objectClass=group))'
    }

    It 'rejects a negative Limit' {
        { Get-TVADCActiveDirectoryGroup -AD_Root 'LDAP://DC=example,DC=com' -Limit -1 -ErrorAction Stop } | Should -Throw
    }
}
