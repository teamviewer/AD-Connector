---
external help file: TeamViewerADC-help.xml
Module Name: TeamViewerADC
online version:
schema: 2.0.0
---

# New-TeamViewerADCConfiguration

## SYNOPSIS

Creates a new TeamViewer AD Connector configuration file with default values.

## SYNTAX

```powershell
New-TeamViewerADCConfiguration [[-Config_File] <String>] [-Api_Uri <String>] [-Api_Token <String>]
 [-TestRun <Boolean>] [-ActiveDirectory_Root <String>] [-ActiveDirectory_Groups <String[]>]
 [-User_Language <String>] [-User_MeetingLicenseKey <String>] [-User_DefaultPassword <SecureString>]
 [-Sso_CustomerId <String>] [-Use_DefaultPassword <Boolean>] [-Use_GeneratedPassword <Boolean>]
 [-Use_SsoCustomerId <Boolean>] [-Sync_DeactivateUsers <Boolean>] [-Sync_UseSecondaryEmails <Boolean>]
 [-Sync_IncludeUserGroups <Boolean>] [-Sync_RecursiveUserGroups <Boolean>] [-Force] [-PassThru]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Creates a new JSON configuration file for TeamViewerADC with all default values. User-provided parameter values override the defaults. The configuration is validated before being written to disk. Parent directories are created automatically if they do not exist.

If the configuration file already exists, an error is raised unless the `-Force` flag is used.

## EXAMPLES

### Example 1: Create a configuration with defaults

```powershell
PS C:\> New-TeamViewerADCConfiguration
```

Creates a new configuration file at the default location (`Config\TeamViewerADC.json`) with all default values.

### Example 2: Create a configuration with custom values

```powershell
PS C:\> New-TeamViewerADCConfiguration -Api_Token "abc123xyz" -ActiveDirectory_Root "DC=contoso,DC=com" -PassThru
```

Creates a new configuration at the default location with a custom API token and Active Directory root. Returns the configuration object.

### Example 3: Create a configuration at a custom location

```powershell
PS C:\> New-TeamViewerADCConfiguration -Config_File "C:\ProgramData\TeamViewerADC\TeamViewerADC.json" -Force
```

Creates a new configuration at a custom location, overwriting if the file already exists.

### Example 4: Create a configuration with WhatIf

```powershell
PS C:\> New-TeamViewerADCConfiguration -Config_File "C:\Config\TeamViewerADC.json" -WhatIf
```

Shows what would happen if the configuration file were created without actually creating it.

## PARAMETERS

### -Config_File

Path to the JSON configuration file to create. Defaults to `Config\TeamViewerADC.json` located next to the module.
Parent directories are created automatically if they do not exist.

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

The TeamViewer API URI. Must be a valid absolute URI or empty string. Defaults to `https://webapi.teamviewer.com/api/v1`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: https://webapi.teamviewer.com/api/v1
Accept pipeline input: False
Accept wildcard characters: False
```

### -Api_Token

The TeamViewer API token for authentication. Leave empty to set later.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (empty)
Accept pipeline input: False
Accept wildcard characters: False
```

### -TestRun

If `$true`, the synchronization runs in test mode without making actual changes. Defaults to `$true`.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -ActiveDirectory_Root

The distinguished name (DN) of the Active Directory root to synchronize from. For example, `DC=contoso,DC=com`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (empty)
Accept pipeline input: False
Accept wildcard characters: False
```

### -ActiveDirectory_Groups

An array of Active Directory group names or distinguished names to synchronize.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -User_Language

The language code for user interface and localization. Defaults to `en`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: en
Accept pipeline input: False
Accept wildcard characters: False
```

### -User_MeetingLicenseKey

The Meeting license key (must be a valid GUID if provided).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (empty)
Accept pipeline input: False
Accept wildcard characters: False
```

### -User_DefaultPassword

A SecureString containing the default password for new users. Required if `-Use_DefaultPassword` is `$true`.

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

The SSO customer ID for Single Sign-On. Required if `-Use_SsoCustomerId` is `$true`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (empty)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Use_DefaultPassword

If `$true`, use a default password for new users. Requires `-User_DefaultPassword`.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Use_GeneratedPassword

If `$true`, generate a password for new users. Defaults to `$true`.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Use_SsoCustomerId

If `$true`, use SSO for authentication. Requires `-Sso_CustomerId`.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sync_DeactivateUsers

If `$true`, deactivate users in TeamViewer that are no longer in Active Directory. Defaults to `$true`.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sync_UseSecondaryEmails

If `$true`, use secondary email addresses from Active Directory. Defaults to `$true`.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sync_IncludeUserGroups

If `$true`, synchronize user groups to TeamViewer. Defaults to `$false`.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sync_RecursiveUserGroups

If `$true`, recursively synchronize nested user groups. Defaults to `$true`.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

Overwrite the configuration file if it already exists. By default, an error is raised if the file exists.

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

### -PassThru

Returns the configuration object after creation. By default, no output is produced.

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

Shows what would happen if the cmdlet runs. The cmdlet is not run.

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

Prompts you for confirmation before running the cmdlet.

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

Returns the created configuration object if `-PassThru` is specified.

## NOTES

The configuration is validated before being written to disk. If validation fails, the file is not created and errors are displayed.

Exactly one password method must be selected:

- `-Use_DefaultPassword`
- `-Use_GeneratedPassword`
- `-Use_SsoCustomerId`

## RELATED LINKS

[Get-TeamViewerADCConfiguration](Get-TeamViewerADCConfiguration.md)
[Set-TeamViewerADCConfiguration](Set-TeamViewerADCConfiguration.md)
[Convert-TeamViewerADCConfiguration](Convert-TeamViewerADCConfiguration.md)
