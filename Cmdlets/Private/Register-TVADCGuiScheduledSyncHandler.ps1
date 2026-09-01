function Register-TVADCGuiScheduledSyncHandler {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Locale', Justification = 'Locale parameter is used in scriptblocks passed to Add_Click')]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object] $Window,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object] $Locale
    )

    $Window.FindName('BtnChangeLogDirectory').Add_Click( {
            $folderDialog = (New-Object -TypeName System.Windows.Forms.FolderBrowserDialog)
            $folderDialog.SelectedPath = $Window.DataContext.ScheduledSyncData.LogDirectory

            if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $Window.DataContext.ScheduledSyncData.LogDirectory = $folderDialog.SelectedPath
                Sync-TVADCGuiDataContext -Window $Window
            }
        })

    $Window.FindName('BtnInstallSched').Add_Click( {
            if (-not (Test-Path -PathType 'Container' $Window.DataContext.ScheduledSyncData.LogDirectory)) {
                [System.Windows.Forms.MessageBox]::Show($Locale.LogDirectoryWarning, $Locale.Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)

                return
            }

            try {
                New-TeamViewerADCScheduledTask -Interval ([int]$Window.DataContext.ScheduledSyncData.Interval) | Out-Null
            }
            catch {
                Write-Error "Failed to install scheduled task: $_"

                [System.Windows.Forms.MessageBox]::Show($Locale.InstallError, $Locale.Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }

            Sync-TVADCGuiScheduledSyncData -Data $Window.DataContext.ScheduledSyncData -Locale $Locale
            Sync-TVADCGuiDataContext -Window $Window
        })

    $Window.FindName('BtnUninstallSched').Add_Click( {
            try {
                Remove-TeamViewerADCScheduledTask
            }
            catch {
                Write-Error "Failed to uninstall scheduled task: $_"
                [System.Windows.Forms.MessageBox]::Show($Locale.UninstallError, $Locale.Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }

            Sync-TVADCGuiScheduledSyncData -Data $Window.DataContext.ScheduledSyncData -Locale $Locale
            Sync-TVADCGuiDataContext -Window $Window
        })
}
