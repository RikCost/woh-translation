<#
  patch_images.ps1 — патчит data.win переведёнными картинками и шрифтами (Windows).
  ПРОТОТИП: перед применением делается резервная копия data.win.orig_backup.

  Нужен UndertaleModCli (CLI-сборка UndertaleModTool):
    https://github.com/UnderminersTeam/UndertaleModTool/releases
  Укажите путь через -UmtCli или переменную окружения UMT_CLI, либо положите
  UndertaleModCli(.exe) в PATH.

  Пример:
    powershell -ExecutionPolicy Bypass -File patch_images.ps1 -UmtCli "C:\umt\UndertaleModCli.exe"
#>
param(
  [string]$UmtCli = $env:UMT_CLI,
  [string]$GameDir = ""
)
$ErrorActionPreference = "Stop"
$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$img    = (Resolve-Path (Join-Path $here "..\..\img")).Path
$font   = (Resolve-Path (Join-Path $here "..\..\font")).Path
$script = Join-Path $here "woh_patch.csx"

function Get-WohDir {
  $libs = @()
  try { $steam = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction Stop).SteamPath } catch { $steam = "C:\Program Files (x86)\Steam" }
  if ($steam) { $libs += $steam }
  $vdf = Join-Path $steam "config\libraryfolders.vdf"
  if (Test-Path $vdf) { foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s*"([^"]+)"')) { $libs += ($m.Groups[1].Value -replace '\\\\','\') } }
  foreach ($lib in ($libs | Select-Object -Unique)) {
    $c = Join-Path $lib "steamapps\common\WOH"
    if (Test-Path (Join-Path $c "data.win")) { return $c }
  }
  return $null
}

if (-not $GameDir) { $GameDir = Get-WohDir }
if (-not $GameDir) { $GameDir = Read-Host "Не нашёл игру. Укажите путь к папке WOH" }
$dataWin = Join-Path $GameDir "data.win"
if (-not (Test-Path $dataWin)) { throw "data.win не найден: $dataWin" }

$bak = "$dataWin.orig_backup"
if (-not (Test-Path $bak)) { Copy-Item $dataWin $bak -Force; Write-Host "Резервная копия: $bak" -f Green }

if (-not $UmtCli) {
  $c = Get-Command UndertaleModCli -ErrorAction SilentlyContinue
  if ($c) { $UmtCli = $c.Source }
}
if (-not $UmtCli -or -not (Test-Path $UmtCli)) {
  throw "UndertaleModCli не найден. Скачайте CLI-сборку UndertaleModTool и укажите -UmtCli путь или env UMT_CLI.`nhttps://github.com/UnderminersTeam/UndertaleModTool/releases"
}

$env:WOH_IMG_DIR  = $img
$env:WOH_FONT_DIR = $font
$out = "$dataWin.new"
Write-Host "Патчим $dataWin (img: $img, font: $font)..." -f Cyan
& $UmtCli load $dataWin -s $script -o $out -f -v
if ($LASTEXITCODE -ne 0) { throw "UndertaleModCli завершился с ошибкой $LASTEXITCODE" }
Move-Item $out $dataWin -Force
Write-Host "Готово: data.win пропатчен. Откат — вернуть $bak." -f Green
