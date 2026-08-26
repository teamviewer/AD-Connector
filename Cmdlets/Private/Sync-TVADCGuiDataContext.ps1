function Sync-TVADCGuiDataContext {
    [CmdletBinding()]

    [OutputType([void])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]
        $Window
    )

    $Context = $Window.DataContext
    $Window.DataContext = $null
    $Window.DataContext = $Context
}
