function Test-TeamViewerADCTeamViewerPS {
    [CmdletBinding()]

    [OutputType([bool])]

    param()

    [string]$TVPS_ModuleName = 'TeamViewerPS'

    if (Get-InstalledModule -Name $TVPS_ModuleName -ErrorAction SilentlyContinue) {
        Write-Verbose "PowerShell module '$TVPS_ModuleName' is already installed."

        return $true
    }
    else {
        Write-Verbose "PowerShell module '$TVPS_ModuleName' is not installed!"

        return $false
    }
}
