#!/usr/bin/env bash
# Установщик русификатора WORLD OF HORROR для Linux / macOS / Steam Deck.
# - всегда ставит ТЕКСТ (папка language)
# - если рядом лежит data.win (полный пакет) — ставит и картинки/шрифты
# Делает резервные копии; удаление — uninstall.sh. Запускать из папки перевода.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/language"
[ -d "$src" ] || { echo "Папка language не найдена рядом с установщиком."; exit 1; }

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
    [ -d "$p/steamapps/common/WOH/language" ] && { echo "$p/steamapps/common/WOH"; return; }
  done
}

woh="$(find_woh || true)"
[ -n "${woh:-}" ] || read -r -p "Не нашёл игру. Укажите путь к папке WOH: " woh
[ -d "$woh/language" ] || { echo "Это не папка игры (нет language)."; exit 1; }
echo "Игра найдена: $woh"

lang="$woh/language"; bak="$lang/engLanguage.orig_backup"
[ -d "$bak" ] || { cp -rf "$lang/engLanguage" "$bak"; echo "Резервная копия: $bak"; }
cp -rf "$src/." "$lang/"
echo "Текст установлен."

if [ -f "$here/data.win" ]; then
  [ -f "$woh/data.win.orig_backup" ] || { cp -f "$woh/data.win" "$woh/data.win.orig_backup"; echo "Резервная копия data.win создана."; }
  cp -f "$here/data.win" "$woh/data.win"; echo "Картинки/шрифты (data.win) установлены."
elif [ -f "$here/images/patch_images.sh" ]; then
  read -r -p "Также применить переведённые КАРТИНКИ? Пропатчит data.win, скачает UndertaleModCli (~130 МБ). [y/N] " ans
  case "${ans:-}" in
    [yYдД]*) bash "$here/images/patch_images.sh" "$woh" || echo "Патч картинок не удался — текст уже установлен." ;;
    *) echo "Картинки пропущены (установлен только текст)." ;;
  esac
else
  echo "Инструментов патча картинок нет — установлен только текст."
fi
echo "Готово. В игре выберите язык English (это и есть русский)."
