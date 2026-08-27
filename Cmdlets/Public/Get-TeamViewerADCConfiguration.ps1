function Get-TeamViewerADCConfiguration {
    [CmdletBinding()]

    [OutputType([psobject])]

    param(
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]
        $Config_File = (Join-Path -Path $PSScriptRoot -ChildPath 'Config\TeamViewerADC.json')
    )

    $Configuration = Import-TVADCConfiguration -Config_File $Config_File

    Write-Output $Configuration
}
