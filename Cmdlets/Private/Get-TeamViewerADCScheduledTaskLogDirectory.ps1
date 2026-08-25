function Get-TeamViewerADCScheduledTaskLogDirectory {
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
        if ($Task -and $Task.Actions -and $Task.Actions[0].Arguments -match '-Log_Directory ''(?<Log_Directory>.+?)''') {
            return $Matches['Log_Directory']
        }

        return $SchedTask_LogDirectory
    }
}
