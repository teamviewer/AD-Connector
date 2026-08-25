function Format-TeamViewerADCSyncLog {
    [CmdletBinding()]

    [OutputType([string])]
    [OutputType([object])]

    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $InputObject
    )

    process {
        if ($null -eq $InputObject) {
            return
        }

        $Properties = $InputObject.PSObject.Properties

        if ($Properties['Message']) {
            $Date = if ($Properties['Date'] -and $null -ne $InputObject.Date) {
                '{0:yyyy-MM-dd HH:mm:ss}' -f $InputObject.Date
            }
            else {
                '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date)
            }

            return "$Date $($InputObject.Message)"
        }
        elseif ($Properties['Activity'] -and $Properties['Statistics']) {
            $Statistics = $InputObject.Statistics | Format-Table -AutoSize -HideTableHeaders | Out-String -Width 4096

            if (-not [string]::IsNullOrWhiteSpace($Statistics)) {
                $Statistics.TrimEnd()
            }

            return "Duration $($InputObject.Activity): $($InputObject.Duration)"
        }
        else {
            return $InputObject
        }
    }
}
