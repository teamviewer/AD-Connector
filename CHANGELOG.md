# Change Log

## [2.0.0]

- Imported TeamViewerPS module for API calls

## [1.5.0]

- Removed company permissions
- Removed Conditional Access synchronization support (access groups)
- Harmonize code format
- Updated year in copyright

## [1.4.1]

- Fixed missing German translation of TeamViewer user groups synchronization option.

## [1.4.0]

- Added optional synchronization of TeamViewer user groups.

## [1.3.2]

- Fixed bulking of CA group member requests.

## [1.3.1]

- Fixed TeamViewer API calls to use TLS 1.2.

## [1.3.0]

- Added synchronization for TeamViewer Conditional Access directory groups.

## [1.2.2]

- Added hint to options that require TeamViewer Tensor license.
- Fixed escaping of spaces in script path of scheduled task.
- Fixed handling of global catalog names, starting with `GC://`.

## [1.2.1]

- Fixed handling of trailing whitespace in secondary email addresses.
- Fixed possible timeouts in update/deactivate user calls to the TeamViewer Web API on some versions of PowerShell.

## [1.2.0]

- Added configuration field `UseGeneratedPassword` to create user accounts with a generated password. Such users will receive an email to reset their password.
- Added optional lookup for token owner to avoid accidental deactivation of the account that owns the configured API token. This requires additional token permissions.
- Version number is now printed to the log file and title bar.
- Run in graphical user interface can now be cancelled.
- Fixed AD user list to filter-out duplicate users (by email).
- Fixed AD groups list UI to strip possible LDAP hostnames.
- Fixed sorting of account language list.

## [1.1.0]

- Added option `UseSecondaryEmails` to additionally use the user's secondary email addresses for the synchronization.
- Added configuration field `SsoCustomerId` to create user accounts that have Single Sign-On already activated.
- Added text filtering in the Active Directory groups drop-down menu. The filter is applied after typing at least 3 characters.
- Fixed encoding problem when creating or updating TeamViewer accounts.
- Log output now lists changes when updating a user.

## [1.0.0] - Initial Release
