#Requires -RunAsAdministrator

function Invoke-TeamViewerADCConfiguration {
   [CmdletBinding()]

   param(
      [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
      [string]
      $Config_File = (Join-Path -Path $PSScriptRoot -ChildPath 'Config\TeamViewerADC.json'),

      [string]
      $Culture = (Get-Culture).TwoLetterISOLanguageName
   )

   process {
      (. "$PSScriptRoot\..\Private\Configuration.ps1")
      (. "$PSScriptRoot\..\Private\ActiveDirectory.ps1")
      (. "$PSScriptRoot\..\Private\ScheduledSync.ps1")
      (. "$PSScriptRoot\..\Private\GraphicalUserInterface.ps1")

      $Config_Content = Import-Configuration -ConfigFile $Config_File
      # ToDo: Check if needed and what happens
      Confirm-Configuration -ConfigContent $Config_Content

      Invoke-GraphicalUserInterfaceConfiguration $Config_Content $Culture
   }
}
