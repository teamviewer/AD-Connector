
function Get-TeamViewerADCScheduledInterval {
    [CmdletBinding()]

    [OutputType([TimeSpan])]

    param(
        [Parameter(ValueFromPipeline = $true)]
        [object]$Task
    )

    begin {
        $SchedTask_Interval = New-TimeSpan -Hours 24
    }

    process {
        if ($Task -and $Task.Triggers.Repetition.Interval) {
            return [Xml.XmlConvert]::ToTimeSpan($Task.Triggers.Repetition.Interval)
        }

        return $SchedTask_Interval
    }
}
