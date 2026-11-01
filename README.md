# WORLD OF HORROR — русификатор: лёгкая установка

Готовый пакет для установки русского перевода WORLD OF HORROR **в один запуск**
на Windows, Linux, macOS и Steam Deck.

Перевод — проекта **Deimos Translations**
(https://github.com/deimos-translations/woh-translation, лицензия WTFPL).
Эта ветка — только файлы перевода и скрипты установки, без лишнего.

## Установка (текст)
- **Windows:** запустите `install.bat`
- **Linux / macOS / Steam Deck:** выполните `bash install.sh`

Скрипт сам находит игру (через Steam-библиотеки, включая SD-карту Деки),
делает резервную копию и копирует перевод. Текст заменяет английский слот
`engLanguage` — язык в настройках менять не нужно.

**Steam Deck:** нативной Linux-версии нет, игра идёт через Proton, поэтому перевод
применяется как на Windows. Запускать `install.sh` из Режима рабочего стола
(Konsole). Обновление игры/проверка целостности откатывают перевод — поставьте заново.

## Удаление
- **Windows:** `uninstall.bat`
- **Linux / macOS / Deck:** `bash uninstall.sh`

Либо в Steam: Свойства игры → Установленные файлы → Проверить целостность.

## Картинки и шрифты (опционально)
Текстовая установка не меняет картинки/шрифты (они в `data.win`). Их можно
применить локальным патчем — см. [images/README_IMAGES.md](images/README_IMAGES.md)
(нужен UndertaleModCli). Это **прототип**, проверяйте на копии `data.win`.

## Содержимое
```
language/engLanguage/*.jn     перевод (ТЕКСТ)
img/*.png                     переведённые спрайты (для патча картинок)
font/*.png                    переведённые шрифты (для патча картинок)
install.*  / uninstall.*      установка / удаление (Win / Linux/macOS/Deck)
images/                       патч data.win: woh_patch.csx, patch_images.*, README
ЧИТАЙ_МЕНЯ.txt                краткая памятка
```

## Кредиты
Перевод: Deimos Translations (Деймос, Труповальня, Red_Ruby). Лицензия: WTFPL.
