@echo off
setlocal

cd /D "%~dp0"
powershell -NonInteractive -NoProfile -ExecutionPolicy bypass -Command "& {.\TeamViewerADConnector\Invoke-Configuration.ps1 ; exit $LastExitCode }"
