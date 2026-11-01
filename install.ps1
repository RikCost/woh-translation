<#
  Установщик русификатора WORLD OF HORROR (Windows).
  Находит игру, делает резервную копию и ставит перевод.
  - всегда ставит ТЕКСТ (папка language)
  - если рядом лежит data.win (полный пакет) — ставит и картинки/шрифты
  Запускать из папки предмета мастерской / распакованного архива.
#>
param([switch]$Images, [switch]$NoImages)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$src  = Join-Path $here "language"
if (-not (Test-Path $src)) { Write-Host "Папка language не найдена рядом с установщиком." -f Red; pause; exit 1 }

function Get-WohDir {
  $libs = @()
  try { $steam = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction Stop).SteamPath } catch { $steam = "C:\Program Files (x86)\Steam" }
  if ($steam) { $libs += $steam }
  $vdf = Join-Path $steam "config\libraryfolders.vdf"
  if (Test-Path $vdf) { foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s*"([^"]+)"')) { $libs += ($m.Groups[1].Value -replace '\\\\','\') } }
  foreach ($lib in ($libs | Select-Object -Unique)) {
    $c = Join-Path $lib "steamapps\common\WOH"
    if (Test-Path (Join-Path $c "worldofhorror.exe")) { return $c }
  }
  return $null
}

$woh = Get-WohDir
if (-not $woh) { $woh = Read-Host "Не нашёл игру. Укажите путь к папке WOH" }
if (-not (Test-Path (Join-Path $woh "worldofhorror.exe"))) { Write-Host "Это не папка игры." -f Red; pause; exit 1 }
Write-Host "Игра найдена: $woh" -f Green

# --- backup + text ---
$lang = Join-Path $woh "language"
$bak  = Join-Path $lang "engLanguage.orig_backup"
if (-not (Test-Path $bak)) { Copy-Item (Join-Path $lang "engLanguage") $bak -Recurse -Force; Write-Host "Резервная копия: $bak" }
Copy-Item (Join-Path $src "*") $lang -Recurse -Force
Write-Host "Текст установлен." -f Green

# --- картинки/шрифты ---
$dw = Join-Path $here "data.win"
$patch = Join-Path $here "images\patch_images.ps1"
if (Test-Path $dw) {
  $dwBak = Join-Path $woh "data.win.orig_backup"
  if (-not (Test-Path $dwBak)) { Copy-Item (Join-Path $woh "data.win") $dwBak -Force; Write-Host "Резервная копия data.win создана." }
  Copy-Item $dw (Join-Path $woh "data.win") -Force
  Write-Host "Картинки/шрифты (data.win) установлены." -f Green
} elseif (Test-Path $patch) {
  $do = $Images
  if (-not $Images -and -not $NoImages) {
    $ans = Read-Host "Также применить картинки/шрифты? Пропатчит data.win (скачает UndertaleModCli). [y/N]"
    $do = ($ans -match '^(y|Y|д|Д)')
  }
  if ($do) {
    try { & $patch -GameDir $woh } catch { Write-Host "Патч картинок не удался — текст уже установлен. $_" -f Yellow }
  } else { Write-Host "Картинки/шрифты пропущены (текст установлен)." -f Yellow }
} else {
  Write-Host "Инструментов патча нет — картинки/шрифты останутся английскими." -f Yellow
}
Write-Host "Готово. Запускайте игру." -f Green
if ($Host.Name -eq "ConsoleHost") { pause }
