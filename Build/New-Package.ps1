param(
    [Parameter(Mandatory = $true)]
    [String] $Path,

    [Parameter(Mandatory = $true)]
    [String] $Destination,

    [Parameter(Mandatory = $true)]
    [String] $Version
)

$script:ErrorActionPreference = 'Stop'
$global:ProgressPreference = 'SilentlyContinue'
Add-Type -assembly "system.io.compression.filesystem"

$Path = (Resolve-Path $Path)
Push-Location -Path $Path
$temporaryDirectory = (Join-Path ([System.IO.Path]::GetTempPath()) ([string][System.Guid]::NewGuid()))
(New-Item -ItemType Directory -Path $temporaryDirectory) | Out-Null

# HTML Readme File
ConvertTo-Html `
    -Title (Get-Content ./README.md -First 1).Trim('# ') `
    -PreContent (Get-Content ./Build/README.style.html | Out-String) `
    -Body (Get-Content ./README.md | Out-String | ConvertFrom-Markdown) | `
    Set-Content (Join-Path $temporaryDirectory README.html)

# Prepare package files
Copy-Item ./TeamViewerADConnector -Destination $temporaryDirectory -Recurse
Copy-Item ./LICENSE.txt -Destination $temporaryDirectory
Copy-Item ./README.md -Destination $temporaryDirectory
Copy-Item ./*.bat -Destination $temporaryDirectory

# Set script version
(Get-ChildItem -Recurse $temporaryDirectory/**/*.ps1) | `
    ForEach-Object { `
        (Get-Content $_) | `
        ForEach-Object { $_ -replace "{ScriptVersion}","$Version" } | `
        Set-Content $_ `
    }

# Compress package
Compress-Archive -Force `
    -Path $temporaryDirectory/* `
    -DestinationPath $Destination

Remove-Item $temporaryDirectory -Force -Recurse -ErrorAction SilentlyContinue
Pop-Location
