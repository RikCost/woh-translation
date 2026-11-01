<#
  patch_images.ps1 — ставит переведённые КАРТИНКИ в data.win (Windows).
  Метод: спрайты заменяются in-place (QOI), страницы атласа со шрифтами
  пропускаются (иначе ломается текст). Шрифты не трогаются.
  Требуется nightly-сборка UndertaleModCli — скачивается автоматически.
  Перед патчем делается резервная копия data.win.orig_backup.

  Запуск:  powershell -ExecutionPolicy Bypass -File patch_images.ps1 [-GameDir "...\WOH"]
#>
param([string]$GameDir = "", [string]$UmtCli = $env:UMT_CLI)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$img  = (Resolve-Path (Join-Path $here "..\img")).Path
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

function Ensure-Cli {
  if ($UmtCli -and (Test-Path $UmtCli)) { return $UmtCli }
  $cache = Join-Path $here ".utmt_nightly"
  $exe = Get-ChildItem $cache -Recurse -Filter "UndertaleModCli.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($exe) { return $exe.FullName }
  Write-Host "Скачиваю UndertaleModCli (nightly)..." -f Cyan
  New-Item -ItemType Directory -Force $cache | Out-Null
  $rel = Invoke-RestMethod "https://api.github.com/repos/UnderminersTeam/UndertaleModTool/releases/tags/nightly"
  $asset = $rel.assets | Where-Object { $_.name -match "CLI" -and $_.name -match "windows" } | Select-Object -First 1
  if (-not $asset) { throw "Не нашёл nightly-ассет CLI (windows)." }
  $zip = Join-Path $cache "cli.zip"
  Invoke-WebRequest $asset.browser_download_url -OutFile $zip
  Expand-Archive $zip $cache -Force
  $exe = Get-ChildItem $cache -Recurse -Filter "UndertaleModCli.exe" | Select-Object -First 1
  if (-not $exe) { throw "UndertaleModCli.exe не найден в архиве." }
  return $exe.FullName
}

if (-not $GameDir) { $GameDir = Get-WohDir }
if (-not $GameDir) { $GameDir = Read-Host "Не нашёл игру. Укажите путь к папке WOH" }
$dataWin = Join-Path $GameDir "data.win"
if (-not (Test-Path $dataWin)) { throw "data.win не найден: $dataWin" }

$bak = "$dataWin.orig_backup"
if (-not (Test-Path $bak)) { Copy-Item $dataWin $bak -Force; Write-Host "Резервная копия: $bak" -f Green }

$cli = Ensure-Cli
$env:WOH_IMG_DIR = $img
$out = "$dataWin.new"
Write-Host "Патчу картинки через: $cli" -f Cyan
& $cli load $dataWin -s $script -o $out -f
if ($LASTEXITCODE -ne 0) { throw "UndertaleModCli завершился с ошибкой $LASTEXITCODE" }
Move-Item $out $dataWin -Force
Write-Host "Готово: картинки применены. Откат — вернуть $bak." -f Green
