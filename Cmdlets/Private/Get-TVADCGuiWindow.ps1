
function Get-TVADCGuiWindow {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string]
        $File
    )

    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')

    try {
        [xml]$Window_Xml = (Get-Content -Path $File)
        $Window_XmlReader = (New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $Window_Xml)

        return [Windows.Markup.XamlReader]::Load($Window_XmlReader)
    }
    catch {
        Write-Verbose -Message 'Failed to initialize graphical user interface!'

        exit 1
    }
}
