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

    $ADS_Searcher.PropertiesToLoad.AddRange(@('userPrincipalName', 'name', 'mail', 'userAccountControl', 'proxyAddresses'))
    $ADS_Searcher.PageSize = 1000
    $ADS_Searcher.SizeLimit = $Limit

    $Result = $ADS_Searcher.FindAll()

    return $Result | ForEach-Object -Process {
        $UserPrincipalName = [string]$_.Properties.userprincipalname
        $ExternalEmailCandidates = @(
            $UserPrincipalName
            [string]$_.Properties.mail
            $_.Properties.proxyaddresses | Where-Object -FilterScript { $_ -match '^(SMTP|smtp):' } |
            ForEach-Object -Process { $_ -replace '^(SMTP|smtp):', '' }
        ) | ForEach-Object -Process { $_.Trim() } |
        Where-Object -FilterScript { $_ -match '^[^@\s]+@[^@\s]+\.[^@\s]+$' -and $_ -notmatch '@[^@]+\.local$' } |
        Select-Object -Unique

        $PrimaryEmail = $ExternalEmailCandidates | Select-Object -First 1
        $IsEnabled = [bool](($_.Properties.useraccountcontrol.Item(0) -band 2) -eq 0)
        $Name = [string]$_.Properties.name

        if (-not $PrimaryEmail -or -not $Name -or -not $IsEnabled) {
            return
        }

        [pscustomobject]@{
            Email           = $PrimaryEmail
            Name            = $Name
            IsEnabled       = $true
            SecondaryEmails = @($ExternalEmailCandidates | Where-Object -FilterScript { $_ -ne $PrimaryEmail })
        }
    }
}
