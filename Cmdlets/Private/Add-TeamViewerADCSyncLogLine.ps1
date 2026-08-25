function Add-TeamViewerADCSyncLogLine {
    [CmdletBinding()]

    [OutputType([hashtable])]

    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [Parameter()]
        [string]
        $Extra
    )

    process {
        Write-Output -InputObject @{ Date = Get-Date; Message = $Message; Extra = $Extra } -NoEnumerate
    }
}
