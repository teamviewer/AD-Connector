function Get-TVADCActiveDirectoryGroup {
    [CmdletBinding()]

    [OutputType([string[]])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AD_Root,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]
        $Limit = 2500
    )

    $ADS_Searcher = New-Object System.DirectoryServices.DirectorySearcher

    if ($AD_Root) {
        $ADS_Searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry $AD_Root
    }

    $ADS_Searcher.Filter = '(&(objectClass=group))'
    $ADS_Searcher.SizeLimit = $Limit
    $Result = $ADS_Searcher.FindAll()

    return ($Result | Select-Object -ExpandProperty Path | Select-String '^(?:LDAP|GC)://(?:[^\s/]+/)?(.+)$' | ForEach-Object { $_.Matches.Groups[1].Value }) | Sort-Object
}
