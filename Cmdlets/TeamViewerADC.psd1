@{
    # Script module or binary module file associated with this manifest.
    RootModule           = 'TeamViewerADC.psm1'

    # Version number of this module.
    ModuleVersion        = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module.
    GUID                 = 'b2c9f0a4-7e3d-4f6a-9c1b-2d5e8a4f10c7'

    # Author of this module.
    Author               = 'TeamViewer Germany GmbH'

    # Company or vendor of this module.
    CompanyName          = 'TeamViewer Germany GmbH'

    # Copyright statement for this module.
    Copyright            = '(c) 2018-2026 TeamViewer Germany GmbH. All rights reserved.'

    # Description of the functionality provided by this module.
    Description          = 'TeamViewerADC synchronizes users and user groups from Active Directory (AD) to a TeamViewer tenant / company via REST based APIs.'

    # Minimum version of the PowerShell engine required by this module.
    PowerShellVersion    = '5.1'

    # Functions to export from this module. Keep alphabetized.
    FunctionsToExport    = '*'

    # Cmdlets to export from this module.
    CmdletsToExport      = @()

    # Variables to export from this module.
    VariablesToExport    = @()

    # Aliases to export from this module.
    AliasesToExport      = @()

    # Private data to pass to the module specified in RootModule.
    PrivateData          = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('TeamViewer', 'ActiveDirectory', 'AD', 'Synchronization', 'Automation', 'Api', 'Provisioning', 'PowerShell', 'Scripting')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/teamviewer/AD-Connector/blob/main/LICENSE.md'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/teamviewer/AD-Connector'

            # ReleaseNotes of this module.
            ReleaseNotes = 'See CHANGELOG.md at https://github.com/teamviewer/AD-Connector/blob/main/CHANGELOG.md'
        }
    }
}
