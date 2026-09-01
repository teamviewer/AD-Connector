function New-TVADCGuiConfigurationData {
    [CmdletBinding()]

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This function creates data objects for the GUI, it does not make system state changes')]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object] $Configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object] $Locale,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object] $ScheduledSyncData,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object] $AD_Groups
    )

    return New-Object PSObject -Property @{
        L                      = $Locale
        LanguagesData          = @(Get-TVADCGuiSupportedLocale | ForEach-Object {
                New-Object PSObject -Property @{ Tag = "$_"; Content = $Locale."UserLanguage_$_" }
            })
        ScheduledSyncIntervals = @(Get-TVADCSupportedScheduledSyncInterval | ForEach-Object {
                New-Object PSObject -Property @{ Tag = "$_"; Content = $_ }
            })

        ConfigurationData      = $Configuration
        ScheduledSyncData      = $ScheduledSyncData
        ADGroupsData           = $AD_Groups
        ADGroupsSelectionData  = (New-Object PSObject -Property @{ AddValue = ''; RemoveValue = ''; })
        ScriptVersion          = $ScriptVersion
    }
}
