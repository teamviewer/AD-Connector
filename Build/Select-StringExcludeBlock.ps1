
function Select-StringExcludeBlock {
    Param(
        [Parameter(Mandatory = $true)]
        [string] $Begin,

        [Parameter(Mandatory = $true)]
        [string] $End,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $pipelineInput
    )
    Begin {
        $include = $true
        $patternBegin = [Regex]::Escape($Begin)
        $patternEnd = [Regex]::Escape($End)
    }
    Process {
        $pipelineInput | ForEach-Object {
            if ($_ -match $patternBegin) {
                $include = $false
            }
            if ($include) {
                Write-Output $_
            }
            if ($_ -match $patternEnd) {
                $include = $true
            }
        }
    }
}
