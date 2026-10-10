@echo off
rem Compila tudo e monta a pasta dist\ (zip de instalacao manual + pacotes do GetIt).
rem package.bat            compila e empacota
rem package.bat /skipbuild empacota os .bpl que ja estao em bin\
if /i "%~1"=="/skipbuild" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0package.ps1" -SkipBuild
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0package.ps1"
)
