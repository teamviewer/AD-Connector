function Invoke-TeamViewerADCSynchronization {
   [CmdletBinding(SupportsShouldProcess = $true)]

   param(
      [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
      [string]
      $Config_File = (Join-Path -Path $PSScriptRoot -ChildPath 'Config\TeamViewerADC.json'),

      [ValidateScript({ -not $_ -or (Test-Path -Path $_ -PathType Container) -or (New-Item -Path $_ -ItemType Directory -Force -ErrorAction SilentlyContinue) })]
      [string]
      $Log_Directory = (Join-Path -Path $PSScriptRoot -ChildPath 'Logs'),

      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Log_Basename,

      [ValidateRange(1, [int]::MaxValue)]
      [int]
      $Log_Retention = 16,

      [ValidateNotNull()]
      [ScriptBlock]
      $Progress_Handler = {},

      [switch]
      $PassThru
   )

   begin {
   }

   process {
      (. "$PSScriptRoot\..\Private\Configuration.ps1")
      (. "$PSScriptRoot\..\Private\ActiveDirectory.ps1")
      (. "$PSScriptRoot\..\Private\Sync.ps1")
      (. "$PSScriptRoot\..\Private\Logfile.ps1")

      $Config_Content = Import-Configuration -ConfigFile $Config_File
      Confirm-Configuration -ConfigContent $Config_Content

      if ($PSCmdlet.ShouldProcess($Config_File, 'Synchronize Active Directory users and groups.')) {
         if ($PassThru) {
            Invoke-Sync -ConfigContent $Config_Content -Progress_Handler $Progress_Handler
         }
         elseif ($Log_Directory -and $Log_Basename -and $Log_Retention -gt 0) {
            Invoke-Sync -ConfigContent $Config_Content -Progress_Handler $Progress_Handler | Format-SyncLog | Out-TeamViewerADCLogfile -LogDirectory $Log_Directory -LogBasename $Log_Basename

            Invoke-LogfileRotation -LogDirectory $Log_Directory -LogBasename $Log_Basename -LogRetention $Log_Retention
         }
         else {
            Invoke-Sync -ConfigContent $Config_Content -Progress_Handler $Progress_Handler | Format-SyncLog
         }
      }
   }
}
