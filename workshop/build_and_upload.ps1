<#
  Собирает папку content/ для предмета мастерской WOH и (опционально)
  загружает её через steamcmd.

  Примеры:
    powershell -ExecutionPolicy Bypass -File build_and_upload.ps1 -NoUpload
    powershell -ExecutionPolicy Bypass -File build_and_upload.ps1 -SteamLogin мой_логин

  -NoUpload    только собрать content/, без steamcmd
  -SteamLogin  логин Steam для steamcmd (по умолчанию спросит steamcmd)
  -SteamCmd    путь к steamcmd.exe (по умолчанию D:\steamcmd\steamcmd.exe)
#>
param(
  [switch]$NoUpload,
  [string]$SteamLogin = "",
  [string]$SteamCmd = "D:\steamcmd\steamcmd.exe"
)
$ErrorActionPreference = "Stop"
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcLang = Join-Path $here "..\translation\language"          # engLanguage/*.jn
$content = Join-Path $here "content"
$vdf     = Join-Path $here "item.vdf"

# 1. Пересобираем content/ с нуля
if (Test-Path $content) { Remove-Item $content -Recurse -Force }
New-Item -ItemType Directory -Path $content | Out-Null

# 2. Кладём папку language (только текст .jn)
$dstLang = Join-Path $content "language"
Copy-Item $srcLang $dstLang -Recurse -Force
# на всякий случай выкидываем всё, что не .jn (шрифты/картинки через мастерскую не идут)
Get-ChildItem $dstLang -Recurse -File | Where-Object { $_.Extension -ne ".jn" } | Remove-Item -Force

# 3. Докладываем установщик и памятку, если лежат рядом со скриптом
foreach ($f in @("install.bat","install.ps1","install.sh","ЧИТАЙ_МЕНЯ.txt")) {
  $p = Join-Path $here $f
  if (Test-Path $p) { Copy-Item $p $content -Force }
}

$jn = (Get-ChildItem (Join-Path $dstLang "engLanguage") -Filter *.jn).Count
Write-Host "content/ собран: $jn файлов .jn в language\engLanguage" -ForegroundColor Green
Write-Host "Путь: $content"

if ($NoUpload) { Write-Host "-NoUpload: загрузка пропущена."; return }

# 4. Загрузка через steamcmd
if (-not (Test-Path $SteamCmd)) { throw "steamcmd не найден: $SteamCmd" }
if (-not (Test-Path (Join-Path $here 'preview.png'))) {
  Write-Warning "preview.png рядом с item.vdf не найден — Steam может отклонить публикацию без превью."
}
$loginArg = if ($SteamLogin) { $SteamLogin } else { "anonymous" }
Write-Host "Запуск steamcmd (login: $loginArg)..." -ForegroundColor Cyan
& $SteamCmd +login $loginArg +workshop_build_item $vdf +quit
