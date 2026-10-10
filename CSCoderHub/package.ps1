# Builds every package and assembles what gets distributed, under dist\:
#
#   dist\CSCoderHubProjetos-<version>.zip     manual install: Install.bat / Uninstall.bat + all .bpl
#   dist\GetIt\<D11|D12|D13>\                 one GetIt package per Delphi version:
#       CSCoderHubProjetos<tag>.json            local GetIt file for the 32-bit IDE
#       CSCoderHubProjetos<tag>x64.json         same for the 64-bit IDE (Delphi 12 and 13)
#       CSCoderHubProjetos<tag>.zip             what GetIt downloads: the .bpl files + license
#       LICENSE.txt, CSCoderHubProjetos.png     shown by GetIt before installing
#
# Run through package.bat. -SkipBuild reuses the .bpl already in bin\.
param([switch]$SkipBuild)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
# 0.<yy>.<mm>.<dd><letter>: the date of the release, plus a letter for more than one in a day.
# Keep the four numbers of FILEVERSION / PRODUCTVERSION in the .rc in step (the letter only
# fits its ProductVersion text, which is what the About window shows).
$Version = '0.26.10.10d'
$Name = 'CS.Coder - Hub de Projetos'
$Vendor = 'CS.Coder'
# Fill these in before sending to Embarcadero (GetIt shows them as links).
$VendorUrl = 'https://www.cscoder.com.br'
$ProjectUrl = 'https://github.com/cscoder69/delphi-project-hub'
$DescriptionEn = 'Welcome Page panel that keeps your Delphi projects one double-click away, organized in ' +
  'categories and groups, with search, export/import and an interface in English, Portuguese, Spanish, ' +
  'German and French.'
$Tags = 'D11', 'D12', 'D13'

if (-not $SkipBuild) {
  & cmd /c "`"$Root\build.bat`" all"
  if ($LASTEXITCODE -ne 0) { throw 'build failed' }
}

$Dist = Join-Path $Root 'dist'
if (Test-Path $Dist) { Remove-Item $Dist -Recurse -Force }
New-Item -ItemType Directory -Force $Dist | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Copy-Bpl([string]$Tag, [string]$Platform, [string]$TargetDir) {
  $file = "CSCoder.HubProjetos.$Tag.bpl"
  $source = if ($Platform -eq 'Win64') { Join-Path $Root "bin\Win64\$file" } else { Join-Path $Root "bin\$file" }
  if (-not (Test-Path $source)) { return $false }
  New-Item -ItemType Directory -Force $TargetDir | Out-Null
  Copy-Item $source (Join-Path $TargetDir $file)
  return $true
}

# ---- manual install package -------------------------------------------------
$Stage = Join-Path $Dist "CSCoderHubProjetos-$Version"
New-Item -ItemType Directory -Force $Stage | Out-Null
foreach ($tag in $Tags) {
  [void](Copy-Bpl $tag 'Win32' (Join-Path $Stage "bin\$tag\Win32"))
  [void](Copy-Bpl $tag 'Win64' (Join-Path $Stage "bin\$tag\Win64"))
}
Copy-Item (Join-Path $Root 'installer\*') $Stage
Copy-Item (Join-Path $Root 'LICENSE.txt'), (Join-Path $Root 'LICENCA.txt') $Stage
Copy-Item (Join-Path $Root 'installer-readme\README.txt'), (Join-Path $Root 'installer-readme\LEIAME.txt') $Stage
[System.IO.Compression.ZipFile]::CreateFromDirectory($Stage, "$Stage.zip")
Remove-Item $Stage -Recurse -Force

# ---- GetIt packages ---------------------------------------------------------
function New-Action([int]$Id, [int]$ActionId, [string]$ActionName, [int]$Type, [string]$Description, [string]$Path) {
  [ordered]@{
    Id = "$Id"; ActionId = "$ActionId"; Type = "$Type"; RequireElevation = '0'
    Parameter = @([ordered]@{ Parameter = $Path })
    ActionName = $ActionName; Description = $Description
  }
}

function Write-GetItJson([string]$Tag, [string]$Platform, [string]$Dir) {
  $suffix = if ($Platform -eq 'Win64') { 'x64' } else { '' }
  $id = "CSCoderHubProjetos$Tag$suffix"
  # GetIt unpacks the zip into <CatalogRepository>\<Id>.
  $bpl = "`$(BDSCatalogRepository)\$id\$Platform\CSCoder.HubProjetos.$Tag.bpl"
  $ide = if ($Platform -eq 'Win64') { ' (64-bit IDE)' } else { '' }
  $json = [ordered]@{
    Id = $id
    Name = "$Name$ide"
    Version = $Version
    Description = $DescriptionEn
    Vendor = $Vendor
    VendorUrl = $VendorUrl
    Image = 'CSCoderHubProjetos.png'
    License = 'LICENSE.txt'
    Url = "CSCoderHubProjetos$Tag.zip"
    ProjectUrl = $ProjectUrl
    Modified = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    LicenseName = 'MIT License'
    RequireElevation = '0'
    AllUsers = '0'
    Actions = @(
      # Type 3 = before install, 5 = before uninstall. ActionId 7 / 8 = InstallPackage / UninstallPackage.
      (New-Action 1 7 'InstallPackage' 3 "Install $Name" $bpl),
      (New-Action 2 8 'UninstallPackage' 5 "Uninstall $Name" $bpl)
    )
  }
  $text = ($json | ConvertTo-Json -Depth 6)
  [System.IO.File]::WriteAllText((Join-Path $Dir "$id.json"), $text, (New-Object System.Text.UTF8Encoding($false)))
}

foreach ($tag in $Tags) {
  $dir = Join-Path $Dist "GetIt\$tag"
  $stage = Join-Path $dir '_zip'
  $has32 = Copy-Bpl $tag 'Win32' (Join-Path $stage 'Win32')
  $has64 = Copy-Bpl $tag 'Win64' (Join-Path $stage 'Win64')
  if (-not ($has32 -or $has64)) { if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }; continue }
  Copy-Item (Join-Path $Root 'LICENSE.txt') $stage
  [System.IO.Compression.ZipFile]::CreateFromDirectory($stage, (Join-Path $dir "CSCoderHubProjetos$tag.zip"))
  Remove-Item $stage -Recurse -Force
  Copy-Item (Join-Path $Root 'LICENSE.txt') $dir
  Copy-Item (Join-Path $Root 'assets\CSCoderHubProjetos.png') $dir
  if ($has32) { Write-GetItJson $tag 'Win32' $dir }
  if ($has64) { Write-GetItJson $tag 'Win64' $dir }
}

Write-Host ''
Write-Host "dist ready: $Dist"
Get-ChildItem $Dist -Recurse -File | ForEach-Object { '  ' + $_.FullName.Substring($Dist.Length + 1) + '  (' + $_.Length + ' bytes)' }
