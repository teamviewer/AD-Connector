function Select-TVADCActiveDirectoryCommonName {
    [CmdletBinding()]

    [OutputType([string])]

    param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AD_Path
    )

    # Simplified version of a common-name parser.
    # The following characters need to be escaped:
    #  , + " \ < > ; \r \n = /
    # See https://msdn.microsoft.com/en-us/windows/desktop/aa366101
    # See https://www.ietf.org/rfc/rfc2253.txt

    process {
        if ($AD_Path -match 'CN=((?:[^,+"\\<>;\r\n=/]|(?:\\[,+"\\<>;\r\n=/]))+)') {
            Write-Output ($Matches.1 -replace '\\([,+"\\<>;\r\n=/])', '$1')
        }
        else {
            Write-Output $null
        }
    }
}
