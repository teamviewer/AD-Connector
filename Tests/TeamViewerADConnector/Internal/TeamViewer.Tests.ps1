# Copyright (c) 2018 TeamViewer GmbH
# See file LICENSE

. "$PSScriptRoot\..\..\..\TeamViewerADConnector\Internal\TeamViewer.ps1"

Describe 'Invoke-TeamViewerRestMethod' {

    It 'Should pass through arguments and result' {
        Mock -CommandName Invoke-RestMethod -MockWith { return 123 }
        Invoke-TeamViewerRestMethod -Uri 'https://example.test' -Method Get | Should -Be 123
        Assert-MockCalled Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -And $Uri -eq 'https://example.test' -And
            $Method -And $Method -eq 'Get'
        }
    }

    It 'Should convert error payload' {
        $testError = (@{ message = 'Some Error'})
        Mock -CommandName Invoke-RestMethod -MockWith { Throw ($testError | ConvertTo-Json) }
        Mock -CommandName ConvertTo-TeamViewerRestError -MockWith { return $testError }
        { Invoke-TeamViewerRestMethod -Uri 'https://example.test' -Method Get } | Should -Throw $testError
        Assert-MockCalled Invoke-RestMethod -Times 1
        Assert-MockCalled ConvertTo-TeamViewerRestError -Times 1
    }

    It 'Should call Invoke-WebRequest for PUT and DELETE methods' {
        Mock -CommandName Invoke-RestMethod -MockWith { return 123 }
        Mock -CommandName Invoke-WebRequest -MockWith { return @{Content = '{"value":456}'} }
        Invoke-TeamViewerRestMethod -Uri 'https://example.test' -Method Get | Should -Be 123
        Invoke-TeamViewerRestMethod -Uri 'https://example.test' -Method Post | Should -Be 123
        (Invoke-TeamViewerRestMethod -Uri 'https://example.test' -Method Put).value | Should -Be 456
        (Invoke-TeamViewerRestMethod -Uri 'https://example.test' -Method Delete).value | Should -Be 456
        Assert-MockCalled Invoke-RestMethod -Times 2 -Scope It
        Assert-MockCalled Invoke-WebRequest -Times 2 -Scope It
    }
}

Describe 'Invoke-TeamViewerPing' {

    It 'Should call the API ping REST endpoint' {
        Mock -CommandName Invoke-RestMethod -MockWith { return @{token_valid = $true} }
        Invoke-TeamViewerPing 'TestAccessToken' | Should Be $true
        Assert-MockCalled Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -And [System.Uri]$Uri.PathAndQuery -eq '/api/v1/ping' -And
            $Method -And $Method -eq 'Get'
        }
    }

    It 'Should return false for invalid tokens' {
        Mock -CommandName Invoke-RestMethod -MockWith { return @{token_valid = $false} }
        Invoke-TeamViewerPing 'TestAccessToken' | Should Be $false
    }

    It 'Should set the authorization header' {
        Mock -CommandName Invoke-RestMethod -MockWith { return @{token_valid = $true} }
        Invoke-TeamViewerPing 'TestAccessToken'
        Assert-MockCalled Invoke-RestMethod -Times 1 -ParameterFilter {
            $Headers -And $Headers.ContainsKey('authorization') -And $Headers.authorization -eq 'Bearer TestAccessToken'
        }
    }
}

Describe 'Get-TeamViewerUser' {

    Mock -CommandName Invoke-RestMethod -MockWith { return @{
            'users' = @(
                @{ email = 'test1@example.test'; name = 'Test User1' },
                @{ email = 'test2@example.test'; name = 'Test User2' },
                @{ email = 'test3@example.test'; name = 'Test User3' }
            )
        }}

    It 'Should call the API users endpoint' {
        Get-TeamViewerUser 'TestAccessToken'
        Assert-MockCalled Invoke-RestMethod -Times 1 -Scope It -ParameterFilter {
            $Uri -And [System.Uri]$Uri.PathAndQuery -eq '/api/v1/users' -And
            $Method -And $Method -eq 'Get'
        }
    }

    It 'Should return a dictionary of users by their email addresses' {
        $result = (Get-TeamViewerUser 'TestAccessToken')
        $result.Keys | Should -Contain 'test1@example.test'
        $result.Keys | Should -Contain 'test2@example.test'
        $result.Keys | Should -Contain 'test3@example.test'
        $result['test1@example.test'].Keys | Should -Contain 'name'
        $result['test1@example.test'].name | Should -Be 'Test User1'
    }

    It 'Should set the authorization header' {
        Get-TeamViewerUser 'TestAccessToken'
        Assert-MockCalled Invoke-RestMethod -Times 1 -Scope It -ParameterFilter {
            $Headers -And $Headers.ContainsKey('authorization') -And $Headers.authorization -eq 'Bearer TestAccessToken'
        }
    }
}

