# CS.Coder - Hub de Projetos: install / uninstall for every Delphi found on this PC.
# Run through Install.bat or Uninstall.bat. Works per Windows user, no administrator needed.
#
#   -Action install     copies the packages and registers them in each Delphi (11, 12, 13)
#   -Action uninstall   unregisters and removes them; add -RemoveData to delete the shortcut list too
#
# The remaining parameters exist for automated tests.
param(
  [Parameter(Mandatory = $true)][ValidateSet('install', 'uninstall')][string]$Action,
  [switch]$RemoveData,
  [switch]$Quiet,
  [string]$RegistryRoot = 'Software\Embarcadero\BDS',
  [string]$InstallDir = '',
  [string]$SourceDir = '',
  [switch]$SkipProcessCheck
)

$ErrorActionPreference = 'Stop'
# Resolved here, not as parameter defaults: Windows PowerShell 5.1 does not
# always have $PSScriptRoot available while binding parameters.
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($InstallDir -eq '') { $InstallDir = Join-Path $env:LOCALAPPDATA 'CSCoder\Hub\bin' }
if ($SourceDir -eq '') { $SourceDir = Join-Path $Here 'bin' }
$Product = 'CS.Coder - Hub de Projetos'
# What Component > Install Packages shows: the same text as {$DESCRIPTION} of the packages.
$Description = "$Product (https://www.cscoder.com.br)"
$Versions = @(
  @{ Key = '22.0'; Tag = 'D11'; Name = 'Delphi 11' },
  @{ Key = '23.0'; Tag = 'D12'; Name = 'Delphi 12' },
  @{ Key = '37.0'; Tag = 'D13'; Name = 'Delphi 13' }
)
# Every file name this package has ever been registered under.
$OurPackage = '(?i)\\(CSCoder\.HubProjetos\.D\d+|CSCoderHubD\d+|DelphiProjectHubD\d+)\.bpl$'
$Portuguese = (Get-UICulture).TwoLetterISOLanguageName -eq 'pt'

function T([string]$En, [string]$Pt) { if ($Portuguese) { $Pt } else { $En } }
function Say([string]$Text) { Write-Host $Text }

