---
external help file: TeamViewerADC-help.xml
Module Name: TeamViewerADC
online version:
schema: 2.0.0
---

# Get-TeamViewerADCConfiguration

## SYNOPSIS

Reads the TeamViewer AD Connector configuration from disk.

## SYNTAX

```powershell
Get-TeamViewerADCConfiguration [[-Config_File] <String>] [<CommonParameters>]
```

## DESCRIPTION

Loads the specified JSON configuration file and returns the configuration object with any missing values filled in from the established defaults.

## EXAMPLES

### Example 1

```powershell
PS C:\> Get-TeamViewerADCConfiguration
```

Returns the configuration stored in the default configuration file.

### Example 2

```powershell
PS C:\> Get-TeamViewerADCConfiguration -Config_File 'C:\ProgramData\TeamViewerADC\TeamViewerADC.json'
```

Returns the configuration stored in a specific configuration file.

## PARAMETERS

### -Config_File

Path to the JSON configuration file to read. The file must exist.
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

## RELATED LINKS
