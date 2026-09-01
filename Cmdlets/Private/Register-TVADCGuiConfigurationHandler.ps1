function Register-TVADCGuiConfigurationHandler {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Culture', Justification = 'Culture parameter is used in scriptblocks passed to Add_Click')]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object] $Window,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Culture
    )

    $Window.FindName('BtnSave').Add_Click( {
            Save-TVADCConfiguration -Configuration $Window.DataContext.ConfigurationData
        })

    $Window.FindName('BtnSaveAndRun').Add_Click( {
            $Window.DataContext.ConfigurationData.TestRun = $false
            Save-TVADCConfiguration -Configuration $Window.DataContext.ConfigurationData
            Set-TVADCEnvironment -Configuration $Window.DataContext.ConfigurationData
            Invoke-TVADCGuiSync -Configuration $Window.DataContext.ConfigurationData -Culture $Culture -Owner $Window
        })

    $Window.FindName('BtnSaveAndTestRun').Add_Click({
            $Window.DataContext.ConfigurationData.TestRun = $true
            Save-TVADCConfiguration -Configuration $Window.DataContext.ConfigurationData
            Set-TVADCEnvironment -Configuration $Window.DataContext.ConfigurationData
            Invoke-TVADCGuiSync -Configuration $Window.DataContext.ConfigurationData -Culture $Culture -Owner $Window
        })
}
