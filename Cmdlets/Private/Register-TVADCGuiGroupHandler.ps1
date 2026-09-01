function Register-TVADCGuiGroupHandler {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'AD_GroupsComboBox', Justification = 'AD_GroupsComboBox parameter is used in scriptblocks passed to Add_Click')]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object] $Window,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object] $AD_GroupsComboBox
    )

    $Window.FindName('BtnAddGroup').Add_Click( {
            $group = $Window.DataContext.ADGroupsSelectionData.AddValue
            $groups = [System.Collections.ArrayList]($Window.DataContext.ConfigurationData.ActiveDirectory_Groups)

            if ($group -and $groups -notcontains $group) {
                $groups.Add($group)
                $Window.DataContext.ConfigurationData.ActiveDirectory_Groups = $groups.ToArray()
                $Window.DataContext.ADGroupsSelectionData.AddValue = ''
                $AD_GroupsComboBox.Items.Filter = $null
                Sync-TVADCGuiDataContext -Window $Window
            }
        })

    $Window.FindName('BtnRemoveGroup').Add_Click( {
            $group = $Window.DataContext.ADGroupsSelectionData.RemoveValue
            $groups = [System.Collections.ArrayList]($Window.DataContext.ConfigurationData.ActiveDirectory_Groups)

            if ($group) {
                $groups.Remove($group)
                $Window.DataContext.ConfigurationData.ActiveDirectory_Groups = $groups.ToArray()
                Sync-TVADCGuiDataContext -Window $Window
            }
        })
}
