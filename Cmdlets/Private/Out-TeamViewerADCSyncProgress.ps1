function Out-TeamViewerADCSyncProgress {
    [CmdletBinding()]

    [OutputType([void])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [scriptblock]
        $Handler,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]
        $Percent,

        [Parameter()]
        [string]
        $Operation
    )

    (& $Handler $Percent $Operation) | Out-Null
}
