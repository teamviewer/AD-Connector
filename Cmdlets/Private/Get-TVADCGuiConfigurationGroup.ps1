function Get-TVADCGuiConfigurationGroup {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $AD_Root,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object] $Locale
    )

    $Window_LoadingADGroups = Get-TVADCGuiWindow -File "$PSScriptRoot\Forms\Window_LoadingADGroups.xaml"
    $Window_LoadingADGroups.DataContext = New-Object PSObject -Property @{
        L              = $Locale
        LoadingMessage = $Locale.LoadingADGroups
        ScriptVersion  = $ScriptVersion
    }

    try {
        $Window_LoadingADGroups.Show()
        $AD_Groups = Get-TVADCActiveDirectoryGroup -AD_Root $AD_Root
    }
    finally {
        $Window_LoadingADGroups.Close()
    }

    return $AD_Groups
}
