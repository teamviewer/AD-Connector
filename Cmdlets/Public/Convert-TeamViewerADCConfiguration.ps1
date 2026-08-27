function Convert-TeamViewerADCConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true)]

    [OutputType([psobject])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Destination,

        [Parameter(Mandatory = $false)]
        [switch]
        $PassThru
    )

    # Maps legacy TeamViewerADConnector field names to the current TeamViewerADC configuration fields.
    $Configuration_FieldMap = [ordered]@{
        ApiToken              = 'Api_Token'
        ActiveDirectoryRoot   = 'ActiveDirectory_Root'
        ActiveDirectoryGroups = 'ActiveDirectory_Groups'
        UserLanguage          = 'User_Language'
        UseDefaultPassword    = 'Use_DefaultPassword'
        DefaultPassword       = 'User_DefaultPassword'
        UseSsoCustomerId      = 'Use_SsoCustomerId'
        UseGeneratedPassword  = 'Use_GeneratedPassword'
        SsoCustomerId         = 'Sso_CustomerId'
        TestRun               = 'TestRun'
        DeactivateUsers       = 'Sync_DeactivateUsers'
        RecursiveGroups       = 'Sync_RecursiveUserGroups'
        UseSecondaryEmails    = 'Sync_UseSecondaryEmails'
        EnableUserGroupsSync  = 'Sync_SyncUserGroups'
        MeetingLicenseKey     = 'User_MeetingLicenseKey'
    }

    $Configuration_Legacy = Get-Content -Path $Path | Out-String | ConvertFrom-Json

    $Configuration = New-Object -TypeName PSObject -Property (Get-TVADCConfigurationDefault)

    foreach ($LegacyName in $Configuration_FieldMap.Keys) {
        if ($Configuration_Legacy.PSObject.Properties[$LegacyName]) {
            $Configuration.($Configuration_FieldMap[$LegacyName]) = $Configuration_Legacy.$LegacyName
        }
    }

    # The legacy 'Environment' switch is translated into a concrete API URI.
    if ($Configuration_Legacy.PSObject.Properties['Environment'] -and "$($Configuration_Legacy.Environment)".ToLowerInvariant() -eq 'us') {
        $Configuration.Api_Uri = 'https://webapi.teamviewer.com/api/v1'
    }

    $Configuration | Add-Member -NotePropertyName Filename -NotePropertyValue $Destination

    if ($PSCmdlet.ShouldProcess($Destination, "Convert legacy configuration from '$Path'.")) {
        $Parent = Split-Path -Path $Destination -Parent

        if ($Parent -and -not (Test-Path -Path $Parent)) {
            New-Item -Path $Parent -ItemType Directory -Force | Out-Null
        }

        Save-TVADCConfiguration -Configuration $Configuration
    }

    if ($PassThru) {
        Write-Output $Configuration
    }
}
