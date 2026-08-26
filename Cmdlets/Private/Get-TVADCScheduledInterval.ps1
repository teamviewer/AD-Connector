
function Get-TVADCScheduledInterval {
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
            Write-Output ([Xml.XmlConvert]::ToTimeSpan($Task.Triggers.Repetition.Interval))
        }
        else {
            Write-Output $SchedTask_Interval
        }
    }
}
