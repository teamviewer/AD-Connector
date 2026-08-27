function Set-TeamViewerADCConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true)]

    [OutputType([psobject])]

    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Config_File = (Join-Path -Path $PSScriptRoot -ChildPath 'Config\TeamViewerADC.json'),

        [Parameter(Mandatory = $false)]
        [ValidateScript({ [string]::IsNullOrWhiteSpace($_) -or [uri]::IsWellFormedUriString($_, [System.UriKind]::Absolute) })]
        [string]
        $Api_Uri ,

        [Parameter(Mandatory = $false)]
        [string]
        $Api_Token,

        [Parameter(Mandatory = $false)]
        [bool]
        $TestRun,

        [Parameter(Mandatory = $false)]
        [string]
        $ActiveDirectory_Root,

        [Parameter(Mandatory = $false)]
        [string[]]
        $ActiveDirectory_Groups,

        [Parameter(Mandatory = $false)]
        [string]
        $User_Language,

        [Parameter(Mandatory = $false)]
        [ValidateScript({ [string]::IsNullOrWhiteSpace($_) -or ($_ -as [guid]) })]
        [string]
        $User_MeetingLicenseKey,

        [Parameter(Mandatory = $false)]
        [securestring]
        $User_DefaultPassword,

        [Parameter(Mandatory = $false)]
        [string]
        $Sso_CustomerId,

        [Parameter(Mandatory = $false)]
        [bool]
        $Use_DefaultPassword,

        [Parameter(Mandatory = $false)]
        [bool]
        $Use_GeneratedPassword,

        [Parameter(Mandatory = $false)]
        [bool]
        $Use_SsoCustomerId,

        [Parameter(Mandatory = $false)]
        [bool]
        $Sync_DeactivateUsers,

        [Parameter(Mandatory = $false)]
        [bool]
        $Sync_UseSecondaryEmails,

        [Parameter(Mandatory = $false)]
        [bool]
        $Sync_SyncUserGroups,

        [Parameter(Mandatory = $false)]
        [bool]
        $Sync_RecursiveUserGroups,

        [Parameter(Mandatory = $false)]
        [switch]
        $PassThru
    )

    $Config_DefaultItems = (Get-TVADCConfigurationDefault).Keys
    $Config_ProvidedItems = @($Config_DefaultItems | Where-Object { $PSBoundParameters.ContainsKey($_) })

    if ($Config_ProvidedItems.Count -eq 0) {
        throw 'Specify at least one configuration item to change.'
    }

    if (Test-Path -Path $Config_File -PathType Leaf) {
        $Configuration = Import-TVADCConfiguration -Config_File $Config_File
    }
    else {
        $Configuration = New-Object -TypeName PSObject -Property (Get-TVADCConfigurationDefault)
        $Configuration | Add-Member -NotePropertyName Filename -NotePropertyValue $Config_File
    }

    foreach ($Config_ProvidedItem in $Config_ProvidedItems) {
        if ($Config_ProvidedItem -eq 'User_DefaultPassword') {
            $Password_Pointer = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PSBoundParameters[$Config_ProvidedItem])

            try {
                $Configuration.$Config_ProvidedItem = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($Password_Pointer)
            }
            finally {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Password_Pointer)
            }
        }
        else {
            $Configuration.$Config_ProvidedItem = $PSBoundParameters[$Config_ProvidedItem]
        }
    }

    if ($PSCmdlet.ShouldProcess($Config_File, "Set configuration setting(s): $($Config_ProvidedItems -join ', ')")) {
        $Parent = Split-Path -Path $Config_File -Parent

        if ($Parent -and -not (Test-Path -Path $Parent)) {
            New-Item -Path $Parent -ItemType Directory -Force | Out-Null
        }

        Save-TVADCConfiguration -Configuration $Configuration
    }

    if ($PassThru) {
        Write-Output $Configuration
    }
}
