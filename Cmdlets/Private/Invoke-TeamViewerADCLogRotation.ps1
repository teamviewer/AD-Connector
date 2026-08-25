function Invoke-TeamViewerADCLogRotation {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]
        $Log_Directory,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Log_Basename,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $RetentionCount
    )

    $Log_Files = (Get-ChildItem -Path (Join-Path -Path $Log_Directory -ChildPath "$Log_Basename*.log") -File | Sort-Object -Property LastWriteTimeUtc, CreationTimeUtc, FullName)

    if ($Log_Files.Count -gt $RetentionCount) {
        Remove-Item -Path $Log_Files[0..($Log_Files.Count - $RetentionCount - 1)] -ErrorAction Stop
    }
}
