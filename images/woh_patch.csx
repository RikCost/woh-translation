// woh_patch.csx — РАБОЧИЙ метод патча картинок WORLD OF HORROR.
// Заменяет переведённые спрайты «на месте» (формат страницы QOI сохраняется —
// иначе рантайм WOH рисует мусор), и ПРОПУСКАЕТ страницы атласа, которые делят
// место со шрифтами (их перекодирование ломает глифы -> битый текст).
// Шрифты НЕ трогаются (стоковые нормально рисуют кириллицу).
// Требуется nightly-сборка UndertaleModCli (QOI-кодер релиза 0.9.2.0 ненадёжен).
//   UndertaleModCli load data.win -s woh_patch.csx -o data.win.new -f
// Пути: WOH_IMG_DIR — папка с PNG спрайтов (имена вида sprite_<кадр>.png).
using System;
using System.IO;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using ImageMagick;

EnsureDataLoaded();

// Страницы атласа, занятые любым шрифтом — их не трогаем (там глифы).
var fontPages = new HashSet<UndertaleEmbeddedTexture>();
foreach (var f in Data.Fonts)
    if (f.Texture?.TexturePage is not null) fontPages.Add(f.Texture.TexturePage);

int ok = 0, skipFont = 0, miss = 0;
var rx = new Regex(@"^(.+?)_(\d+)$", RegexOptions.Compiled);

UndertaleTexturePageItem Find(string nm)
{
    var m = rx.Match(nm);
    if (m.Success)
    {
        var spr = Data.Sprites.ByName(m.Groups[1].Value);
        int fr = int.Parse(m.Groups[2].Value);
        if (spr is not null && fr < spr.Textures.Count && spr.Textures[fr]?.Texture is not null)
            return spr.Textures[fr].Texture;
    }
    var s0 = Data.Sprites.ByName(nm);
    if (s0 is not null && s0.Textures.Count > 0 && s0.Textures[0]?.Texture is not null)
        return s0.Textures[0].Texture;
    var bg = Data.Backgrounds.ByName(m.Success ? m.Groups[1].Value : nm) ?? Data.Backgrounds.ByName(nm);
    if (bg?.Texture is not null) return bg.Texture;
    return null;
}

string imgDir = Environment.GetEnvironmentVariable("WOH_IMG_DIR");
if (string.IsNullOrEmpty(imgDir) || !Directory.Exists(imgDir))
    throw new Exception("WOH_IMG_DIR не задан/не найден: " + imgDir);

foreach (string file in Directory.GetFiles(imgDir, "*.png"))
{
    string nm = Path.GetFileNameWithoutExtension(file);
    var tpi = Find(nm);
    if (tpi is null) { miss++; Console.WriteLine("[WOH] не найден: " + nm); continue; }
    if (tpi.TexturePage is not null && fontPages.Contains(tpi.TexturePage))
    { skipFont++; Console.WriteLine("[WOH] пропуск (общая со шрифтом страница): " + nm); continue; }
    using var img = new MagickImage(file);
    tpi.ReplaceTexture(img);
    ok++;
}

Console.WriteLine($"[WOH] заменено спрайтов: {ok}, пропущено(страницы шрифтов): {skipFont}, не найдено: {miss}");
if (ok == 0) throw new Exception("[WOH] ничего не заменено — проверьте WOH_IMG_DIR.");
