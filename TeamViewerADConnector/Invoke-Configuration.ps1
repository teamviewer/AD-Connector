<#
 .SYNOPSIS
    Opens a graphical user interface for setting the configuration of the TeamViewer AD-Connector script.

 .DESCRIPTION
    This script will start the graphical user interface to configure the TeamViewer AD-Connector script.
    It allows to update the configuration and store it to the configuration file.
    Also it is possible to trigger a run of the TeamViewer AD-Connector synchronization script from
    within the graphical user interface.
    In addition, this script allows to setup a scheduled task to run TeamViewer AD-Connector regularly.

 .PARAMETER ConfigurationFile
    The path to the configuration file to use.
    Defaults to "TeamViewerADConnector.config.json" in the script directory.

 .PARAMETER Culture
    The two-letter language identifier used for the localization of the graphical user interface.
    Defaults to the currently configured culture of the Powershell.
    Falls back to english if no localization could be found for the specified culture.

 .PARAMETER Version
    Output the version of the script and exit.

 .NOTES
    Copyright (c) 2018-2020 TeamViewer GmbH
    See file LICENSE
    Version {ScriptVersion}
#>

param(
    [string]
    $ConfigurationFile = (Join-Path $PSScriptRoot "TeamViewerADConnector.config.json"),

    [string]
    $Culture = (Get-Culture).TwoLetterISOLanguageName,

    [switch]
    $Version
)

$ScriptVersion = "{ScriptVersion}"

if ($Version) {
    Write-Output $ScriptVersion
    return
}

$principal = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent()))
if (!$principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb runAs -ArgumentList "& '$($script:MyInvocation.MyCommand.Definition)'"
    exit 0
}

(. "$PSScriptRoot\Internal\Configuration.ps1")
(. "$PSScriptRoot\Internal\ActiveDirectory.ps1")
(. "$PSScriptRoot\Internal\TeamViewer.ps1")
(. "$PSScriptRoot\Internal\ScheduledSync.ps1")
(. "$PSScriptRoot\Internal\GraphicalUserInterface.ps1")

$configuration = (Import-Configuration $ConfigurationFile)
Invoke-GraphicalUserInterfaceConfiguration $configuration $Culture
