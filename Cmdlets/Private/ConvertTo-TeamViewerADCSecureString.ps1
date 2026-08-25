function ConvertTo-TeamViewerADCSecureString {
    [CmdletBinding()]

    [OutputType([securestring])]

    param(
        [AllowEmptyString()]
        [string]$Value
    )

    $SecureString = [System.Security.SecureString]::new()

    foreach ($Character in $Value.ToCharArray()) {
        [void]$SecureString.AppendChar($Character)
    }

    $SecureString.MakeReadOnly()

    return $SecureString
}
