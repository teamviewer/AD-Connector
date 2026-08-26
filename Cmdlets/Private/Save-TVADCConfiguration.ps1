function Save-TVADCConfiguration {
    [CmdletBinding()]

    [OutputType([void])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$Configuration
    )

    $Excluded = @('Filename')

    $Configuration | Select-Object -Property * -ExcludeProperty $Excluded | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $Configuration.Filename
}
