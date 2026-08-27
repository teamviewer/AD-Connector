---
external help file: TeamViewerADC-help.xml
Module Name: TeamViewerADC
online version:
schema: 2.0.0
---

# Set-TeamViewerADCConfiguration

## SYNOPSIS

Sets one or more TeamViewer AD Connector configuration settings.

## SYNTAX

```powershell
Set-TeamViewerADCConfiguration [[-Config_File] <String>] [-Api_Uri <String>] [-Api_Token <String>]
 [-TestRun <Boolean>] [-ActiveDirectory_Root <String>] [-ActiveDirectory_Groups <String[]>]
 [-User_Language <String>] [-User_MeetingLicenseKey <String>] [-User_DefaultPassword <SecureString>]
 [-Sso_CustomerId <String>] [-Use_DefaultPassword <Boolean>] [-Use_GeneratedPassword <Boolean>]
 [-Use_SsoCustomerId <Boolean>] [-Sync_DeactivateUsers <Boolean>] [-Sync_UseSecondaryEmails <Boolean>]
 [-Sync_IncludeUserGroups <Boolean>] [-Sync_RecursiveUserGroups <Boolean>] [-PassThru]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Updates individual settings in the JSON configuration file.
Only the settings passed as parameters are changed; all other settings are preserved.
If the configuration file does not exist, it is created with the established defaults and the requested changes.

## EXAMPLES

### Example 1

```powershell
PS C:\> Set-TeamViewerADCConfiguration -Api_Token '12345678-abcd...'
```

Sets the TeamViewer API token in the default configuration file.

### Example 2

```powershell
PS C:\> Set-TeamViewerADCConfiguration -Api_Uri 'https://webapi.teamviewer.com/api/v1' -ActiveDirectory_Groups 'CN=Sales,OU=Groups,DC=example,DC=com'
```

Sets the TeamViewer API URI and the Active Directory groups to synchronize.

## PARAMETERS

### -Config_File

Path to the JSON configuration file to change. The file is created if it does not exist.
Defaults to `Config\TeamViewerADC.json` located next to the module.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: Config\TeamViewerADC.json
Accept pipeline input: False
Accept wildcard characters: False
```

### -Api_Uri

The TeamViewer web API base URI. Leave empty to use the default (global) endpoint, or set it to a regional endpoint such as `https://webapi.teamviewer.com/api/v1`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Api_Token

The TeamViewer API access token used to access user and user group data.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TestRun

If set to `$true` the synchronization only logs the actions it would perform without modifying any TeamViewer resources.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ActiveDirectory_Root

The LDAP root path used for the Active Directory queries.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ActiveDirectory_Groups

The Active Directory user groups (LDAP identifiers without the leading `LDAP://` scheme) used for the synchronization.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -User_Language

The two-letter language identifier used as the default language for newly created TeamViewer users.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -User_MeetingLicenseKey

The meeting license key (GUID) assigned to newly created TeamViewer users. Provide an empty value to clear it.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -User_DefaultPassword

The initial password used for newly created TeamViewer users when `Use_DefaultPassword` is enabled.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sso_CustomerId

The TeamViewer Single Sign-On (SSO) customer identifier used when `Use_SsoCustomerId` is enabled.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Use_DefaultPassword

If set to `$true` TeamViewer users are created with the initial password from `User_DefaultPassword`. Mutually exclusive with `Use_SsoCustomerId` and `Use_GeneratedPassword`.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Use_GeneratedPassword

If set to `$true` TeamViewer users are created with a generated password and receive a password reset email. Mutually exclusive with `Use_DefaultPassword` and `Use_SsoCustomerId`.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Use_SsoCustomerId

If set to `$true` TeamViewer users are created with Single Sign-On (SSO) activated using `Sso_CustomerId`. Mutually exclusive with `Use_DefaultPassword` and `Use_GeneratedPassword`.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sync_DeactivateUsers

If set to `$true` TeamViewer users that are not members of the selected Active Directory groups are deactivated.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sync_UseSecondaryEmails

If set to `$true` the secondary email addresses of Active Directory users are also used when mapping to TeamViewer users.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sync_IncludeUserGroups

If set to `$true` the configured Active Directory groups and their members are synchronized with TeamViewer user groups.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sync_RecursiveUserGroups

If set to `$true` users of nested Active Directory user groups are included.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru

Returns the resulting configuration object. By default this command produces no output.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the command runs. The command is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts for confirmation before running the command.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

## RELATED LINKS
