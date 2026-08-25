function Save-TeamViewerADCConfiguration {
    [CmdletBinding()]

    [OutputType([void])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$Config_Content
    )

    $Excluded = @('Filename')

    $Config_Content | Select-Object -Property * -ExcludeProperty $Excluded | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $Config_Content.Filename
}
