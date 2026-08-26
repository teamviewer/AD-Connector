# TeamViewer Active Directory Connector (AD Connector, ADC)

A PowerShell module to synchronize users and user groups from Active Directory (AD) to a [TeamViewer](https://www.teamviewer.com) tenant / company via REST based API's.
Targets Windows PowerShell 5.1 and PowerShell 6+ on Windows.

<!--[+github]-->
[![Build Status](https://github.com/teamviewer/AD-Connector/actions/workflows/ci.yml/badge.svg)](https://github.com/teamviewer/AD-Connector/actions/workflows/ci.yml)
<!--[-github]-->

Further information can be found in the knowledge base article "[Active Directory-Connector](https://www.teamviewer.com/en/global/support/knowledge-base/teamviewer-classic/integrations/core-integrations/active-directory-connector-ad-connector/?id=31158-active-directory-connector-ad-connector)".

## Download

You can download the AD Connector package from the [GitHub releases page](https://github.com/teamviewer/AD-Connector/releases).
The package contains the `TeamViewerADC` module folder.

## Prerequisites

The AD Connector requires the [TeamViewerPS](https://github.com/teamviewer/TeamViewerPS) module for the TeamViewer web API calls.
Install it with `Invoke-TeamViewerADCTeamViewerPSInstallation` (or check its presence with `Test-TeamViewerADCTeamViewerPS`).

## Installation

Extract the downloaded package to a writable location and import the module:

```powershell
Import-Module .\TeamViewerADC\TeamViewerADC.psd1
```

List the available commands and their help:

```powershell
Get-Command -Module TeamViewerADC
Get-Help -Full Invoke-TeamViewerADCSynchronization
```

The module exports the following commands:

- `Invoke-TeamViewerADCConfiguration` - graphical configuration interface.
- `Invoke-TeamViewerADCSynchronization` - run the synchronization.
- `Invoke-TeamViewerADCLogRotation` - rotate the synchronization log files.
- `Invoke-TeamViewerADCTeamViewerPSInstallation` / `Test-TeamViewerADCTeamViewerPS` - manage the TeamViewerPS dependency.
- `New-TeamViewerADCScheduledTask` / `Remove-TeamViewerADCScheduledTask` - manage the automatic synchronization task.

## Configuration

The module comes with a graphical configuration interface that can be started with the `Invoke-TeamViewerADCConfiguration` command.

The configuration provides the following features:

- Validate the entered TeamViewer API token.
- Show and adapt the synchronization configuration.
- Manually trigger a run of the synchronization.
- Install / uninstall a scheduled task to run the synchronization automatically.

The configuration requires to be run with elevated user rights to be able to install and uninstall the scheduled task.
Start PowerShell as administrator before running `Invoke-TeamViewerADCConfiguration`.

### Configuration Parameters

- Parameter `ApiToken`:

  The TeamViewer API access token that is used for accessing the user / user group data on TeamViewer side.
  For more information on how to create such a token please visit: [TeamViewer for developers](https://www.teamviewer.com/en/global/support/for-developers/)

  The TeamViewer API token requires the following access permissions:

  - _User management_: _Create users, view users, edit users_ (corresponds to the web API permissions `Users.CreateUsers`, `Users.Read`, `Users.ModifyUsers`)
  - (optional) _Account management_: _View full profile_ (corresponds to the web API permissions `Account.Read`, `Account.ReadEmail`. Used to skip possible deactivation of API token owner.)
  - (optional) _Group management_: _View, create, delete, edit and share groups_
  - (optional) _User group management_: _View, create, delete and edit groups_. Required when user group synchronization is enabled.

- Parameter `ActiveDirectoryGroups`:

  The LDAP identifiers (without the leading `LDAP://` protocol scheme) of the Active Directory user groups used for the synchronization.

- Parameter `UserLanguage`:

  The two-letter language identifier used as default language for newly created TeamViewer users.
  For example it is used to localize the "User welcome" email.

- Parameter `UseDefaultPassword`:

  If set to `true` TeamViewer users will be created with the initial password specified by the `DefaultPassword` parameter.
  This parameter cannot be used in conjunction with the `UseSsoCustomerId` or `UseGeneratedPassword` parameters.

- Parameter `DefaultPassword`:

  The initial password used for newly created TeamViewer users.

- Parameter `UseSsoCustomerId`:

  If set to `true` TeamViewer users will be created having Single Sign-On (SSO) already activated.
  Therefore a customer ID needs to be specified in the `SsoCustomerId` parameter.
  This parameter cannot be used in conjunction with the `UseDefaultPassword` or `UseGeneratedPassword` parameters.

- Parameter `SsoCustomerId`:

  The TeamViewer Single Sign-On (SSO) customer identifier.

- Parameter `UseGeneratedPassword`:

  If set to `true` TeamViewer users will be created with a generated password.
  The users will receive an email for resetting their password.

- Parameter `TestRun`:

  If set to `true` the synchronization will **not** modify any TeamViewer user resources but instead only log the actions that would have been executed.

- Parameter `DeactivateUsers`:

  If set to `true` TeamViewer users that are not member of the selected Active Directory user group will be disabled.

- Parameter `RecursiveGroups`:

  If set to `true` users of nested Active Directory user groups will be included.

- Parameter `UseSecondaryEmails`:

  If set to `true` the secondary email addresses configured for an Active Directory user will also be taken into account when trying to map to a TeamViewer user.

- Parameter `EnableUserGroupsSync`:

  If set to `true` the script attempts to synchronize the given Active Directory user groups and their respective users with the TeamViewer user groups.
  Those user groups can then be used to configure TeamViewer functionality, for example: Single Sign-On ownership or exclusions.
  The user groups synchronization step runs after the user sync. This option requires the API token to have additional permissions, see point `ApiToken` above.

### Scheduled Task

Create the scheduled task with `New-TeamViewerADCScheduledTask`. It runs every 24 hours by default; use `-IntervalHours` to specify an interval between 1 and 24 hours.

The scheduled task is registered as:

```powershell
\TeamViewerADC\Automatic Synchronization
```

The task runs the synchronization command as the `NETWORKSERVICE` account. Remove it with `Remove-TeamViewerADCScheduledTask`.

## Synchronization Logic

The actual synchronization is done by the `Invoke-TeamViewerADCSynchronization` command using the following logic:

- Users of the configured Active Directory user group that are not yet part of the configured TeamViewer tenant / company (identified by the API token) will be created with the specified initial password.
- Users of the configured Active Directory user group that are already part of the configured TeamViewer tenant / company will be activated and/or updated if the name of the user has been changed or the TeamViewer user is deactivated.
- If configured, users of the TeamViewer tenant / company that are not present in the configured Active Directory user group will be deactivated.

Identification of users is done based on the email addresses. If configured, the secondary email addresses of Active Directory users are also taken into account for the mapping between Active Directory users and TeamViewer users.

## License

Copyright (c) 2018-2026 TeamViewer Germany GmbH

See file `LICENSE`.
