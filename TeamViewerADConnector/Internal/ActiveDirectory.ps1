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

    # Ask-once runtime state (script scope)
    if (-not (Get-Variable EmailSuffixOverrideAsked -Scope Script -ErrorAction SilentlyContinue)) {
        $script:EmailSuffixOverrideAsked = $false
        $script:EmailSuffixOverride = ""
    }

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

    $searcher.PropertiesToLoad.AddRange(@(
        'name',
        'mail',
        'userPrincipalName',
        'sAMAccountName',
        'userAccountControl',
        'proxyAddresses'
    ))

    $searcher.PageSize = 1000
    $searcher.SizeLimit = 10000

    function Is-EmailLike {
        param([string]$Value)
        if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
        return ($Value.Trim() -match '^[^@\s]+@[^@\s]+\.[^@\s]+$')
    }

    function Is-LocalEmail {
        param([string]$Value)
        if (-not (Is-EmailLike $Value)) { return $false }
        return ($Value -match '@[^@]+\.local$')
    }

    function Get-SmtpProxyAddresses {
        param($ProxyAddresses)

        $out = @()
        foreach ($addr in @($ProxyAddresses)) {
            if ($addr -match '^(SMTP|smtp):(.*)$') {
                $email = $Matches[2].Trim()
                if ($email) { $out += $email }
            }
        }
        return $out
    }

    $searcher.FindAll() | ForEach-Object {

        $props = $_.Properties

        $name = [string]$props.name
        $upn  = [string]$props.userprincipalname
        $mail = [string]$props.mail
        $sam  = [string]$props.samaccountname

        $enabled = (($props.useraccountcontrol[0] -band 2) -eq 0)
        if (-not $enabled) { return }

        # ---- Collect candidate emails ----
        $candidates = @()

        if (Is-EmailLike $upn)  { $candidates += $upn }
        if (Is-EmailLike $mail) { $candidates += $mail }

        $candidates += Get-SmtpProxyAddresses $props.proxyaddresses

        $candidates = $candidates | Select-Object -Unique

        # ---- Guard rail: kill .local ----
        $external = $candidates | Where-Object { -not (Is-LocalEmail $_) }

        # ---- Primary selection ----
        $primary = $null

        if (Is-EmailLike $upn -and -not (Is-LocalEmail $upn)) {
            $primary = $upn
        }
        elseif ($external.Count -gt 0) {
            $primary = $external[0]
        }

        # ---- Optional runtime suffix override ----
        if (-not $primary) {

            if (-not $script:EmailSuffixOverrideAsked) {
                $script:EmailSuffixOverrideAsked = $true

                Write-Host ""
                Write-Host "TeamViewer AD Sync" -ForegroundColor Cyan
                Write-Host "No valid external email detected for some users." -ForegroundColor Yellow
                Write-Host "Guard rail active: *.local will never sync." -ForegroundColor Yellow
                Write-Host ""

                $suffix = Read-Host "Optional fallback: enter email suffix (example: saracenenergy.com) or press Enter to skip"
                $suffix = $suffix.Trim().TrimStart('@')

                if ($suffix) {
                    $script:EmailSuffixOverride = $suffix
                    Write-Host "Fallback enabled: <samAccountName>@$suffix" -ForegroundColor Green
                }
                else {
                    Write-Host "Fallback disabled. Users without email will be skipped." -ForegroundColor Yellow
                }
                Write-Host ""
            }

            if ($script:EmailSuffixOverride -and $sam) {
                $primary = "$sam@$($script:EmailSuffixOverride)"
            }
        }

        if (-not $primary -or -not $name) { return }

        # ---- Secondary emails (external only) ----
        $secondary = $external | Where-Object { $_ -ne $primary }

        @{
            Email           = $primary
            Name            = $name
            IsEnabled       = $true
            SecondaryEmails = $secondary
        }
    }
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
