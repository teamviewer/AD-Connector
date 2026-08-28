---
external help file: TeamViewerADC-help.xml
Module Name: TeamViewerADC
online version:
schema: 2.0.0
---

# Convert-TeamViewerADCConfiguration

## SYNOPSIS

Converts a legacy TeamViewer AD Connector configuration to the current format.

## SYNTAX

```powershell
Convert-TeamViewerADCConfiguration [-Path] <String> [-Destination] <String> [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Reads a configuration file created by the legacy TeamViewer AD Connector script and writes a new configuration file that uses the current TeamViewerADC field names.
Any settings absent from the legacy file are filled in from the established defaults.

## EXAMPLES

### Example 1

```powershell
PS C:\> Convert-TeamViewerADCConfiguration -Path 'C:\Old\TeamViewerADConnector.json' -Destination 'C:\ProgramData\TeamViewerADC\TeamViewerADC.json'
```

Converts a legacy configuration file and writes the result in the current format.

## PARAMETERS

### -Path

Path to the legacy configuration file to convert. The file must exist.

```yaml
Type: String
Parameter Sets: (All)
Aliases: LegacyConfig_File

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Destination

Path of the configuration file to create in the current format.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru

Returns the converted configuration object. By default this command produces no output.

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
