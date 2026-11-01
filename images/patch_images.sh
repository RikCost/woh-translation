#!/usr/bin/env bash
# patch_images.sh — ставит переведённые КАРТИНКИ в data.win (Linux/macOS/Deck).
# Метод: спрайты in-place (QOI), страницы атласа со шрифтами пропускаются
# (иначе ломается текст). Шрифты не трогаются. Нужна nightly-сборка
# UndertaleModCli — скачивается автоматически. Делается бэкап data.win.orig_backup.
#   bash patch_images.sh [путь_к_папке_WOH]
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
img="$(cd "$here/../img" && pwd)"
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

ensure_cli() {
  if [ -n "${UMT_CLI:-}" ]; then echo "$UMT_CLI"; return; fi
  local cache="$here/.utmt_nightly" exe
  exe="$(find "$cache" -type f -name UndertaleModCli 2>/dev/null | head -1 || true)"
  if [ -n "${exe:-}" ]; then chmod +x "$exe"; echo "$exe"; return; fi
  local kw; case "$(uname -s)" in Darwin) kw="macOS";; *) kw="ubuntu";; esac
  echo "Скачиваю UndertaleModCli (nightly, $kw)..." >&2
  mkdir -p "$cache"
  local url
  url="$(curl -fsSL https://api.github.com/repos/UnderminersTeam/UndertaleModTool/releases/tags/nightly \
        | grep -oE '"browser_download_url"[: ]*"[^"]*CLI[^"]*'"$kw"'[^"]*\.zip"' \
        | sed -E 's/.*"(https[^"]+)".*/\1/' | head -1)"
  [ -n "${url:-}" ] || { echo "Не нашёл nightly-ассет CLI ($kw)." >&2; return 1; }
  curl -fL "$url" -o "$cache/cli.zip" >&2
  if command -v unzip >/dev/null 2>&1; then (cd "$cache" && unzip -oq cli.zip)
  elif command -v python3 >/dev/null 2>&1; then python3 -c "import zipfile,sys;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$cache/cli.zip" "$cache"
  else echo "Нужен unzip или python3." >&2; return 1; fi
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
export WOH_IMG_DIR="$img"
echo "Патчу картинки через: $cli"
"$cli" load "$data" -s "$script" -o "$data.new" -f
mv -f "$data.new" "$data"
echo "Готово: картинки применены. Откат — вернуть $bak."
