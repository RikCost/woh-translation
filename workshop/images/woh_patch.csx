// woh_patch.csx — headless патч data.win: заменяет спрайты и шрифты «на месте».
// Использует UndertaleTexturePageItem.ReplaceTexture (как ручной Import в GUI),
// без экспорта/переупаковки атласов. Переведённые PNG должны совпадать по
// размеру с оригинальными кадрами (они и есть перерисовки тех же спрайтов).
//
// Пути берутся из переменных окружения:
//   WOH_IMG_DIR  — папка с PNG спрайтов (имена вида sprite_<кадр>.png), плоская
//   WOH_FONT_DIR — папка с silver_vsmall.png / silver_small.png / silver_big.png
//
// Запуск:
//   UndertaleModCli load data.win -s woh_patch.csx -o data.win.new -f
//
// ПРОТОТИП: проверять на копии data.win (всегда есть бэкап в обёртке).

using System;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using ImageMagick;

EnsureDataLoaded();

int sprOk = 0, sprMiss = 0, fontOk = 0;
var rx = new Regex(@"^(.+?)_(\d+)$", RegexOptions.Compiled);

void ReplaceFrame(UndertaleSprite spr, int frame, MagickImage img)
{
    spr.Textures[frame].Texture.ReplaceTexture(img);
    sprOk++;
}

string imgDir = Environment.GetEnvironmentVariable("WOH_IMG_DIR");
if (!string.IsNullOrEmpty(imgDir) && Directory.Exists(imgDir))
{
    foreach (string file in Directory.GetFiles(imgDir, "*.png"))
    {
        string nm = Path.GetFileNameWithoutExtension(file);
        using var img = new MagickImage(file);

        // 1) sprite_<frame>: имя без последнего _N — имя спрайта, N — кадр
        var m = rx.Match(nm);
        if (m.Success)
        {
            var spr = Data.Sprites.ByName(m.Groups[1].Value);
            int frame = int.Parse(m.Groups[2].Value);
            if (spr is not null && frame < spr.Textures.Count && spr.Textures[frame]?.Texture is not null)
            {
                ReplaceFrame(spr, frame, img);
                continue;
            }
        }
        // 2) всё имя — спрайт с одним кадром
        var spr0 = Data.Sprites.ByName(nm);
        if (spr0 is not null && spr0.Textures.Count > 0 && spr0.Textures[0]?.Texture is not null)
        {
            ReplaceFrame(spr0, 0, img);
            continue;
        }
        // 3) фон/тайлсет
        var baseName = m.Success ? m.Groups[1].Value : nm;
        var bg = Data.Backgrounds.ByName(baseName) ?? Data.Backgrounds.ByName(nm);
        if (bg is not null && bg.Texture is not null)
        {
            bg.Texture.ReplaceTexture(img);
            sprOk++;
            continue;
        }
        sprMiss++;
        Console.WriteLine("[WOH] не найден спрайт/фон для: " + nm);
    }
}

string fontDir = Environment.GetEnvironmentVariable("WOH_FONT_DIR");
if (!string.IsNullOrEmpty(fontDir) && Directory.Exists(fontDir))
{
    foreach (string name in new[] { "silver_vsmall", "silver_small", "silver_big" })
    {
        string png = Path.Combine(fontDir, name + ".png");
        if (!File.Exists(png)) continue;
        var font = Data.Fonts.ByName(name);
        if (font?.Texture is null) continue;
        using var img = new MagickImage(png);
        font.Texture.ReplaceTexture(img);
        fontOk++;
    }
}

Console.WriteLine($"[WOH] спрайтов заменено: {sprOk}, не найдено: {sprMiss}, шрифтов: {fontOk}");
if (sprOk == 0 && fontOk == 0)
    throw new Exception("[WOH] ничего не заменено — проверьте WOH_IMG_DIR / WOH_FONT_DIR.");
