BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Select-TeamViewerADCActiveDirectoryCommonName.ps1"
}

Describe 'Select-TeamViewerADCActiveDirectoryCommonName' {
    It 'declares correct output type' {
        $CommandInfo = Get-Command -Name Select-TeamViewerADCActiveDirectoryCommonName

        $CommandInfo.OutputType.Type | Should -Contain ([string])
        $CommandInfo.CmdletBinding | Should -BeTrue
    }

    It 'accepts pipeline input' {
        $CommandInfo = Get-Command -Name Select-TeamViewerADCActiveDirectoryCommonName
        $AD_PathParameter = $CommandInfo.Parameters['AD_Path']

        $AD_PathParameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ValueFromPipeline
        } | Should -Not -BeNullOrEmpty
    }

    It 'validates AD_Path is not null or empty' {
        $CommandInfo = Get-Command -Name Select-TeamViewerADCActiveDirectoryCommonName
        $AD_PathParameter = $CommandInfo.Parameters['AD_Path']

        $AD_PathParameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute]
        } | Should -Not -BeNullOrEmpty
    }

    It 'extracts CN from simple LDAP distinguished name' {
        $DN = 'CN=Jeff Smith,OU=Sales,DC=Fabrikam,DC=COM'

        $Result = $DN | Select-TeamViewerADCActiveDirectoryCommonName

        $Result | Should -Be 'Jeff Smith'
    }

    It 'extracts CN from DN with multiple CN components' {
        $DN = 'CN=Karen Berge,CN=admin,DC=corp,DC=Fabrikam,DC=COM'

        $Result = $DN | Select-TeamViewerADCActiveDirectoryCommonName

        $Result | Should -Be 'Karen Berge'
    }

    It 'handles escaped comma in CN' {
        $DN = 'CN=Doe\, John,OU=Users,DC=Fabrikam,DC=COM'

        $Result = $DN | Select-TeamViewerADCActiveDirectoryCommonName

        $Result | Should -Be 'Doe, John'
    }

    It 'handles escaped quote in CN' {
        $DN = 'CN=Smith\"s Group,OU=Groups,DC=Fabrikam,DC=COM'

        $Result = $DN | Select-TeamViewerADCActiveDirectoryCommonName

        $Result | Should -Be 'Smith"s Group'
    }

    It 'handles escaped backslash in CN' {
        $DN = 'CN=Network\\Share,OU=Resources,DC=Fabrikam,DC=COM'

        $Result = $DN | Select-TeamViewerADCActiveDirectoryCommonName

        $Result | Should -Be 'Network\Share'
    }

    It 'handles escaped plus sign in CN' {
        $DN = 'CN=Test\+Group,OU=Groups,DC=Fabrikam,DC=COM'

        $Result = $DN | Select-TeamViewerADCActiveDirectoryCommonName

        $Result | Should -Be 'Test+Group'
    }

    It 'unescapes all remaining supported LDAP delimiters' {
        $DN = 'CN=Semi\; Slash\/ Less\<More\>,OU=Groups,DC=Fabrikam,DC=COM'

        $Result = $DN | Select-TeamViewerADCActiveDirectoryCommonName

        $Result | Should -Be 'Semi; Slash/ Less<More>'
    }

    It 'handles escaped equals sign in CN' {
        $DN = 'CN=Key\=Value,OU=Config,DC=Fabrikam,DC=COM'

        $Result = $DN | Select-TeamViewerADCActiveDirectoryCommonName

        $Result | Should -Be 'Key=Value'
    }

    It 'returns $null when no CN pattern found' {
        $DN = 'OU=Users,DC=Fabrikam,DC=COM'

        $Result = $DN | Select-TeamViewerADCActiveDirectoryCommonName

        $Result | Should -BeNullOrEmpty
    }

    It 'returns $null for invalid DN string' {
        $DN = 'Invalid DN String'

        $Result = $DN | Select-TeamViewerADCActiveDirectoryCommonName

        $Result | Should -BeNullOrEmpty
    }

    It 'accepts named parameter input' {
        $DN = 'CN=Test User,OU=Users,DC=example,DC=COM'

        $Result = Select-TeamViewerADCActiveDirectoryCommonName -AD_Path $DN

        $Result | Should -Be 'Test User'
    }

    It 'extracts CN when it is the final distinguished-name component' {
        $DN = 'CN=Terminal User'

        $Result = Select-TeamViewerADCActiveDirectoryCommonName -AD_Path $DN

        $Result | Should -Be 'Terminal User'
    }

    It 'processes multiple pipeline inputs' {
        $DNs = @(
            'CN=User One,OU=Users,DC=example,DC=COM'
            'CN=User Two,OU=Users,DC=example,DC=COM'
            'CN=User Three,OU=Users,DC=example,DC=COM'
        )

        $Results = $DNs | Select-TeamViewerADCActiveDirectoryCommonName

        $Results | Should -HaveCount 3
        $Results[0] | Should -Be 'User One'
        $Results[1] | Should -Be 'User Two'
        $Results[2] | Should -Be 'User Three'
    }

    It 'rejects null input with validation error' {
        { Select-TeamViewerADCActiveDirectoryCommonName -AD_Path $null -ErrorAction Stop } | Should -Throw
    }

    It 'rejects empty string with validation error' {
        { Select-TeamViewerADCActiveDirectoryCommonName -AD_Path '' -ErrorAction Stop } | Should -Throw
    }

    It 'extracts CN from GC (Global Catalog) path' {
        $Path = 'GC://server.example.com/CN=Test Group,OU=Groups,DC=example,DC=COM'

        $Result = $Path | Select-TeamViewerADCActiveDirectoryCommonName

        $Result | Should -Be 'Test Group'
    }

    It 'handles CN with escaped angle brackets' {
        $DN = 'CN=\<Special\>,OU=Users,DC=Fabrikam,DC=COM'

        $Result = $DN | Select-TeamViewerADCActiveDirectoryCommonName

        $Result | Should -Be '<Special>'
    }

    It 'extracts CN without modifying valid unescaped characters' {
        $DN = "CN=John-Paul O'Brien III,OU=Users,DC=Fabrikam,DC=COM"

        $Result = $DN | Select-TeamViewerADCActiveDirectoryCommonName

        $Result | Should -Be "John-Paul O'Brien III"
    }
}