function Open-Key([string]$SubPath, [bool]$Writable) {
  [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($SubPath, $Writable)
}

# Removes our entries from one key. Returns how many were removed.
function Remove-OurValues([string]$SubPath) {
  $key = Open-Key $SubPath $true
  if (-not $key) { return 0 }
  try {
    $names = @($key.GetValueNames() | Where-Object { $_ -match $OurPackage })
    foreach ($n in $names) { $key.DeleteValue($n, $false) }
    return $names.Count
  } finally { $key.Close() }
}

function Remove-OurSubKeys([string]$SubPath) {
  $key = Open-Key $SubPath $true
  if (-not $key) { return }
  try {
    foreach ($n in @($key.GetSubKeyNames() | Where-Object { ('\' + $_) -match $OurPackage })) {
      $key.DeleteSubKeyTree($n, $false)
    }
  } finally { $key.Close() }
}

function Unregister-Version($v) {
  $base = "$RegistryRoot\$($v.Key)"
  $n = 0
  foreach ($k in 'Known Packages', 'Known Packages x64', 'Disabled Packages', 'Disabled Packages x64') {
    $n += Remove-OurValues "$base\$k"
  }
  foreach ($k in 'Package Cache', 'Package Cache x64') { Remove-OurSubKeys "$base\$k" }
  return $n
}

function Register-Package($v, [string]$Platform, [string]$KeyName) {
  $file = "CSCoder.HubProjetos.$($v.Tag).bpl"
  $source = Join-Path $SourceDir "$($v.Tag)\$Platform\$file"
  if (-not (Test-Path $source)) { return $false }
  $key = Open-Key "$RegistryRoot\$($v.Key)\$KeyName" $true
  if (-not $key) { return $false }
  try {
    $targetDir = Join-Path $InstallDir "$($v.Tag)\$Platform"
    New-Item -ItemType Directory -Force $targetDir | Out-Null
    $target = Join-Path $targetDir $file
    Copy-Item $source $target -Force
    $key.SetValue($target, $Description, [Microsoft.Win32.RegistryValueKind]::String)
    return $true
  } finally { $key.Close() }
}

function Find-Versions {
  $found = @()
  foreach ($v in $Versions) {
    $key = Open-Key "$RegistryRoot\$($v.Key)" $false
    if (-not $key) { continue }
    try {
      # A leftover key without RootDir is a Delphi that is no longer installed.
      if ([string]$key.GetValue('RootDir', '') -ne '') { $found += $v }
    } finally { $key.Close() }
  }
  return $found
}

# ---------------------------------------------------------------------------

Say ''
Say "$Product - $(if ($Action -eq 'install') { T 'install' 'instalar' } else { T 'uninstall' 'desinstalar' })"
Say ''

# Delphi rewrites its package list when it closes, which would undo our changes.
if (-not $SkipProcessCheck -and (Get-Process -Name 'bds' -ErrorAction SilentlyContinue)) {
  Say (T 'Delphi is running. Close every Delphi window and run this again.' `
         'O Delphi está aberto. Feche todas as janelas do Delphi e execute de novo.')
  exit 2
}

$found = @(Find-Versions)
if ($found.Count -eq 0) {
  Say (T 'No supported Delphi (11, 12 or 13) was found for this Windows user.' `
         'Nenhum Delphi compatível (11, 12 ou 13) foi encontrado para este usuário do Windows.')
  exit 3
}

if ($Action -eq 'install') {
  $done = 0
  foreach ($v in $found) {
    [void](Unregister-Version $v)   # also clears older copies registered from other folders
    $w32 = Register-Package $v 'Win32' 'Known Packages'
    $w64 = Register-Package $v 'Win64' 'Known Packages x64'
    if ($w32 -or $w64) {
      $done++
      $bits = @(); if ($w32) { $bits += '32-bit' }; if ($w64) { $bits += '64-bit' }
      Say ("  [OK] $($v.Name) (" + ($bits -join ', ') + ')')
    } else {
      Say ("  [--] $($v.Name): " + (T 'package for this version is not in this download' `
                                      'o pacote desta versão não veio neste download'))
    }
  }
  Say ''
  if ($done -eq 0) {
    Say (T 'Nothing was installed.' 'Nada foi instalado.')
    exit 4
  }
  Say (T 'Done. Open Delphi; if the panel is not on the Welcome Page, use Edit Layout to place it.' `
         'Pronto. Abra o Delphi; se o painel não estiver na Welcome Page, use Edit Layout para posicioná-lo.')
  Say ((T 'Installed in: ' 'Instalado em: ') + $InstallDir)
  exit 0
}

# uninstall
$removed = 0
foreach ($v in $Versions) { $removed += (Unregister-Version $v) }   # every version, installed or not
if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force }
Say ("  " + (T 'Package registrations removed: ' 'Registros de pacote removidos: ') + $removed)

$dataDir = Split-Path $InstallDir -Parent
if ($RemoveData) {
  # Left by releases up to 0.26.10.10e, which kept the language here. Nothing is written there anymore.
  [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree('Software\CSCoder\HubProjetos', $false)
  foreach ($f in 'settings.json', 'settings.json.tmp') {
    $p = Join-Path $dataDir $f
    if (Test-Path $p) { Remove-Item $p -Force }
  }
  # One list per Delphi version (D11\, D12\, ...) plus the single file older releases shared.
  # Only our own files are deleted, never a whole folder blindly.
  $dataFiles = 'projects.json', 'projects.json.bak', 'projects.json.tmp'
  $folders = @($dataDir)
  if (Test-Path $dataDir) {
    $folders += @(Get-ChildItem $dataDir -Directory | Where-Object { $_.Name -match '^D\d+$' } | ForEach-Object { $_.FullName })
  }
  foreach ($folder in $folders) {
    foreach ($f in $dataFiles) {
      $p = Join-Path $folder $f
      if (Test-Path $p) { Remove-Item $p -Force }
    }
    # Pictures the user loaded as icons: only the files the plugin itself names.
    $icons = Join-Path $folder 'icons'
    if (Test-Path $icons) {
      Get-ChildItem $icons -File | Where-Object { $_.Name -match '^[0-9a-f]+\.png$' } | Remove-Item -Force
      if (-not (Get-ChildItem $icons -Force)) { Remove-Item $icons -Force }
    }
  }
  foreach ($folder in ($folders | Sort-Object Length -Descending)) {
    if ((Test-Path $folder) -and -not (Get-ChildItem $folder -Force)) { Remove-Item $folder -Force }
  }
  Say ("  " + (T 'Shortcut list and settings removed.' 'Lista de atalhos e configurações removidas.'))
} else {
  Say ("  " + (T 'Your shortcut list was kept in: ' 'Sua lista de atalhos foi mantida em: ') + $dataDir)
  Say ("  " + (T 'To delete it too, run: Uninstall.bat /data' 'Para apagar também, execute: Uninstall.bat /data'))
}
Say ''
Say (T 'Done.' 'Pronto.')
exit 0
