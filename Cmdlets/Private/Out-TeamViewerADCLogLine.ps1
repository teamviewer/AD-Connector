function Out-TeamViewerADCLogLine {
    [CmdletBinding(SupportsShouldProcess = $true)]

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

        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    begin {
        $Log_Filename = Join-Path -Path $Log_Directory -ChildPath "$($Log_Basename)$('{0:yyyy-MM-dd}' -f (Get-Date)).log"
    }

    process {
        if ($PSCmdlet.ShouldProcess($Log_Filename, 'Append to logfile.')) {
            $InputObject | Out-File -FilePath $Log_Filename -Append
        }
    }
}
