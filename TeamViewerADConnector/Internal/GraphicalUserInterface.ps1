# Copyright (c) 2018 TeamViewer GmbH
# See file LICENSE

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
Add-Type -AssemblyName System.Windows.Forms

function Get-GraphicalUserInterfaceSupportedLocale() {
    return @(
        'bg', 'cs', 'da', 'de', 'el', 'en', 'es', 'fi', 'fr', 'hr', 'hu', 'id', 'it', 'ja',
        'ko', 'lt', 'nl', 'no', 'pl', 'pt', 'ro', 'ru', 'sk', 'sr', 'sv', 'th', 'tr', 'uk',
        'vi', 'zh_CN', 'zh_TW')
}

function Get-GraphicalUserInterfaceLocale([string] $culture = "en") {
    $locales = @{}
    (Get-ChildItem "$PSScriptRoot\Localization\GraphicalUserInterface.*.json" | `
            ForEach-Object { $locales[($_.Name -Split '\.')[1]] = (Get-Content $_ -Encoding UTF8 | Out-String | ConvertFrom-Json) })
    $locale = $locales[$culture]
    if (!$locale) { $locale = $locales.en }
    return $locale
}

function Get-GraphicalUserInterfaceWindow($file) {
    try {
        [xml] $windowXml = (Get-Content $file)
        $windowXmlReader = (New-Object System.Xml.XmlNodeReader $windowXml)
        return [Windows.Markup.XamlReader]::Load($windowXmlReader)
    }
    catch {
        Write-Error "Failed to initialize user interface!"
        exit 1
    }
}

function Invoke-GraphicalUserInterfaceSync($configuration, [string] $culture, $owner) {
    $locale = (Get-GraphicalUserInterfaceLocale $culture)

    $progressWindow = (Get-GraphicalUserInterfaceWindow "$PSScriptRoot\Forms\ProgressWindow.xaml")
    $progressWindow.Owner = $owner
    $progressWindow.DataContext = (New-Object PSObject -Prop @{ L = $locale; ScriptVersion = $ScriptVersion })

    $context = [hashtable]::Synchronized(@{})
    $context.Locale = $locale
    $context.ProgressWindow = $progressWindow
    $context.ProgressControl = $progressWindow.FindName("Progress")
    $context.MessageControl = $progressWindow.FindName("Message")
    $context.Command = (Join-Path (Get-Item "$PSScriptRoot\..") "Invoke-Sync.ps1")
    $context.ConfigurationFile = $configuration.Filename

    # Run `Invoke-Sync` in a separate PowerShell instance
    $runspace = [RunspaceFactory]::CreateRunspace($Host)
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("context", $context)
    $cmd = [PowerShell]::Create().AddScript( {
            try {
                & $context.Command -ConfigurationFile $context.ConfigurationFile -ProgressHandler {
                    param([int]$progress, [string]$message)
                    $context.ProgressControl.Dispatcher.Invoke( { $context.ProgressControl.Value = $progress } )
                    $context.MessageControl.Dispatcher.Invoke( { $context.MessageControl.Text = $context.Locale."Sync$message" } )
                } | Write-Host
            }
            catch {
                Write-Host "Synchronization failed: $_"
                $context.IsError = $true
            }
            finally {
                Write-Host "End of script"
                $context.IsFinished = $true
                if ($context.IsError -Or $context.IsCancelled) {
                    $context.ProgressWindow.Dispatcher.Invoke( { $context.ProgressWindow.Close() } )
                }
            }
        })
    $cmd.Runspace = $runspace

    # Progress window close button
    $progressWindow.Add_Closing( {
            $_.Cancel = !$context.IsFinished
            if ($_.Cancel) {
                Write-Host "User cancelled synchronization"
                $context.IsCancelled = $true
                $context.StopHandle = $cmd.BeginStop( {}, $null)
            }
        })

    $handle = $cmd.BeginInvoke()
    $progressWindow.ShowDialog()
    if ($context.StopHandle) { $cmd.EndStop($context.StopHandle) }
    else { $cmd.EndInvoke($handle) }
    $runspace.Close()
    if ($context.IsError) {
        [System.Windows.Forms.MessageBox]::Show(
            $locale.SyncError,
            $locale.Title,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Invoke-GraphicalUserInterfaceConfiguration($configuration, [string] $culture) {
    $locale = (Get-GraphicalUserInterfaceLocale $culture)

    function RefreshDataContext($window) {
        $context = $window.DataContext
        $window.DataContext = $null
        $window.DataContext = $context
    }

    function RefreshScheduledSyncData($data) {
        $scheduledSync = Get-ScheduledSync
        $enabled = [bool]($scheduledSync)
        if ($enabled) {
            $data.StatusMessage = $locale.ScheduledSyncEnabled
        }
        else {
            $data.StatusMessage = $locale.ScheduledSyncDisabled
        }
        if (!$data.IsEnabled) {
            $data.Interval = (Get-ScheduledSyncInterval $scheduledSync).TotalHours
            $data.LogDirectory = (Get-ScheduledSyncLogDirectory $scheduledSync)
        }
        $data.IsEnabled = $enabled
        $data.IsNotEnabled = (!$enabled)
    }

    $languagesData = (Get-GraphicalUserInterfaceSupportedLocale | `
            ForEach-Object { New-Object PSObject -Prop @{
                Tag     = "$_"
                Content = $locale."UserLanguage_$_"
            }})

    # Scheduled sync view model
    $scheduledSyncData = (New-Object PSObject -Prop @{
            IsEnabled     = $false
            IsNotEnabled  = $true
            Interval      = 1
            LogDirectory  = ''
            StatusMessage = ''
        })
    RefreshScheduledSyncData $scheduledSyncData

    # Show loading window while fetching AD groups
    $loadingWindow = (Get-GraphicalUserInterfaceWindow "$PSScriptRoot\Forms\LoadingWindow.xaml")
    $loadingWindow.DataContext = (New-Object PSObject -Prop @{
            L              = $locale
            LoadingMessage = $locale.LoadingADGroups
            ScriptVersion  = $ScriptVersion
        })
    $loadingWindow.Show()
    $adGroups = (Get-ActiveDirectoryGroup $configuration.ActiveDirectoryRoot)
    $loadingWindow.Close()
    $adGroupsSelection = (New-Object PSObject -Prop @{ AddValue = ""; RemoveValue = ""; })

    # Main Window
    $mainWindow = (Get-GraphicalUserInterfaceWindow "$PSScriptRoot\Forms\MainWindow.xaml")
    $mainWindow.DataContext = (New-Object PSObject -Prop @{
            L                     = $locale
            LanguagesData         = $languagesData
            ConfigurationData     = $configuration
            ScheduledSyncData     = $scheduledSyncData
            ADGroupsData          = $adGroups
            ADGroupsSelectionData = $adGroupsSelection
            ScriptVersion         = $ScriptVersion
        })

    # AD Groups ComboBox filtering
    $adGroupsComboBox = $mainWindow.FindName("CbxNewADGroup")
    $adGroupsComboBox.Items.IsLiveFiltering = $true;
    $adGroupsComboBox.AddHandler(
        [System.Windows.Controls.Primitives.TextBoxBase]::TextChangedEvent,
        [System.Windows.RoutedEventHandler] {
            $filterText = $args[0].Text.ToLowerInvariant()
            if ($filterText.Length -gt 2) {
                $adGroupsComboBox.Items.Filter = {
                    return $args[0].ToString().ToLowerInvariant().Contains($filterText)
                }
                if (!$adGroupsComboBox.IsDropDownOpen) {
                    $textBox = $adGroupsComboBox.Template.FindName("PART_EditableTextBox", $adGroupsComboBox)
                    $cursorPos = $textBox.SelectionStart
                    $adGroupsComboBox.IsDropDownOpen = $true
                    $textBox.Select($cursorPos, 0)
                }
                if ($adGroupsComboBox.SelectedItem) { $adGroupsComboBox.SelectedItem = $null }
            }
            elseif ($adGroupsComboBox.Items.Filter) { $adGroupsComboBox.Items.Filter = $null }
        })

    # Click Handler Button "Test Token"
    $mainWindow.FindName("BtnTestToken").Add_Click( {
            try { $tokenValid = (Invoke-TeamViewerPing $mainWindow.DataContext.ConfigurationData.ApiToken) }
            catch { Write-Error "Token test failed: $_" }
            if ($tokenValid) {
                [System.Windows.Forms.MessageBox]::Show(
                    $locale.TestTokenSuccess,
                    $locale.Title,
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information)
            }
            else {
                [System.Windows.Forms.MessageBox]::Show(
                    $locale.TestTokenFailure,
                    $locale.Title,
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        })

    # Click Handler Button "Save"
    $mainWindow.FindName("BtnSave").Add_Click( {
            Save-Configuration $mainWindow.DataContext.ConfigurationData
        })

    # Click Handler Button "Save & Run"
    $mainWindow.FindName("BtnSaveAndRun").Add_Click( {
            Save-Configuration $mainWindow.DataContext.ConfigurationData
            Invoke-GraphicalUserInterfaceSync $mainWindow.DataContext.ConfigurationData $culture $mainWindow
        })

    # Click Handler Button "Add" (Group)
    $mainWindow.FindName("BtnAddGroup").Add_Click( {
            $group = $mainWindow.DataContext.ADGroupsSelectionData.AddValue
            $groups = [System.Collections.ArrayList]($mainWindow.DataContext.ConfigurationData.ActiveDirectoryGroups)
            if ($group -And $groups -NotContains $group) {
                $groups.Add($group)
                $mainWindow.DataContext.ConfigurationData.ActiveDirectoryGroups = $groups.ToArray()
                $mainWindow.DataContext.ADGroupsSelectionData.AddValue = ""
                $adGroupsComboBox.Items.Filter = $null
                RefreshDataContext $mainWindow
            }
        })

    # Click Handler Button "Remove" (Group)
    $mainWindow.FindName("BtnRemoveGroup").Add_Click( {
            $group = $mainWindow.DataContext.ADGroupsSelectionData.RemoveValue
            $groups = [System.Collections.ArrayList]($mainWindow.DataContext.ConfigurationData.ActiveDirectoryGroups)
            if ($group) {
                $groups.Remove($group)
                $mainWindow.DataContext.ConfigurationData.ActiveDirectoryGroups = $groups.ToArray()
                RefreshDataContext $mainWindow
            }
        })

    # Click Handler Button "..." (Change log directory location)
    $mainWindow.FindName("BtnChangeLogDirectory").Add_Click( {
            $folderDialog = (New-Object -Typename System.Windows.Forms.FolderBrowserDialog)
            $folderDialog.SelectedPath = $mainWindow.DataContext.ScheduledSyncData.LogDirectory
            if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $mainWindow.DataContext.ScheduledSyncData.LogDirectory = $folderDialog.SelectedPath
                RefreshDataContext $mainWindow
            }
        })

    # Click Handler Button "Install" (Scheduled Task)
    $mainWindow.FindName("BtnInstallSched").Add_Click( {
            if (-Not (Test-Path -PathType "Container" $mainWindow.DataContext.ScheduledSyncData.LogDirectory)) {
                [System.Windows.Forms.MessageBox]::Show(
                    $locale.LogDirectoryWarning,
                    $locale.Title,
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning)
            }
            try {
                Install-ScheduledSync (New-TimeSpan -Hours $mainWindow.DataContext.ScheduledSyncData.Interval) `
                    $mainWindow.DataContext.ScheduledSyncData.LogDirectory
            }
            catch {
                Write-Error "Failed to install scheduled task: $_"
                [System.Windows.Forms.MessageBox]::Show(
                    $locale.InstallError,
                    $locale.Title,
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error)
            }
            RefreshScheduledSyncData $mainWindow.DataContext.ScheduledSyncData
            RefreshDataContext $mainWindow
        })

    # Click Handler Button "Uninstall" (Scheduled Task)
    $mainWindow.FindName("BtnUninstallSched").Add_Click( {
            try { Uninstall-ScheduledSync }
            catch {
                Write-Error "Failed to uninstall scheduled task: $_"
                [System.Windows.Forms.MessageBox]::Show(
                    $locale.UninstallError,
                    $locale.Title,
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error)
            }
            RefreshScheduledSyncData $mainWindow.DataContext.ScheduledSyncData
            RefreshDataContext $mainWindow
        })

    $mainWindow.ShowDialog() | Out-Null
}
