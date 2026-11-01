<#
  Удаление русификатора WORLD OF HORROR (Windows): восстановление из резервных копий.
#>
$ErrorActionPreference = "Stop"
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
if (-not $woh) { $woh = Read-Host "Укажите путь к папке WOH" }
$lang = Join-Path $woh "language"
$bak  = Join-Path $lang "engLanguage.orig_backup"
if (Test-Path $bak) {
  Remove-Item (Join-Path $lang "engLanguage") -Recurse -Force
  Rename-Item $bak "engLanguage"
  Write-Host "Текст восстановлен из резервной копии." -f Green
} else { Write-Host "Резервной копии текста нет. Можно восстановить через Steam: Проверить целостность файлов." -f Yellow }
$dwBak = Join-Path $woh "data.win.orig_backup"
if (Test-Path $dwBak) { Move-Item $dwBak (Join-Path $woh "data.win") -Force; Write-Host "data.win восстановлен." -f Green }
Write-Host "Готово." -f Green
if ($Host.Name -eq "ConsoleHost") { pause }
