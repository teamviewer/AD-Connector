# Copyright (c) 2018-2021 TeamViewer Germany GmbH
# See file LICENSE

function Invoke-LogfileRotation($folder, $basename, $retentionCount) {
    $files = [array](Get-ChildItem -Path (Join-Path $folder "$basename*.log") -File `
            | Sort-Object LastWriteTimeUtc, CreationTimeUtc, FullName)
    while ($files.Count -gt $retentionCount) {
        Remove-Item $files[0]
        $files = $files[1..($files.Count - 1)]
    }
}

function Out-Logfile($folder, $basename) {
    Begin {
        $filename = (Join-Path $folder "$($basename)$("{0:yyyy-MM-dd}" -f (Get-Date)).log")
    }
    Process {
        $_ | Out-File -Append -FilePath $filename
    }
}
