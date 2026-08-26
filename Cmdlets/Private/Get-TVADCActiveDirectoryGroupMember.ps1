function Get-TVADCActiveDirectoryGroupMember {
    [CmdletBinding()]

    [OutputType([psobject[]])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AD_Root,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AD_Path,

        [Parameter(Mandatory = $false)]
        [bool]
        $Recursive = $false,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]
        $Limit = 2500
    )

    $ADS_Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher

    if ($AD_Root) {
        $ADS_Searcher.SearchRoot = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList $AD_Root
    }

    if ($Recursive) {
        $ADS_Searcher.Filter = "(&(objectClass=user)(memberOf:1.2.840.113556.1.4.1941:=$AD_Path))"
    }
    else {
        $ADS_Searcher.Filter = "(&(objectClass=user)(memberOf=$AD_Path))"
    }

    $ADS_Searcher.PropertiesToLoad.AddRange(@('name', 'mail', 'userAccountControl', 'proxyAddresses'))
    $ADS_Searcher.PageSize = 1000
    $ADS_Searcher.SizeLimit = $Limit

    $Result = $ADS_Searcher.FindAll()

    return $Result | ForEach-Object -Process {
        $SecondaryEmails = $_.Properties.proxyaddresses | Select-String -Pattern '^smtp:(.*)$' -CaseSensitive -AllMatches |
        Select-Object -ExpandProperty Matches | Where-Object -FilterScript { $_.Groups.Count -gt 0 } |
        ForEach-Object -Process { [string]($_.Groups[1].Value).Trim() }

        [pscustomobject]@{
            Email           = [string]($_.Properties.mail)
            Name            = [string]($_.Properties.name)
            IsEnabled       = [bool](($_.Properties.useraccountcontrol.Item(0) -band 2) -eq 0)
            SecondaryEmails = $SecondaryEmails
        }
    } | Where-Object -FilterScript { $_.Email -and $_.Name -and $_.IsEnabled }
}
