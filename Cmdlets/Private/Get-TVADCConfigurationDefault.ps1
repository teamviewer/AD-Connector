function Get-TVADCConfigurationDefault {
    [CmdletBinding()]

    [OutputType([hashtable])]

    param()

    return @{
        Api_Uri                  = 'https://webapi.teamviewer.com/api/v1'
        Api_Token                = ''
        TestRun                  = $true
        ActiveDirectory_Root     = ''
        ActiveDirectory_Groups   = @()
        User_Language            = 'en'
        User_MeetingLicenseKey   = ''
        User_DefaultPassword     = ''
        Sso_CustomerId           = ''
        Use_DefaultPassword      = $false
        Use_GeneratedPassword    = $true
        Use_SsoCustomerId        = $false
        Sync_DeactivateUsers     = $true
        Sync_UseSecondaryEmails  = $true
        Sync_SyncUserGroups      = $false
        Sync_RecursiveUserGroups = $true
    }
}
