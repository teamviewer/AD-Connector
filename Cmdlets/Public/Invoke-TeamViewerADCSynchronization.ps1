function Invoke-TeamViewerADCSynchronization {
   [CmdletBinding(SupportsShouldProcess = $true)]

   param(
      [Parameter(Mandatory = $false)]
      [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
      [string]
      $Config_File = (Join-Path -Path $PSScriptRoot -ChildPath 'Config\TeamViewerADC.json'),

      [Parameter(Mandatory = $false)]
      [ValidateScript({ -not $_ -or (Test-Path -Path $_ -PathType Container) -or (New-Item -Path $_ -ItemType Directory -Force -ErrorAction SilentlyContinue) })]
      [string]
      $Log_Directory = (Join-Path -Path $PSScriptRoot -ChildPath 'Logs'),

      [Parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Log_Basename = 'TeamViewerADC',

      [Parameter(Mandatory = $false)]
      [ValidateRange(1, [int]::MaxValue)]
      [int]
      $Log_Retention = 16,

      [Parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [ScriptBlock]
      $Progress_Handler = {},

      [Parameter(Mandatory = $false)]
      [switch]
      $PassThru
   )

   (. "$PSScriptRoot\..\Private\Import-TeamViewerADCConfiguration.ps1")
   (. "$PSScriptRoot\..\Private\Test-TeamViewerADCConfiguration.ps1")
   (. "$PSScriptRoot\..\Private\ActiveDirectory.ps1")
   (. "$PSScriptRoot\..\Private\Sync.ps1")
   (. "$PSScriptRoot\..\Private\Logfile.ps1")

   $Configuration = Import-TeamViewerADCConfiguration -ConfigFile $Config_File
   Test-TeamViewerADCConfiguration -Config_Content $Configuration

   if ($PSCmdlet.ShouldProcess($Config_File, 'Synchronize Active Directory users and groups.')) {
      $SyncResult = Invoke-TeamViewerADCSync -Configuration $Configuration -Progress $Progress_Handler

      if ($PassThru) {
         Write-Output $SyncResult
      }
      elseif ($Log_Directory -and $Log_Basename -and $Log_Retention -gt 0) {
         $SyncResult | Format-TeamViewerADCSyncLog | Out-TeamViewerADCLogLine -Log_Directory $Log_Directory -Log_Basename $Log_Basename

         Invoke-LogfileRotation -LogDirectory $Log_Directory -LogBasename $Log_Basename -LogRetention $Log_Retention
      }
      else {
         $SyncResult | Format-TeamViewerADCSyncLog
      }
   }
}
