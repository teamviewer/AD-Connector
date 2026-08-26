function Register-TVADCGuiTokenHandler {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Locale', Justification = 'Locale parameter is used in scriptblocks passed to Add_Click')]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object] $Window,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object] $Locale
    )

    $Window.FindName('BtnTestToken').Add_Click( {
            try {
                Set-TVADCEnvironment -Configuration $Window.DataContext.ConfigurationData

                $Token_Valid = (Invoke-TeamViewerPing -ApiToken (ConvertTo-TVADCSecureString -Value $Window.DataContext.ConfigurationData.Api_Token))
            }
            catch {
                Write-Error "Token test failed: $_"

                $Token_Valid = $false
            }

            if ($Token_Valid) {
                [System.Windows.Forms.MessageBox]::Show($Locale.TestTokenSuccess, $Locale.Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
            else {
                [System.Windows.Forms.MessageBox]::Show($Locale.TestTokenFailure, $Locale.Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        })
}
