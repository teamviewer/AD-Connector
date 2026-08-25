function Split-TeamViewerADCUserGroupMemberId {
    [CmdletBinding()]

    [OutputType([System.Array])]

    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Size = 100
    )

    begin {
        $Bulk = New-Object System.Collections.ArrayList($Size)
    }

    process {
        $Bulk.Add($InputObject) | Out-Null; if ($Bulk.Count -ge $Size) {
            , $Bulk.Clone(); $Bulk.Clear()
        }
    }

    end {
        if ($Bulk.Count -gt 0) {
            , $Bulk
        }
    }
}
