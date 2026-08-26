Add-Type -AssemblyName System.Windows.Forms

function Invoke-TVADCGuiSync {
    [CmdletBinding()]

    [OutputType([void])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$Configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Culture,

        [Parameter(Mandatory = $false)]
        [object]$Owner
    )

    # Resolve localized strings and create the progress window used by the sync.
    $Locale = (Get-TVADCGuiLocale $Culture)

    $Window_SyncProgress = (Get-TVADCGuiWindow -File "$PSScriptRoot\Forms\Window_Progress.xaml")
    $Window_SyncProgress.Owner = $Owner
    $Window_SyncProgress.DataContext = (New-Object PSObject -Prop @{ L = $Locale; ScriptVersion = $ScriptVersion })

    # Store UI controls and synchronization settings in a thread-safe context.
    $Context = [hashtable]::Synchronized(@{})
    $Context.Locale = $Locale
    $Context.Window_Progress = $Window_SyncProgress
    $Context.ProgressControl = $Window_SyncProgress.FindName('Progress')
    $Context.MessageControl = $Window_SyncProgress.FindName('Message')
    $Context.Command = (Join-Path $PSScriptRoot 'Invoke-TVADCSync.ps1')
    $Context.ConfigurationFile = $Configuration.Filename

    # Run the synchronization in a dedicated STA runspace so the UI remains responsive.
    $Runspace = [RunspaceFactory]::CreateRunspace($Host)
    $Runspace.ApartmentState = 'STA'
    $Runspace.ThreadOptions = 'ReuseThread'
    $Runspace.Open()
    $Runspace.SessionStateProxy.SetVariable('context', $Context)

    $Cmd = [PowerShell]::Create().AddScript( {
            try {
                # Forward synchronization progress to the controls on the UI thread.
                & $Context.Command -ConfigurationFile $Context.ConfigurationFile -ProgressHandler {
                    param([int]$progress, [string]$message)

                    $Progress_Value = $progress
                    $Message_Key = $message
                    $Context.ProgressControl.Dispatcher.Invoke( { $Context.ProgressControl.Value = $Progress_Value } )
                    $Context.MessageControl.Dispatcher.Invoke( { $Context.MessageControl.Text = $Context.Locale."Sync$Message_Key" } )
                } | Write-Host
            }
            catch {
                # Keep the error state in the shared context for the caller to report.
                Write-Host "Synchronization failed: $_"

                $Context.IsError = $true
            }
            finally {
                # Mark completion and close the window after failure or cancellation.
                Write-Host 'End of script'

                $Context.IsFinished = $true

                if ($Context.IsError -or $Context.IsCancelled) {
                    $Context.Window_Progress.Dispatcher.Invoke( { $Context.Window_Progress.Close() } )
                }
            }
        })

    # Stop the background command when the user closes the progress window.
    $Window_SyncProgress.Add_Closing( {
            $_.Cancel = !$Context.IsFinished

            if ($_.Cancel) {
                Write-Host 'User cancelled synchronization.'

                $Context.IsCancelled = $true
                $Context.StopHandle = $Cmd.BeginStop( {}, $null)
            }
        })

    # Start the sync and block here while the modeless background operation updates the dialog.
    $Handle = $Cmd.BeginInvoke()
    $Window_SyncProgress.ShowDialog()

    # Complete or stop the asynchronous command before releasing the runspace.
    if ($Context.StopHandle) {
        $Cmd.EndStop($Context.StopHandle)
    }
    else {
        $Cmd.EndInvoke($Handle)
    }

    $Runspace.Close()

    # Surface synchronization failures after the progress window has closed.
    if ($Context.IsError) {
        [System.Windows.Forms.MessageBox]::Show($Locale.SyncError, $Locale.Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}
