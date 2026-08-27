BeforeAll {
    $Script:Module_RootPath = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..'))
    $Script:Module_FilePath = (Get-ChildItem -Path (Join-Path -Path $Module_RootPath -ChildPath 'Cmdlets') -Filter '*.psm1' -File).FullName
    $Script:Module_ManifestFilePath = (Get-ChildItem -Path (Join-Path -Path $Module_RootPath -ChildPath 'Cmdlets') -Filter '*.psd1' -File).FullName
    $Script:Module_ManifestData = Import-PowerShellDataFile -Path $Module_ManifestFilePath
    $Script:Module_Name = (Split-Path -Path $Module_FilePath -Leaf).Replace('.psm1', '')
}

Context 'Test-ManifestFile' {
    It 'Valid module folder artifacts' {
        @(Get-ChildItem -Path (Join-Path -Path $Module_RootPath -ChildPath 'Cmdlets') -Filter '*.psm1' -File).Count | Should -Be 1
        @(Get-ChildItem -Path (Join-Path -Path $Module_RootPath -ChildPath 'Cmdlets') -Filter '*.psd1' -File).Count | Should -Be 1
    }

    It 'Valid module manifest file' {
        $Module_ManifestFilePath | Should -Exist

        {
            $Script:Module_Manifest = Test-ModuleManifest -Path $Module_ManifestFilePath -ErrorAction Stop
        } | Should -Not -Throw
    }

    It 'Valid manifest root module' {
        $Module_Manifest.RootModule | Should -Be "$Module_Name.psm1"
    }

    It 'Valid version check' {
        $Module_Manifest.Version -as [Version] | Should -Not -BeNullOrEmpty
    }

    It 'Valid manifest GUID' {
        $Module_Manifest.Guid | Should -Be 'b2c9f0a4-7e3d-4f6a-9c1b-2d5e8a4f10c7'
    }

    It 'Valid manifest author' {
        $Module_Manifest.Author | Should -Be 'TeamViewer Germany GmbH'
    }

    It 'Valid manifest company' {
        $Module_Manifest.CompanyName | Should -Be 'TeamViewer Germany GmbH'
    }

    It 'Valid manifest description' {
        $Module_Manifest.Description | Should -BeLike "$Module_Name*"
    }

    It 'Valid manifest module file reference' {
        $modulePath = Join-Path -Path (Join-Path -Path $Module_RootPath -ChildPath 'Cmdlets') -ChildPath $Module_Manifest.RootModule
        $modulePath | Should -Exist
    }

    It 'Valid manifest format file references' {
        foreach ($formatFile in $Module_ManifestData.FormatsToProcess) {
            $formatFilePath = Join-Path -Path (Join-Path -Path $Module_RootPath -ChildPath 'Cmdlets') -ChildPath $formatFile
            $formatFilePath | Should -Exist
        }
    }

    It 'Valid manifest minimum PowerShell version' {
        $Module_Manifest.PowerShellVersion -as [Version] | Should -Not -BeNullOrEmpty
    }

    It 'Valid manifest PSData tags' {
        $Module_Manifest.PrivateData.PSData.Tags | Should -Not -BeNullOrEmpty
    }

    It 'Valid manifest project and license URIs' {
        $projectUri = [Uri]$Module_Manifest.PrivateData.PSData.ProjectUri
        $licenseUri = [Uri]$Module_Manifest.PrivateData.PSData.LicenseUri

        $projectUri.IsAbsoluteUri | Should -Be $true
        $licenseUri.IsAbsoluteUri | Should -Be $true
    }
}

<# Context 'Import module' {
    It "Module ($Module_Name) can be imported" {
        $Module_FilePath | Should -Exist

        { Import-Module $Module_FilePath -Force } | Should Not Throw
    }
} #>
