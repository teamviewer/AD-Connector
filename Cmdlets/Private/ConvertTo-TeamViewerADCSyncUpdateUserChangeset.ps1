function ConvertTo-TeamViewerADCSyncUpdateUserChangeset {
    [CmdletBinding()]

    [OutputType([hashtable])]

    param(
        [Parameter(Position = 0)]
        $TV_User,

        [Parameter(Position = 1)]
        $AD_User
    )

    $InputObject = @{ }

    if (-not $TV_User -or !$AD_User) {
        return $InputObject
    }

    if ($AD_User.name -ne $TV_User.name) {
        $InputObject.name = $AD_User.name
    }

    if ($AD_User.IsEnabled -ne $TV_User.active) {
        $InputObject.active = $AD_User.IsEnabled
    }

    return $InputObject
}
