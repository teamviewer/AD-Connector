# Copyright (c) 2018-2023 TeamViewer Germany GmbH
# See file LICENSE

function Get-ActiveDirectoryGroup($root) {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher

    if ($root) {
        $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry $root
    }

    $searcher.Filter = '(&(objectClass=group))'
    $searcher.SizeLimit = 2500
    $result = $searcher.FindAll()

    return ($result | Select-Object -ExpandProperty Path | Select-String '^(?:LDAP|GC):\/\/(?:[^\s\/]+\/)?(.+)$' | ForEach-Object { $_.Matches.Groups[1].Value }) | Sort-Object
}

function Get-ActiveDirectoryGroupMember($root, $recursive, $path) {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher

    if ($root) {
        $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry $root
    }

    if ($recursive) {
        $searcher.Filter = "(&(objectClass=user)(memberOf:1.2.840.113556.1.4.1941:=$path))"
    }
    else {
        $searcher.Filter = "(&(objectClass=user)(memberOf=$path))"
    }

    $searcher.PropertiesToLoad.AddRange(@('name', 'mail', 'userAccountControl', 'proxyAddresses'))
    $searcher.PageSize = 1000
    $searcher.SizeLimit = 10000

    return $searcher.FindAll() | ForEach-Object { @{
            Email           = [string]($_.Properties.mail)
            Name            = [string]($_.Properties.name)
            IsEnabled       = [bool](($_.Properties.useraccountcontrol.Item(0) -BAND 2) -eq 0)
            SecondaryEmails = $_.Properties.proxyaddresses | Select-String -Pattern '^smtp:(.*)$' -CaseSensitive -AllMatches | Select-Object -ExpandProperty Matches | `
                Where-Object { $_.Groups.Count -gt 0 } | ForEach-Object { [string]($_.Groups[1].Value).Trim() }
        } } | Where-Object { $_.Email -And $_.Name -And $_.IsEnabled }
}

function Select-ActiveDirectoryCommonName {
    param([Parameter(ValueFromPipeline)] $path)
    # Simplified version of a common-name parser.
    # The following characters need to be escaped:
    #  , + " \ < > ; \r \n = /
    # See https://msdn.microsoft.com/en-us/windows/desktop/aa366101
    # See https://www.ietf.org/rfc/rfc2253.txt

    Process {
        if ($path -match 'CN=((?:[^,+"\\<>;\r\n=/]|(?:\\[,+"\\<>;\r\n=/]))+)') {
            return $Matches.1 -replace '\\([,+"\\<>;\r\n=/])', '$1'
        }
    }
}
