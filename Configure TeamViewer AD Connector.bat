@ECHO OFF
SETLOCAL

CD /D "%~dp0"
POWERSHELL -NonInteractive -NoProfile -ExecutionPolicy Bypass -Command "& {.\TeamViewerADConnector\Invoke-Configuration.ps1 ; exit $LastExitCode }"
