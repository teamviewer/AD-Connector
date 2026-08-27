function Import-TVADCConfiguration {
    [CmdletBinding()]

    [OutputType([psobject])]

    param(
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]
        $Config_File = (Join-Path -Path $PSScriptRoot -ChildPath 'Config\TeamViewerADC.json')
    )

    $Configuration_Default = @{
        Environment              = 'global'
        Api_Token                = ''
        TestRun                  = $true
        ActiveDirectory_Root     = ''
        ActiveDirectory_Groups   = @()
        User_Language            = 'en'
        User_MeetingLicenseKey   = ''
        User_DefaultPassword     = ''
        Sso_CustomerId           = ''
        Use_DefaultPassword      = $true
        Use_GeneratedPassword    = $false
        Use_SsoCustomerId        = $false
        Sync_DeactivateUsers     = $true
        Sync_UseSecondaryEmails  = $true
        Sync_IncludeUserGroups   = $false
        Sync_RecursiveUserGroups = $true
    }

    if (Test-Path -Path $Config_File -PathType Leaf) {
        $Configuration = Get-Content -Path $Config_File | Out-String | ConvertFrom-Json

        $Configuration_Default.Keys | Where-Object { !$Configuration.PSObject.Properties[$_] } | ForEach-Object { $Configuration | Add-Member $_ $Configuration_Default[$_] }
    }
    else {
        $Configuration = New-Object PSObject -Prop $Configuration_Default
    }

    $Configuration | Add-Member Filename $Config_File

    return $Configuration
}