Describe 'Add-TeamViewerUser' {

    $testUser = @{ 'name' = 'Test User 1'; 'email' = 'test1@example.test' }
    $lastMockParams = @{}
    Mock -CommandName Invoke-RestMethod -MockWith {
        $lastMockParams.Body = $Body
        return $testUser
    }

    It 'Should call the API users endpoint' {
        $input = @{ 'name' = 'Test User 1'; 'email' = 'test1@example.test'; 'language' = 'en' }
        Add-TeamViewerUser 'TestAccessToken' $input | Should -Be $testUser
        Assert-MockCalled Invoke-RestMethod -Times 1 -Scope It -ParameterFilter {
            $Uri -And [System.Uri]$Uri.PathAndQuery -eq '/api/v1/users' -And
            $Method -And $Method -eq 'Post'
        }
    }

    It 'Should throw if required fields are missing' {
        $inputs = @(
            @{ 'email' = 'test1@example.test'; 'language' = 'en' }, # missing 'name'
            @{ 'name' = 'Test User 1'; 'language' = 'en' }, # missing 'email'
            @{ 'name' = 'Test User 1'; 'email' = 'test1@example.test' } # missing 'language'
        )
        $inputs | ForEach-Object { { Add-TeamViewerUser 'TestAccessToken' $_ } | Should -Throw }
    }

    It 'Should encode the payload using UTF-8' {
        $input = @{ 'name' = 'Test User Müller'; 'email' = 'test1@example.test'; 'language' = 'en' }
        Add-TeamViewerUser 'TestAccessToken' $input
        Assert-MockCalled Invoke-RestMethod -Times 1 -Scope It -ParameterFilter { $Body }
        { [System.Text.Encoding]::UTF8.GetString($lastMockParams.Body) } | Should -Not -Throw
        { [System.Text.Encoding]::UTF8.GetString($lastMockParams.Body) | ConvertFrom-Json } | Should -Not -Throw
        ([System.Text.Encoding]::UTF8.GetString($lastMockParams.Body) | ConvertFrom-Json).name | Should -Be 'Test User Müller'
    }

    It 'Should set the authorization header' {
        $input = @{ 'name' = 'Test User 1'; 'email' = 'test1@example.test'; 'language' = 'en' }
        Add-TeamViewerUser 'TestAccessToken' $input
        Assert-MockCalled Invoke-RestMethod -Times 1 -Scope It -ParameterFilter {
            $Headers -And $Headers.ContainsKey('authorization') -And $Headers.authorization -eq 'Bearer TestAccessToken'
        }
    }
}

Describe 'Edit-TeamViewerUser' {

    $testUser = @{ 'id' = '1234'; 'name' = 'Test User 1'; 'email' = 'test1@example.test' }
    Mock -CommandName Invoke-WebRequest -MockWith { return @{Content = $testUser | ConvertTo-Json} }

    It 'Should call the API users endpoint' {
        $input = @{ 'name' = 'Test User 1'; 'email' = 'test1@example.test' }
        $result = (Edit-TeamViewerUser 'TestAccessToken' 1234 $input)
        $result.id | Should -Be $testUser.id
        $result.name | Should -Be $testUser.name
        Assert-MockCalled Invoke-WebRequest -Times 1 -Scope It -ParameterFilter {
            $Uri -And [System.Uri]$Uri.PathAndQuery -eq '/api/v1/users/1234' -And
            $Method -And $Method -eq 'Put'
        }
    }

    It 'Should set the authorization header' {
        $input = @{ 'name' = 'Test User 1'; 'email' = 'test1@example.test' }
        Edit-TeamViewerUser 'TestAccessToken' 1234 $input
        Assert-MockCalled Invoke-WebRequest -Times 1 -Scope It -ParameterFilter {
            $Headers -And $Headers.ContainsKey('authorization') -And $Headers.authorization -eq 'Bearer TestAccessToken'
        }
    }
}

Describe 'Disable-TeamViewerUser' {

    $lastMockParams = @{}
    Mock -CommandName Invoke-WebRequest -MockWith {
        $lastMockParams.Body = $Body
        return @{Content = ""}
    }

    It 'Should call the API users endpoint' {
        Disable-TeamViewerUser 'TestAccessToken' 1234
        Assert-MockCalled Invoke-WebRequest -Times 1 -Scope It -ParameterFilter {
            $Uri -And [System.Uri]$Uri.PathAndQuery -eq '/api/v1/users/1234' -And
            $Method -And $Method -eq 'Put'
        }
    }

    It 'Should set the payload parameter active to false' {
        Disable-TeamViewerUser 'TestAccessToken' 1234
        { [System.Text.Encoding]::UTF8.GetString($lastMockParams.Body) | ConvertFrom-Json } | Should -Not -Throw
        ([System.Text.Encoding]::UTF8.GetString($lastMockParams.Body) | ConvertFrom-Json).active | Should -Be $false
    }

    It 'Should set the authorization header' {
        Disable-TeamViewerUser 'TestAccessToken' 1234
        Assert-MockCalled Invoke-WebRequest -Times 1 -Scope It -ParameterFilter {
            $Headers -And $Headers.ContainsKey('authorization') -And $Headers.authorization -eq 'Bearer TestAccessToken'
        }
    }
}

Describe 'Get-TeamViewerAccount' {
    It 'Should call the API account endpoint' {
        Mock -CommandName Invoke-RestMethod -MockWith {}
        Get-TeamViewerAccount 'TestAccessToken'
        Assert-MockCalled Invoke-RestMethod -Times 1 -Scope It -ParameterFilter {
            $Uri -And [System.Uri]$Uri.PathAndQuery -eq '/api/v1/account' -And
            $Method -And $Method -eq 'Get'
        }
    }

    It 'Should set the authorization header' {
        Mock -CommandName Invoke-RestMethod -MockWith {}
        Get-TeamViewerAccount 'TestAccessToken'
        Assert-MockCalled Invoke-RestMethod -Times 1 -Scope It -ParameterFilter {
            $Headers -And $Headers.ContainsKey('authorization') -And $Headers.authorization -eq 'Bearer TestAccessToken'
        }
    }

    It 'Should throw on error if parameter NoThrow is not set' {
        Mock -CommandName Invoke-RestMethod -MockWith { Throw 'failure' }
        { Get-TeamViewerAccount 'TestAccessToken' } | Should -Throw
    }

    It 'Should not throw on error if parameter NoThrow is set' {
        Mock -CommandName Invoke-RestMethod -MockWith { Throw 'failure' }
        { Get-TeamViewerAccount 'TestAccessToken' -NoThrow } | Should -Not -Throw
    }
}
