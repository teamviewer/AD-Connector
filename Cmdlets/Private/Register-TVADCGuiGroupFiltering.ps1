function Register-TVADCGuiGroupFiltering {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object] $Window
    )

    $ADGroups_ComboBox = $Window.FindName('CbxNewADGroup')
    $ADGroups_ComboBox.Items.IsLiveFiltering = $true

    $ADGroups_ComboBox.AddHandler(
        [System.Windows.Controls.Primitives.TextBoxBase]::TextChangedEvent,
        [System.Windows.RoutedEventHandler] {
            $Filter_Text = $args[0].Text.ToLowerInvariant()

            if ($Filter_Text.Length -gt 2) {
                $ADGroups_ComboBox.Items.Filter = {
                    return $args[0].ToString().ToLowerInvariant().Contains($Filter_Text)
                }

                if (-not$ADGroups_ComboBox.IsDropDownOpen) {
                    $textBox = $ADGroups_ComboBox.Template.FindName('PART_EditableTextBox', $ADGroups_ComboBox)
                    $cursorPos = $textBox.SelectionStart
                    $ADGroups_ComboBox.IsDropDownOpen = $true
                    $textBox.Select($cursorPos, 0)
                }

                if ($ADGroups_ComboBox.SelectedItem) {
                    $ADGroups_ComboBox.SelectedItem = $null
                }
            }
            elseif ($ADGroups_ComboBox.Items.Filter) {
                $ADGroups_ComboBox.Items.Filter = $null
            }
        })
}
