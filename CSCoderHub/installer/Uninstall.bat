@echo off
rem CS.Coder - Hub de Projetos: removes the panel from every Delphi.
rem Uninstall.bat          keeps your shortcut list
rem Uninstall.bat /data    deletes the shortcut list and settings too
if /i "%~1"=="/data" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0HubSetup.ps1" -Action uninstall -RemoveData
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0HubSetup.ps1" -Action uninstall
)
echo.
pause
