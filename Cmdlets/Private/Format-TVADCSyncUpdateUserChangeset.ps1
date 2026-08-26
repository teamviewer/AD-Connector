function Format-TVADCSyncUpdateUserChangeset {
    [CmdletBinding()]

    [OutputType([string])]

    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $InputObject
    )

    process {
        $Message = ''

        if ($InputObject.name) {
            $Message += "Changing name to '$($InputObject.name)'. "
        }

        if ($InputObject.PSObject.Properties['active']) {
            $Status = if ($InputObject.active) {
                'active'
            }
            else {
                'inactive'
            }

            $Message += "Changing account status to '$Status'. "
        }

        Write-Output $Message
    }
}
