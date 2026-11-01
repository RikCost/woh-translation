# Картинки и шрифты: локальный патч data.win (вариант Б) — ПРОТОТИП

Ставит переведённые **картинки и шрифты**, патча `data.win` **на машине
пользователя** через консольный UndertaleModCli — без GUI и без раздачи
самого `data.win` (везём только свои `img/` и `font/`). Работает и на
Linux / Steam Deck.

> ⚠️ **Прототип.** Логика написана по API UndertaleModTool, но на живом
> `data.win` мной не прогонялась. Перед раздачей — обязательно протестировать.
> Скрипт всегда делает резервную копию `data.win.orig_backup`.

## Что нужно
- **UndertaleModCli** — CLI-сборка UndertaleModTool (кроссплатформенная, .NET):
  https://github.com/UnderminersTeam/UndertaleModTool/releases
  (на Linux обычно `dotnet UndertaleModCli.dll`, на Windows — `UndertaleModCli.exe`).
- Папки `img/` (PNG спрайтов) и `font/` (silver_vsmall/small/big.png) из этого репозитория.

## Как работает
`woh_patch.csx` для каждого PNG находит соответствующий спрайт (по имени
`имя_<кадр>.png`) и заменяет этот кадр «на месте» методом
`UndertaleTexturePageItem.ReplaceTexture` — то же, что ручной «Import» на
текстуре в GUI. Атласы не переупаковываются, экспорт всех спрайтов не нужен,
отсутствующие кадры не мешают. Шрифты (3 листа silver_*) заменяются так же.
Переведённые PNG должны совпадать по размеру с оригинальными кадрами
(ReplaceTexture всё равно подгоняет под исходную область).

## Запуск
**Windows:**
```
powershell -ExecutionPolicy Bypass -File patch_images.ps1 -UmtCli "C:\umt\UndertaleModCli.exe"
```
**Linux / macOS / Steam Deck (Desktop Mode):**
```
UMT_CLI="dotnet /путь/UndertaleModCli.dll" bash patch_images.sh
```
Обёртка сама находит игру (через Steam-библиотеки, включая SD-карту Деки),
делает бэкап `data.win` и прогоняет патч. Откат — вернуть `data.win.orig_backup`
или «Проверить целостность файлов» в Steam.

## Проверка перед раздачей (обязательно)
1. Скопировать `data.win` в сторону.
2. Прогнать патч на копии, открыть её в UndertaleModTool (GUI) и глазами
   проверить несколько спрайтов и шрифты.
3. Запустить игру с пропатченным `data.win`, убедиться, что картинки/шрифты
   на месте и нет артефактов.
4. Если `woh_patch.csx` печатает «не найден спрайт/фон для: …» — значит имя
   PNG не совпало с именем ресурса в data.win; такие случаи разобрать вручную.

## Если не заработает — ручной путь (GUI)
Официальная инструкция (экспорт спрайтов → замена → ImportGraphics + импорт
шрифтов) — в README основного репозитория перевода
(https://github.com/deimos-translations/woh-translation).

## Про Steam Deck
Нативной Linux-версии у игры нет; на Деке она идёт через Proton, но `data.win`
платформонезависим, патч применяется один раз к файлу в папке игры. Патч
тяжёлый (data.win ~314 МБ) и небыстрый; запускать из Desktop Mode. После
обновления игры в Steam патч откатывается — прогнать заново.
