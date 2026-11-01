#!/usr/bin/env bash
# Удаление русификатора WORLD OF HORROR (Linux/macOS/Deck): восстановление из бэкапов.
set -euo pipefail
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
[ -n "${woh:-}" ] || read -r -p "Укажите путь к папке WOH: " woh
lang="$woh/language"; bak="$lang/engLanguage.orig_backup"
if [ -d "$bak" ]; then
  rm -rf "$lang/engLanguage"; mv "$bak" "$lang/engLanguage"
  echo "Текст восстановлен из резервной копии."
else
  echo "Резервной копии текста нет. Можно восстановить через Steam: Проверить целостность файлов."
fi
[ -f "$woh/data.win.orig_backup" ] && { mv -f "$woh/data.win.orig_backup" "$woh/data.win"; echo "data.win восстановлен."; }
echo "Готово."
