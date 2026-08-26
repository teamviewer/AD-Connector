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
      # Requires elevation to manage the scheduled synchronization task.
      if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
         throw 'Invoke-TeamViewerADCConfiguration requires administrator privileges.'
      }

      $Configuration = Import-TVADCConfiguration -Config_File $Config_File

      # ToDo: Review if Test-TVADCConfiguration is strictly necessary before invoking the GUI.
      # This call validates the configuration but may have side effects or overhead.
      Test-TVADCConfiguration -Configuration $Configuration

      Invoke-TVADCGuiConfiguration $Configuration -Culture $Culture
   }
}
