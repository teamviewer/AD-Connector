function Resolve-TVADCTeamViewerAccount {
    [CmdletBinding()]

    [OutputType([psobject])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Sync_Context,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Configuration,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $AD_User
    )

    process {
        $TV_User = $Sync_Context.TeamViewerUsersByEmail[$AD_User.Email]

        if (-not $TV_User -and $Configuration.Sync_UseSecondaryEmails) {
            $TV_User = $AD_User.SecondaryEmails | ForEach-Object { $Sync_Context.TeamViewerUsersByEmail[$_] } | Select-Object -First 1
        }

        Write-Output $TV_User
    }
}
