function Out-TeamViewerADCLogfile {
    [CmdletBinding(SupportsShouldProcess = $true)]

    [OutputType([void])]

    param(
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]
        $Log_Directory,

        [ValidateNotNullOrEmpty()]
        [string]
        $Log_Basename
    )

    begin {
        $Log_Filename = Join-Path -Path $Log_Directory -ChildPath "$($Log_Basename)$('{0:yyyy-MM-dd}' -f (Get-Date)).log"
    }

    process {
        if ($PSCmdlet.ShouldProcess($Log_Filename, 'Append to logfile.')) {
            $_ | Out-File -FilePath $Log_Filename -Append
        }
    }
}
