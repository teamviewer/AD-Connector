Add-Type -AssemblyName System.Windows.Forms
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')

function Invoke-TVADCGuiConfiguration {
    [CmdletBinding()]

    [OutputType([void])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object] $Configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Culture
    )

    $Locale = Get-TVADCGuiLocale -Culture $Culture
    $SchedTask_Data = New-Object PSObject -Property @{
        IsEnabled     = $false
        IsNotEnabled  = $true
        Interval      = 1
        LogDirectory  = ''
        StatusMessage = ''
    }

    Sync-TVADCGuiScheduledSyncData -Data $SchedTask_Data -Locale $Locale

    $AD_Groups = Get-TVADCGuiConfigurationGroup -AD_Root $Configuration.ActiveDirectory_Root -Locale $Locale
    $Window_Main = Get-TVADCGuiWindow -File "$PSScriptRoot\Forms\MainWindow.xaml"
    $Window_Main.DataContext = New-TVADCGuiConfigurationData -Configuration $Configuration -Locale $Locale -ScheduledSyncData $SchedTask_Data -AD_Groups $AD_Groups

    Register-TVADCGuiGroupFiltering -Window_Main $Window_Main
    Register-TVADCGuiTokenHandler -Window_Main $Window_Main -Locale $Locale
    Register-TVADCGuiConfigurationHandler -Window_Main $Window_Main -Culture $Culture
    Register-TVADCGuiGroupHandler -Window_Main $Window_Main -AD_GroupsComboBox ($Window_Main.FindName('CbxNewADGroup'))
    Register-TVADCGuiScheduledSyncHandler -Window_Main $Window_Main -Locale $Locale

    $Window_Main.ShowDialog() | Out-Null
}
