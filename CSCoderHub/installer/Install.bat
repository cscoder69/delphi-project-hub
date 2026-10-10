@echo off
rem CS.Coder - Hub de Projetos: installs the Welcome Page panel in every Delphi (11, 12, 13) found.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0HubSetup.ps1" -Action install
echo.
pause
