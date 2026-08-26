function ConvertTo-TVADCSecureString {
    [CmdletBinding()]

    [OutputType([securestring])]

    param(
        [AllowEmptyString()]
        [string]$Value
    )

    $String_Secure = [System.Security.SecureString]::new()

    foreach ($Character in $Value.ToCharArray()) {
        [void]$String_Secure.AppendChar($Character)
    }

    $String_Secure.MakeReadOnly()

    return $String_Secure
}
