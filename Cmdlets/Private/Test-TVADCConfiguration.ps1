function Test-TVADCConfiguration {
    [CmdletBinding()]

    [OutputType([void])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$Configuration
    )

    if (-not ($Configuration.Use_DefaultPassword -xor $Configuration.Use_GeneratedPassword -xor $Configuration.Use_SsoCustomerId)) {
        throw "One of the parameters 'Use_DefaultPassword', 'Use_SsoCustomerId' or 'Use_GeneratedPassword' must be set in the configuration. "
    }

    if ($Configuration.Use_DefaultPassword -and [string]::IsNullOrWhiteSpace($Configuration.User_DefaultPassword)) {
        throw "The parameter 'User_DefaultPassword' cannot be empty if 'Use_DefaultPassword' is configured."
    }

    if ($Configuration.Use_SsoCustomerId -and [string]::IsNullOrWhiteSpace($Configuration.Sso_CustomerId)) {
        throw "The parameter 'Sso_CustomerId' cannot be empty if 'Use_SsoCustomerId' is configured."
    }

    # Verify $Configuration.User_MeetingLicenseKey is a valid guid
    ![string]::IsNullOrWhiteSpace($Configuration.User_MeetingLicenseKey) -and [guid]$Configuration.User_MeetingLicenseKey | Out-Null
}
