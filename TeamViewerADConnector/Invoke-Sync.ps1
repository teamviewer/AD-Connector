<#
 .SYNOPSIS
    Runs the TeamViewer AD Connector synchronization with the given configuration.

 .DESCRIPTION
    This script runs the TeamViewer AD Connector synchronization script using the values in the given configuration file.
    It compares the list of users of the configured AD group with the users in the TeamViewer company that belongs to the configured TeamViewer API token.
    New users will be created, existing users will be updated and, depending on the configuration, TeamViewer users that do not belong to the AD group will be deactivated.
    Optionally, it also synchronises the AD users to corresponding user groups.
    The script outputs its progress to the console.

 .PARAMETER ConfigurationFile
    The path to the configuration file to use.
    Defaults to "TeamViewerADConnector.config.json" in the script directory.

 .PARAMETER ProgressHandler
    An optional script block that will be called on progress changes during the user synchronization.
    The script block will be called with two parameters:
    First, the current progress (percentage).
    Second, a string identifier of the current action.
    Defaults to an empty script block.

 .PARAMETER LogfileDirectory
    An optional path to the directory where log files should be stored.
    If given, the script will write its output to a logfile instead of standard output.

 .PARAMETER LogfileBasename
    The base filename used when writing output to log files. The current date will be appended to the basename, such that there is one log file per day.
    There is a default value given for this parameter.

 .PARAMETER LogfileRetentionCount
    The number of log files to keep at max. This is only used when writing to log files is activated. The script cleans-up old log files AFTER the actual sync has taken place.
    The default value for this parameter is 14, causing two weeks of log files to be kept.

 .PARAMETER PassThru
    If specified no output formatting is applied and the generated synchronization output is returned instead. It also disables writing to log files.

 .PARAMETER Version
    Output the version of the script and exit.

 .NOTES
    Copyright (c) 2018-2023 TeamViewer Germany GmbH
    See file LICENSE

    Version {ScriptVersion}
#>

param(
   [string]
   $ConfigurationFile = (Join-Path $PSScriptRoot 'TeamViewerADConnector.config.json'),

   [ScriptBlock]
   $ProgressHandler = {},

   [string]
   $LogfileDirectory,

   [string]
   $LogfileBasename = 'TeamViewerADConnector_',

   [int]
   $LogfileRetentionCount = 14,

   [switch]
   $PassThru,

   [switch]
   $Version
)

$script:ErrorActionPreference = 'Stop'

$ScriptVersion = '{ScriptVersion}'

(. "$PSScriptRoot\Internal\Configuration.ps1")
(. "$PSScriptRoot\Internal\ActiveDirectory.ps1")
(. "$PSScriptRoot\Internal\Sync.ps1")
(. "$PSScriptRoot\Internal\Logfile.ps1")

if ($Version) {
   Write-Output $ScriptVersion
   return
}

$configuration = (Import-Configuration $ConfigurationFile)
Confirm-Configuration $configuration

if ($PassThru) {
   Invoke-Sync $configuration $ProgressHandler
}
elseif ($LogfileDirectory -And $LogfileBasename -And $LogfileRetentionCount -gt 0) {
   Invoke-Sync $configuration $ProgressHandler | Format-SyncLog | Out-Logfile $LogfileDirectory $LogfileBasename
   Invoke-LogfileRotation $LogfileDirectory $LogfileBasename $LogfileRetentionCount
}
else {
   Invoke-Sync $configuration $ProgressHandler | Format-SyncLog
}
