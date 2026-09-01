function Get-TVADCGuiLocale {
    [CmdletBinding()]

    [OutputType([psobject])]

    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]
        $Culture = 'en'
    )

    begin {
        $Locales = @{}

        Get-ChildItem "$PSScriptRoot\Localization\GraphicalUserInterface.*.json" -File | ForEach-Object {
            $Locales[($_.BaseName -split '\.', 2)[1]] = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        }
    }

    process {
        $Locale = $Locales[$Culture]
        if (-not $Locale) {
            $Locale = $Locales.en
        }

        $Locale
    }
}
