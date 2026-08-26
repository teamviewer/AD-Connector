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
      $Directory = (Join-Path -Path $PSScriptRoot -ChildPath 'Logs'),

      [Parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Basename = 'TeamViewerADC',

      [Parameter(Mandatory = $false)]
      [ValidateRange(1, [int]::MaxValue)]
      [int]
      $Retention = 16,

      [Parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [ScriptBlock]
      $Progress_Handler = {},

      [Parameter(Mandatory = $false)]
      [switch]
      $PassThru
   )

   $Configuration = Import-TVADCConfiguration -Config_File $Config_File
   Test-TVADCConfiguration -Configuration $Configuration

   if ($PSCmdlet.ShouldProcess($Config_File, 'Synchronize Active Directory users and groups.')) {
      $SyncResult = Invoke-TVADCSync -Configuration $Configuration -Progress $Progress_Handler

      if ($PassThru) {
         Write-Output $SyncResult
      }
      elseif ($Directory -and $Basename -and $Retention -gt 0) {
         $SyncResult | Format-TVADCSyncLog | Out-TVADCLogLine -Directory $Directory -Basename $Basename

         Invoke-TeamViewerADCLogRotation -Directory $Directory -Basename $Basename -Retention $Retention
      }
      else {
         $SyncResult | Format-TVADCSyncLog
      }
   }
}
