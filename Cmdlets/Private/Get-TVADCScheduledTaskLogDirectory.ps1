function Get-TVADCScheduledTaskLogDirectory {
    [CmdletBinding()]

    [OutputType([string])]

    param(
        [Parameter(ValueFromPipeline = $true)]
        [object]$Task
    )

    begin {
        [string]$SchedTask_LogDirectory = (Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Logs')).FullName
    }

    process {
        if ($Task -and $Task.Actions -and $Task.Actions[0].Arguments -match '-Directory ''(?<Directory>.+?)''') {
            Write-Output $Matches['Directory']
        }
        else {
            Write-Output $SchedTask_LogDirectory
        }
    }
}
