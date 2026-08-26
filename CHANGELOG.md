# Change Log

## x.x.x (YYYY-xx-xx)

### Added

- Adds translations for `es`, `fr`, and `it`.
- Adds `AGENTS.md` file for AI coding agents.
- Imports `TeamViewerPS` PowerShell module for API calls.
- Adds a setting for the TeamViewer API environment to the configuration.

### Changed

- Packages the TeamViewer Active Directory Connector as the `TeamViewerADC` PowerShell module.

## 1.5.0

### Changed

- Updates year in copyright.

### Removed

- Removes company permissions.
- Removes Conditional Access synchronization support (access groups).

## 1.4.1

### Fixed

- Fixes missing German translation of the TeamViewer user groups synchronization option.

## 1.4.0

### Added

- Adds optional synchronization of TeamViewer user groups.

## 1.3.2

### Fixed

- Fixes bulking of Conditional Access group member requests.

## 1.3.1

### Fixed

- Fixes TeamViewer API calls to use TLS 1.2.

## 1.3.0

### Added

- Adds synchronization for TeamViewer Conditional Access directory groups.

## 1.2.2

### Added

- Adds hint to configurations that require a TeamViewer Tensor license.

### Fixed

- Fixes escaping of spaces in script path of scheduled task.
- Fixes handling of global catalog names, starting with `GC://`.

## 1.2.1

### Fixed

- Fixes handling of trailing whitespace in secondary email addresses.
- Fixes possible timeouts in update/deactivate user calls to the TeamViewer API on some versions of PowerShell.

## 1.2.0

### Added

- Adds configuration field `UseGeneratedPassword` to create user accounts with a generated password. Such users will receive an email to reset their password.
- Adds optional lookup for token owner to avoid accidental deactivation of the account that owns the configured API token. This requires additional token permissions.

### Changed

- Adds `version number` to the log file and title bar.
- Run in graphical user interface can now be cancelled.

### Fixed

- Fixes Active Directory user list to filter-out duplicate users by email.
- Fixes Active Directory user groups list GUI to strip possible LDAP hostnames.
- Fixes sorting of account language list.

## 1.1.0

### Added

- Adds option `UseSecondaryEmails` to additionally use the user's secondary email addresses for the synchronization.
- Adds configuration field `SsoCustomerId` to create user accounts that have Single Sign-On (SSO) already activated.
- Adds text filtering in the Active Directory groups drop-down menu. The filter is applied after typing at least 3 characters.

### Fixed

- Fixes encoding problem when creating or updating TeamViewer accounts.
- Log output now lists changes when updating a user.

## 1.0.0

- Initial release of TeamViewer Active Directory Connector.
