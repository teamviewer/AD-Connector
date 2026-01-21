[CmdletBinding()]
param(
    [string]$ModuleName = 'TeamViewerPS'
)

if (-not (Get-Module -Name $ModuleName -ErrorAction SilentlyContinue)) {
    try {
        Import-Module -Name $ModuleName -ErrorAction Stop
        Write-Verbose "Module $Modulename was succesfully installed"
    }
    catch {
        Write-Verbose 'Install error'
        exit 1
    }
}
else {
    Write-Verbose "Module $Modulename was already installed"
}


$ConfigurationScript = Join-Path $PSScriptRoot 'Invoke-Configuration.ps1'

& $ConfigurationScript
