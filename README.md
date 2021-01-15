# TeamViewer Active Directory Connector (AD-Connector)

A PowerShell integration script to synchronize users of an Active Directory (AD) group to a TeamViewer company via REST based API.

<!--[+github]-->
[![Build Status](https://travis-ci.org/TeamViewer/AD-Connector.svg?branch=master)](https://travis-ci.org/TeamViewer/AD-Connector)
<!--[-github]-->

Further information can be found in the knowledge base article "[Active Directory Connector](https://community.teamviewer.com/t5/Knowledge-Base/Active-Directory-Connector-AD-Connector/ta-p/31158)".

## Download

You can download the AD-Connector package from our [website](https://www.teamviewer.com/en/integrations/active-directory/).

## Configuration

The script comes with a configuration user interface that can be started
by executing the `Invoke-Configuration.ps1` PowerShell script in the
`TeamViewerADConnector` directory.
It can also be started simply by double-clicking the
`Configure TeamViewer AD Connector.bat` file.

The configuration UI provides the following features:

- Show and adapt the sync configuration.
- Validate the entered TeamViewer API token.
- Manually trigger a run of the synchronization script.
- Install/Uninstall a scheduled task to run the synchronization script
  automatically.

The configuration UI requires to be run with elevated user rights to be
able to install and uninstall the scheduled task. The script
automatically asks for elevated rights (if required).

### Available Configuration Parameters

* Parameter `ApiToken`:

  The TeamViewer API access token that is used for accessing the
  TeamViewer company user directory. For more information on how to
  create such a token please visit:
  https://www.teamviewer.com/en/for-developers/teamviewer-api/

  The TeamViewer API token requires the following access permissions:

  - _User management_: _Create users, view users, edit users_
    (corresponds to the WebAPI permissions
     `Users.CreateUsers`, `Users.Read`, `Users.ModifyUsers`)
  - (optional) _Account management_: _View full profile_
    (corresponds to the WebAPI permissions
     `Account.Read`, `Account.ReadEmail`.
     Used to skip possible deactivation of API token owner.)
  - (optional) _Group management_: _View, create, delete, edit and share groups_
     Required when conditional access synchronization is enabled.

* Parameter `ActiveDirectoryGroups`:

  The LDAP identifiers (without the leading `LDAP://` protocol scheme)
  of the AD groups used for the synchronization.

* Parameter `UserLanguage`:

  The two-letter language identifier used as default language for newly
  created TeamViewer users. For example it is used to localize the
  "Welcome" email.

* Parameter `UseDefaultPassword`:

  If set to `true` TeamViewer users will be created with the initial
  password specified by the `DefaultPassword` parameter.
  This parameter cannot be used in conjunction with the
  `UseSsoCustomerId` or `UseGeneratedPassword` parameters.

* Parameter `DefaultPassword`:

  The initial password used for newly created TeamViewer users.

* Parameter `UseSsoCustomerId`:

  If set to `true` TeamViewer users will be created having Single
  Sign-On already activated. Therefore a customer ID needs to be
  specified in the `SsoCustomerId` parameter.
  This parameter cannot be used in conjunction with the
  `UseDefaultPassword` or `UseGeneratedPassword` parameters.

* Parameter `SsoCustomerId`:

  The TeamViewer Single Sign-On customer identifier.

* Parameter `UseGeneratedPassword`:

  If set to `true` TeamViewer users will be created with a generated
  password. The users will receive an email for resetting their
  password.

* Parameter `TestRun`:

  If set to `true` the synchronization will **not** modify any
  TeamViewer user resources but instead only log the actions that would
  have been executed.

* Parameter `DeactivateUsers`:

  If set to `true` TeamViewer users that are not member of the selected
  AD group will be disabled.

* Parameter `RecursiveGroups`:

  If set to `true` users of nested AD groups will be included.

* Parameter `UseSecondaryEmails`:

  If set to `true` the secondary email addresses configured for an AD
  user will also be taken into account when trying to map to a
  TeamViewer user.

* Parameter `EnableConditionalAccessSync`:

  If set to `true` the script attempts to synchronise the given AD groups and
  their respective users with the directory groups for _conditional access_ in
  TeamViewer. Those groups can then be used to restrict/allow TeamViewer
  functionality for certain users.
  The conditional access synchronization step runs after the user sync.
  This option requires the API token to have additional permissions.
  See point `ApiToken` above.


### Scheduled Task

The scheduled task will be created with the specified interval as:
```
\TeamViewer\TeamViewer AD Connector
```

Output of the scheduled task is redirected to the specified log file
location.


## User Synchronization Logic

The actual synchronization is done by the `Invoke-Sync.ps1` script in
the `TeamViewerADConnector` directory using the following logic:

* Users of the configured AD group that are not yet part of the
  configured TeamViewer company (identified by the API token) will be
  created with the specified initial password.
* Users of the configured AD group that are already part of the
  configured TeamViewer company will be activated and/or updated if the
  name of the user has been changed or the TeamViewer user is
  deactivated.
* If configured, users of the TeamViewer company that are not present in
  the configured AD group will be deactivated.

Identification of users is done based on the email addresses.
If configured, the secondary email addresses of AD users are also taken
into account for the mapping between AD users and TeamViewer users.


## License

Copyright (c) 2018-2020 TeamViewer GmbH

See file `LICENSE`.
