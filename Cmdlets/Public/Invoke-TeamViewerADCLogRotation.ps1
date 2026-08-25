function Invoke-TeamViewerADCLogRotation {
    [CmdletBinding()]

    [OutputType([void])]

    param(
        [Parameter(Mandatory = $false)]
        [ValidateScript({ -not $_ -or (Test-Path -Path $_ -PathType Container) -or (New-Item -Path $_ -ItemType Directory -Force -ErrorAction SilentlyContinue) })]
        [string]
        $Log_Directory = (Join-Path -Path $PSScriptRoot -ChildPath 'Logs'),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Log_Basename = 'TeamViewerADC',

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $Log_Retention = 16
    )

    $Log_Files = (Get-ChildItem -Path (Join-Path -Path $Log_Directory -ChildPath "$Log_Basename*.log") -File | Sort-Object -Property LastWriteTimeUtc, CreationTimeUtc, FullName)

    if ($Log_Files.Count -gt $Log_Retention) {
        Remove-Item -Path $Log_Files[0..($Log_Files.Count - $Log_Retention - 1)] -ErrorAction Stop
    }
}
