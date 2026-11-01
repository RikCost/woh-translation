#!/usr/bin/env bash
# patch_images.sh — патчит data.win переведёнными картинками/шрифтами (Linux/macOS/Deck).
# ПРОТОТИП: перед применением делается резервная копия data.win.orig_backup.
#
# Нужен UndertaleModCli (CLI-сборка UndertaleModTool):
#   https://github.com/UnderminersTeam/UndertaleModTool/releases
# Укажите команду через переменную UMT_CLI, напр.:
#   UMT_CLI="dotnet /path/UndertaleModCli.dll" bash patch_images.sh
#   UMT_CLI="/path/UndertaleModCli"            bash patch_images.sh
# Либо положите UndertaleModCli в PATH.
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

woh="${1:-$(find_woh || true)}"
[ -n "${woh:-}" ] || read -r -p "Не нашёл игру. Укажите путь к папке WOH: " woh
data="$woh/data.win"
[ -f "$data" ] || { echo "data.win не найден: $data"; exit 1; }

bak="$data.orig_backup"
[ -f "$bak" ] || { cp -f "$data" "$bak"; echo "Резервная копия: $bak"; }

# команда CLI
cli="${UMT_CLI:-}"
if [ -z "$cli" ]; then
  if command -v UndertaleModCli >/dev/null 2>&1; then cli="UndertaleModCli"; fi
fi
[ -n "$cli" ] || { echo "UndertaleModCli не найден. Задайте UMT_CLI (см. шапку скрипта)."; exit 1; }

export WOH_IMG_DIR="$img"
export WOH_FONT_DIR="$font"
echo "Патчим $data (img: $img, font: $font)..."
# shellcheck disable=SC2086
$cli load "$data" -s "$script" -o "$data.new" -f -v
mv -f "$data.new" "$data"
echo "Готово: data.win пропатчен. Откат — вернуть $bak."
