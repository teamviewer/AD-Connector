BeforeAll {
    . "$PSScriptRoot\..\..\Cmdlets\Private\Resolve-TeamViewerADCTeamViewerAccount.ps1"
}

Describe 'Resolve-TeamViewerADCTeamViewerAccount' {
    BeforeAll {
        $script:SyncContext = [pscustomobject]@{
            TeamViewerUsersByEmail = @{
                'primary@example.com'   = [pscustomobject]@{ id = 'primary' }
                'secondary@example.com' = [pscustomobject]@{ id = 'secondary' }
            }
        }
    }

    It 'declares required parameters and supports pipeline input' {
        $CommandInfo = Get-Command -Name Resolve-TeamViewerADCTeamViewerAccount
        $ADUserParameter = $CommandInfo.Parameters['AD_User']

        $CommandInfo.CmdletBinding | Should -BeTrue
        $CommandInfo.Parameters.Keys | Should -Contain 'Sync_Context'
        $CommandInfo.Parameters.Keys | Should -Contain 'Configuration'
        $CommandInfo.Parameters.Keys | Should -Contain 'AD_User'
        @($ADUserParameter.Attributes | Where-Object { $_.ValueFromPipeline }).Count | Should -Be 1
        @($ADUserParameter.Attributes | Where-Object { $_.Mandatory }).Count | Should -Be 1
        @($CommandInfo.Parameters.Values | ForEach-Object { $_.Attributes } | Where-Object { $_.Mandatory }).Count | Should -Be 3
        @($CommandInfo.Parameters.Values | ForEach-Object { $_.Attributes } | Where-Object { $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] }).Count | Should -Be 3
    }

    It 'resolves a user by primary email' {
        $ADUser = [pscustomobject]@{ Email = 'primary@example.com'; SecondaryEmails = @() }
        $Configuration = [pscustomobject]@{ UseSecondaryEmails = $true }

        $Result = $ADUser | Resolve-TeamViewerADCTeamViewerAccount -Sync_Context $script:SyncContext -Configuration $Configuration

        $Result.id | Should -Be 'primary'
    }

    It 'resolves a user by secondary email when enabled' {
        $ADUser = [pscustomobject]@{ Email = 'missing@example.com'; SecondaryEmails = @('secondary@example.com') }
        $Configuration = [pscustomobject]@{ UseSecondaryEmails = $true }

        $Result = $ADUser | Resolve-TeamViewerADCTeamViewerAccount -Sync_Context $script:SyncContext -Configuration $Configuration

        $Result.id | Should -Be 'secondary'
    }

    It 'does not use secondary email when disabled' {
        $ADUser = [pscustomobject]@{ Email = 'missing@example.com'; SecondaryEmails = @('secondary@example.com') }
        $Configuration = [pscustomobject]@{ UseSecondaryEmails = $false }

        $Result = $ADUser | Resolve-TeamViewerADCTeamViewerAccount -Sync_Context $script:SyncContext -Configuration $Configuration

        $Result | Should -BeNullOrEmpty
    }

    It 'returns no result when no email matches' {
        $ADUser = [pscustomobject]@{ Email = 'missing@example.com'; SecondaryEmails = @('also-missing@example.com') }
        $Configuration = [pscustomobject]@{ UseSecondaryEmails = $true }

        $Result = $ADUser | Resolve-TeamViewerADCTeamViewerAccount -Sync_Context $script:SyncContext -Configuration $Configuration

        $Result | Should -BeNullOrEmpty
    }

    It 'prefers the primary email over secondary emails' {
        $ADUser = [pscustomobject]@{ Email = 'primary@example.com'; SecondaryEmails = @('secondary@example.com') }
        $Configuration = [pscustomobject]@{ UseSecondaryEmails = $true }

        $Result = $ADUser | Resolve-TeamViewerADCTeamViewerAccount -Sync_Context $script:SyncContext -Configuration $Configuration

        $Result.id | Should -Be 'primary'
    }

    It 'resolves each user supplied through the pipeline' {
        $ADUsers = @(
            [pscustomobject]@{ Email = 'primary@example.com'; SecondaryEmails = @() }
            [pscustomobject]@{ Email = 'missing@example.com'; SecondaryEmails = @('secondary@example.com') }
        )
        $Configuration = [pscustomobject]@{ UseSecondaryEmails = $true }

        $Results = @($ADUsers | Resolve-TeamViewerADCTeamViewerAccount -Sync_Context $script:SyncContext -Configuration $Configuration)

        $Results.Count | Should -Be 2
        $Results.id | Should -Be @('primary', 'secondary')
    }
}
