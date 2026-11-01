#!/usr/bin/env bash
# patch_images.sh — патчит data.win переведёнными картинками/шрифтами (Linux/macOS/Deck).
# UndertaleModCli ищется в UMT_CLI / PATH / локальном кэше, иначе СКАЧИВАЕТСЯ
# автоматически (self-contained сборка из релизов UndertaleModTool).
# Перед патчем делается резервная копия data.win.orig_backup.
#
# Запуск:  bash patch_images.sh [путь_к_папке_WOH]
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
img="$(cd "$here/../img" && pwd)"
font="$(cd "$here/../font" && pwd)"
script="$here/woh_patch.csx"

find_woh() {
  local roots=(
    "$HOME/.steam/steam" "$HOME/.steam/root" "$HOME/.local/share/Steam"
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"
    "$HOME/snap/steam/common/.local/share/Steam"
    "$HOME/Library/Application Support/Steam"
  )
  local libs=() r vdf p
  for r in "${roots[@]}"; do
    [ -d "$r" ] && libs+=("$r")
    vdf="$r/steamapps/libraryfolders.vdf"
    [ -f "$vdf" ] && while IFS= read -r p; do libs+=("$p"); done \
      < <(grep -oE '"path"[[:space:]]+"[^"]+"' "$vdf" | sed -E 's/.*"path"[[:space:]]+"([^"]+)".*/\1/')
  done
  for p in "${libs[@]}"; do
    [ -f "$p/steamapps/common/WOH/data.win" ] && { echo "$p/steamapps/common/WOH"; return; }
  done
}

# echo-ит путь к исполняемому UndertaleModCli (скачивает при необходимости)
ensure_cli() {
  if [ -n "${UMT_CLI:-}" ]; then echo "$UMT_CLI"; return; fi
  if command -v UndertaleModCli >/dev/null 2>&1; then echo "UndertaleModCli"; return; fi
  local cache="$here/.umtcli" exe
  exe="$(find "$cache" -type f -name UndertaleModCli 2>/dev/null | head -1 || true)"
  if [ -n "${exe:-}" ]; then chmod +x "$exe"; echo "$exe"; return; fi
  local kw; case "$(uname -s)" in Darwin) kw="macOS";; *) kw="Ubuntu";; esac
  echo "UndertaleModCli не найден — скачиваю ($kw)..." >&2
  mkdir -p "$cache"
  local url
  url="$(curl -fsSL https://api.github.com/repos/UnderminersTeam/UndertaleModTool/releases/latest \
        | grep -oE '"browser_download_url"[: ]*"[^"]*'"$kw"'[^"]*\.zip"' \
        | sed -E 's/.*"(https[^"]+)".*/\1/' | head -1)"
  [ -n "${url:-}" ] || { echo "Не нашёл ассет CLI ($kw) в последнем релизе." >&2; return 1; }
  curl -fL "$url" -o "$cache/cli.zip" >&2
  if command -v unzip >/dev/null 2>&1; then (cd "$cache" && unzip -oq cli.zip)
  elif command -v python3 >/dev/null 2>&1; then python3 -c "import zipfile,sys;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$cache/cli.zip" "$cache"
  else echo "Нужен unzip или python3 для распаковки." >&2; return 1; fi
  exe="$(find "$cache" -type f -name UndertaleModCli | head -1 || true)"
  [ -n "${exe:-}" ] || { echo "UndertaleModCli не найден в архиве." >&2; return 1; }
  chmod +x "$exe"; echo "$exe"
}

woh="${1:-$(find_woh || true)}"
[ -n "${woh:-}" ] || read -r -p "Не нашёл игру. Укажите путь к папке WOH: " woh
data="$woh/data.win"
[ -f "$data" ] || { echo "data.win не найден: $data"; exit 1; }
bak="$data.orig_backup"; [ -f "$bak" ] || { cp -f "$data" "$bak"; echo "Резервная копия: $bak"; }

cli="$(ensure_cli)"
export WOH_IMG_DIR="$img" WOH_FONT_DIR="$font"
echo "Патчим data.win через: $cli"
"$cli" load "$data" -s "$script" -o "$data.new" -f -v
mv -f "$data.new" "$data"
echo "Готово: data.win пропатчен. Откат — вернуть $bak."
