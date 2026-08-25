#Requires -RunAsAdministrator

function Invoke-TeamViewerADCConfiguration {
   [CmdletBinding()]

   param(
      [Parameter(Mandatory = $false)]
      [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
      [string]
      $Config_File = (Join-Path -Path $PSScriptRoot -ChildPath 'Config\TeamViewerADC.json'),

      [Parameter(Mandatory = $false)]
      [string]
      $Culture = (Get-Culture).TwoLetterISOLanguageName
   )

   process {
      (. "$PSScriptRoot\..\Private\Import-TeamViewerADCConfiguration.ps1")
      (. "$PSScriptRoot\..\Private\Save-TeamViewerADCConfiguration.ps1")
      (. "$PSScriptRoot\..\Private\Test-TeamViewerADCConfiguration.ps1")
      (. "$PSScriptRoot\..\Private\ActiveDirectory.ps1")
      (. "$PSScriptRoot\..\Private\ScheduledSync.ps1")
      (. "$PSScriptRoot\..\Private\GraphicalUserInterface.ps1")

      $Configuration = Import-TeamViewerADCConfiguration -ConfigFile $Config_File
      # ToDo: Check if needed and what happens
      Test-TeamViewerADCConfiguration -Config_Content $Configuration

      Invoke-GraphicalUserInterfaceConfiguration $Configuration $Culture
   }
}
