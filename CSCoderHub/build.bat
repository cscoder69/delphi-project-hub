@echo off
rem Compila o pacote pela linha de comando para Delphi 11, 12 e 13.
rem Uso: build.bat [11^|12^|13^|all]   (sem argumento = all)
rem Saida Win32: bin\CSCoder.HubProjetos.D<versao>.bpl
rem Saida Win64: bin\Win64\CSCoder.HubProjetos.D<versao>.bpl  (IDE de 64 bits, Delphi 12 e 13)
setlocal
set "ROOT=%~dp0"
set "TARGET=%~1"
if "%TARGET%"=="" set "TARGET=all"
set FAILED=0
set DONE=0

rem Caminhos de instalacao desta maquina.
if /i "%TARGET%"=="all" call :version 11 "C:\Programas\Embarcadero\Delphi_11_3"
if /i "%TARGET%"=="11"  call :version 11 "C:\Programas\Embarcadero\Delphi_11_3"
if /i "%TARGET%"=="all" call :version 12 "C:\Programas\Embarcadero\Delphi_12_3"
if /i "%TARGET%"=="12"  call :version 12 "C:\Programas\Embarcadero\Delphi_12_3"
if /i "%TARGET%"=="all" call :version 13 "C:\Programas\Embarcadero\Delphi_13_1_v37"
if /i "%TARGET%"=="13"  call :version 13 "C:\Programas\Embarcadero\Delphi_13_1_v37"

if "%DONE%"=="0" echo Nada compilado. Uso: build.bat [11^|12^|13^|all] & exit /b 1
if "%FAILED%"=="1" echo FALHOU & exit /b 1
echo OK
exit /b 0

:version
set "BDS=%~2"
if not exist "%BDS%\bin\dcc32.exe" echo [D%~1] Delphi nao encontrado em %BDS% - pulado & goto :eof
call :build %~1 Win32 dcc32.exe win32 "%ROOT%bin"
rem A IDE de 64 bits (bin64\bds.exe) so carrega pacotes Win64.
if exist "%BDS%\lib\win64\release\designide.dcp" call :build %~1 Win64 dcc64.exe win64 "%ROOT%bin\Win64"
goto :eof

:build
set DONE=1
set "PKG=CSCoder.HubProjetos.D%~1"
set "OUT=%~5"
set "DCU=%ROOT%dcu\D%~1\%~2"
if not exist "%OUT%" mkdir "%OUT%"
if not exist "%DCU%" mkdir "%DCU%"
rem A IDE aberta bloqueia o .bpl carregado, mas deixa renomear: tira o antigo do caminho.
del "%OUT%\%PKG%.bpl.old" >nul 2>&1
if exist "%OUT%\%PKG%.bpl" move /y "%OUT%\%PKG%.bpl" "%OUT%\%PKG%.bpl.old" >nul 2>&1
pushd "%ROOT%packages"
"%BDS%\bin\brcc32.exe" -fo%PKG%.res CSCoder.HubProjetos.rc >nul
if errorlevel 1 echo [D%~1 %~2] FALHOU no .res & set FAILED=1 & popd & goto :eof
"%BDS%\bin\%~3" -B -Q "-U%BDS%\lib\%~4\release" "-LE%OUT%" "-LN%OUT%" "-NU%DCU%" %PKG%.dpk
if errorlevel 1 (echo [D%~1 %~2] FALHOU & set FAILED=1) else (echo [D%~1 %~2] OK: %OUT%\%PKG%.bpl)
popd
goto :eof
