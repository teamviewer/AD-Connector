function Set-TVADCEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]

    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [psobject]$Configuration
    )

    switch ($Configuration.Environment.ToLowerInvariant()) {
        'us' {
            if ($PSCmdlet.ShouldProcess('Set to US environment.')) {
                Set-TeamViewerAPIUri -NewUri 'https://webapi.us.teamviewer.com/api/v1'
            }
        }
        default {
            if ($PSCmdlet.ShouldProcess('Set to global environment.')) {
                Set-TeamViewerAPIUri -Default $true
            }
        }
    }
}
