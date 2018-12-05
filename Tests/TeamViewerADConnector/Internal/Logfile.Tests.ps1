# Copyright (c) 2018 TeamViewer GmbH
# See file LICENSE

. "$PSScriptRoot\..\..\..\TeamViewerADConnector\Internal\Logfile.ps1"

Describe 'Invoke-LogfileRotation' {

    function Add-TestFile($path, $creationTime) {
        New-Item $path -ItemType File
        (Get-ChildItem $path).CreationTime = $creationTime
    }

    It 'Should rollover old files' {
        Add-TestFile 'TestDrive:\LogTest1.log' '2018/01/01 00:00:00'
        Add-TestFile 'TestDrive:\LogTest2.log' '2018/01/01 01:00:00'
        Add-TestFile 'TestDrive:\LogTest4.log' '2018/01/01 02:00:00' # Rollover by creation time
        Add-TestFile 'TestDrive:\LogTest3.log' '2018/01/01 03:00:00' # and not by filename sort
        Add-TestFile 'TestDrive:\LogTest5.log' '2018/01/01 04:00:00'
        Invoke-LogfileRotation 'TestDrive:\' 'LogTest' 3
        (Get-ChildItem 'TestDrive:\').Length | Should -Be 3
        (Test-Path 'TestDrive:\LogTest1.log') | Should -Be $false
        (Test-Path 'TestDrive:\LogTest2.log') | Should -Be $false
        (Test-Path 'TestDrive:\LogTest3.log') | Should -Be $true
        (Test-Path 'TestDrive:\LogTest4.log') | Should -Be $true
        (Test-Path 'TestDrive:\LogTest5.log') | Should -Be $true
    }
}
