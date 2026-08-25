function Test-TeamViewerADCConfiguration {
    [CmdletBinding()]

    [OutputType([void])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$Config_Content
    )

    if (-not ($Config_Content.Use_DefaultPassword -xor $Config_Content.Use_GeneratedPassword -xor $Config_Content.Use_SsoCustomerId)) {
        throw "One of the parameters 'Use_DefaultPassword', 'Use_SsoCustomerId' or 'Use_GeneratedPassword' must be set in the configuration. "
    }

    if ($Config_Content.Use_DefaultPassword -and [string]::IsNullOrWhiteSpace($Config_Content.User_DefaultPassword)) {
        throw "The parameter 'User_DefaultPassword' cannot be empty if 'Use_DefaultPassword' is configured."
    }

    if ($Config_Content.Use_SsoCustomerId -and [string]::IsNullOrWhiteSpace($Config_Content.Sso_CustomerId)) {
        throw "The parameter 'Sso_CustomerId' cannot be empty if 'Use_SsoCustomerId' is configured."
    }

    # Verify $Config_Content.User_MeetingLicenseKey is a valid guid
    ![string]::IsNullOrWhiteSpace($Config_Content.User_MeetingLicenseKey) -and [guid]$Config_Content.User_MeetingLicenseKey | Out-Null
}
