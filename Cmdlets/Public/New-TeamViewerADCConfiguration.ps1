function New-TeamViewerADCConfiguration {
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
        $Api_Uri,

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
        $Sync_IncludeUserGroups,

        [Parameter(Mandatory = $false)]
        [bool]
        $Sync_RecursiveUserGroups,

        [Parameter(Mandatory = $false)]
        [switch]
        $Force,

        [Parameter(Mandatory = $false)]
        [switch]
        $PassThru
    )

    $Config_Default = Get-TVADCConfigurationDefault
    $Config_DefaultItems = $Config_Default.Keys
    $Config_ProvidedItems = @($Config_DefaultItems | Where-Object { $PSBoundParameters.ContainsKey($_) })

    # Create a new configuration from defaults
    $Configuration = New-Object -TypeName PSObject -Property (Get-TVADCConfigurationDefault)
    $Configuration | Add-Member -NotePropertyName Filename -NotePropertyValue $Config_File

    # Apply user-provided overrides
    foreach ($Config_ProvidedItem in $Config_ProvidedItems) {
        $Configuration.$Config_ProvidedItem = $PSBoundParameters[$Config_ProvidedItem]
    }

    # Validate the configuration (throws on error)
    try {
        Test-TVADCConfiguration -Configuration $Configuration -ErrorAction Stop
    }
    catch {
        Write-Error -Message $_.Exception.Message -ErrorAction Stop
        return
    }

    # Check if file already exists
    if (Test-Path -Path $Config_File -PathType Leaf) {
        if ($Force) {
            Write-Verbose -Message "Configuration file '$Config_File' already exists. Overwriting due to -Force flag."
        }
        else {
            Write-Error -Message "Configuration file '$Config_File' already exists. Use -Force to overwrite." -Category ResourceExists
            return
        }
    }

    if ($PSCmdlet.ShouldProcess($Config_File, "Create new configuration file from default values.")) {
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
