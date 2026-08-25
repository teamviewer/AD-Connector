@ECHO OFF
TITLE %~n0

SET "Repo_RootPath=%~dp0"
SET "TVPSInstaller_ScriptFilePath=%Repo_RootPath%TeamViewerADConnector\Invoke-TeamViewerPSInstallation.ps1"

IF NOT EXIST "%TVPSInstaller_ScriptFilePath%" (
	ECHO PowerShell script "%TVPSInstaller_ScriptFilePath% doesn't exist!"

	EXIT /B 1
) ELSE (
    REM TODO: Rename "TeamViewerADConnector.config.json" to "TeamViewerADC.json" if exists

    ECHO PowerShell script "%TVPSInstaller_ScriptFilePath% exists and will be executed..."

    POWERSHELL -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "& { & '%TVPSInstaller_ScriptFilePath%'; exit $LastExitCode }"
)
