#requires -Modules BuildHelpers, Microsoft.PowerShell.PlatyPS

param(
    [Parameter()]
    [string]$Build_OutputPath = "$(Resolve-Path "$PSScriptRoot\..")\Build\TeamViewerADC",

    [Parameter()]
    [version]$Module_Version
)

$Repo_RootPath = Resolve-Path -Path "$PSScriptRoot\.."
$Repo_CmdletPath = Resolve-Path -Path "$PSScriptRoot\..\Cmdlets"

if (Test-Path -Path $Build_OutputPath) {
    Write-Verbose 'Removing existing build output directory...'
    Remove-Item -Path $Build_OutputPath -Recurse -ErrorAction SilentlyContinue
}

Write-Verbose 'Creating build output directories...'
New-Item -Type Directory $Build_OutputPath | Out-Null

# Compile all functions into a single psm file
$Build_ModulePath = (Join-Path -Path $Build_OutputPath -ChildPath 'TeamViewerADC.psm1')

Write-Verbose 'Compiling single-file TeamViewer module...'

$PrivateFunctions = @(Get-ChildItem -Path (Join-Path -Path $Repo_CmdletPath -ChildPath 'Private\*.ps1') -ErrorAction SilentlyContinue)
Write-Verbose "Found $($PrivateFunctions.Count) private function files."

$PublicFunctions = @(Get-ChildItem -Path (Join-Path -Path $Repo_CmdletPath -ChildPath 'Public\*.ps1') -ErrorAction SilentlyContinue)
Write-Verbose "Found $($PublicFunctions.Count) public function files."

@($PrivateFunctions + $PublicFunctions) | Get-Content -Raw | ForEach-Object { $_; "`r`n" } | Set-Content -Path $Build_ModulePath -Encoding UTF8

# Create help from markdown
Write-Verbose 'Building help from Markdown...'
$Help_Command = @(Measure-PlatyPSMarkdown -Path (Join-Path -Path $Repo_RootPath -ChildPath 'Docs\Help\*.md') |
    Where-Object -Property Filetype -Match 'CommandHelp' | ForEach-Object { Import-MarkdownCommandHelp -Path $_.FilePath })

$Help_OutputPath = Join-Path -Path $Build_OutputPath -ChildPath 'en-US'
$Help_ModulePath = Join-Path -Path $Help_OutputPath -ChildPath 'TeamViewerADC'
$Help_Command | Export-MamlCommandHelp -OutputFolder $Help_OutputPath | Out-Null

Move-Item -LiteralPath (Join-Path -Path $Help_ModulePath -ChildPath 'TeamViewerADC-help.xml') -Destination $Help_OutputPath
Remove-Item -Path $Help_ModulePath -Recurse

# Create module manifest
Write-Verbose 'Creating module manifest...'
Copy-Item -Path (Join-Path -Path $Repo_CmdletPath -ChildPath 'TeamViewerADC.psd1') -Destination $Build_OutputPath

Update-Metadata -Path (Join-Path -Path $Build_OutputPath -ChildPath 'TeamViewerADC.psd1') -PropertyName 'FunctionsToExport' -Value $PublicFunctions.BaseName

if ($PSBoundParameters.ContainsKey('Module_Version')) {
    Update-Metadata -Path (Join-Path -Path $Build_OutputPath -ChildPath 'TeamViewerADC.psd1') -PropertyName 'ModuleVersion' -Value $Module_Version
}

# Copy additional package files
Write-Verbose 'Copying additional files into the package...'
Copy-Item -Path (Join-Path -Path $Repo_RootPath -ChildPath 'CHANGELOG.md') -Destination "$Build_OutputPath"
Copy-Item -Path (Join-Path -Path $Repo_RootPath -ChildPath 'LICENSE.md') -Destination "$Build_OutputPath"
Copy-Item -Path (Join-Path -Path $Repo_RootPath -ChildPath 'README.md') -Destination "$Build_OutputPath"

Write-Verbose 'Listing package files:'
Push-Location -Path $Build_OutputPath
Get-ChildItem -Path "$Build_OutputPath\" -Recurse | Sort-Object -Property FullName | Resolve-Path -Relative
Pop-Location
