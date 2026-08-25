#Requires -RunAsAdministrator

function Invoke-TeamViewerADCTeamViewerPSInstallation {
    [CmdletBinding(SupportsShouldProcess = $true)]

    [OutputType([bool])]

    param()

    [string]$TVPS_ModuleName = 'TeamViewerPS'

    if (Test-TeamViewerADCTeamViewerPS) {
        Write-Verbose "PowerShell module '$TVPS_ModuleName' is already installed."

        return $true
    }
    else {
        Write-Verbose "PowerShell module '$TVPS_ModuleName' is not installed."

        try {
            Write-Verbose "PowerShell module '$TVPS_ModuleName' is being installed..."

            if ($PSCmdlet.ShouldProcess($TVPS_ModuleName, 'Install PowerShell module.')) {
                Install-Module -Name $TVPS_ModuleName -Scope AllUsers -Force -ErrorAction Stop

                return $true
            }
        }
        catch {
            Write-Verbose "Installation error: $_"

            return $false
        }
    }
}
