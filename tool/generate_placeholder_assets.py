"""Generate polished temporary WebP artwork matching the production asset layout."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import random

ROOT = Path(__file__).resolve().parents[1] / "assets" / "images" / "themes"
FONT = "C:/Windows/Fonts/segoeui.ttf"
FONT_BOLD = "C:/Windows/Fonts/seguisb.ttf"

THEMES = {
    "japan": {"name": "JAPÃO", "colors": [(25, 24, 33), (184, 54, 58), (236, 181, 151)]},
    "egypt": {"name": "EGITO", "colors": [(19, 31, 35), (190, 134, 52), (226, 197, 123)]},
    "greece": {"name": "GRÉCIA", "colors": [(18, 43, 61), (54, 133, 177), (221, 231, 226)]},
}


def gradient(size, top, bottom):
    width, height = size
    image = Image.new("RGB", size)
    pixels = image.load()
    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(round(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(width):
            pixels[x, y] = color
    return image


def art(theme_id, level, size=(2048, 2048)):
    info = THEMES[theme_id]
    dark, accent, light = info["colors"]
    rng = random.Random(f"{theme_id}-{level}")
    image = gradient(size, dark, tuple(max(0, c - 18) for c in accent))
    draw = ImageDraw.Draw(image, "RGBA")
    w, h = size

    # Atmospheric sun/moon and repeating architecture-like silhouettes.
    sun_r = int(w * (0.13 + level * 0.008))
    sun_x = int(w * (0.68 if level % 2 else 0.31))
    sun_y = int(h * (0.28 + (level % 3) * 0.045))
    draw.ellipse((sun_x-sun_r, sun_y-sun_r, sun_x+sun_r, sun_y+sun_r), fill=(*light, 225))
    for i in range(10):
        x = int((i / 9) * w)
        height = int(h * rng.uniform(.14, .42))
        width = int(w * rng.uniform(.07, .16))
        y = h - height
        shade = tuple(max(0, c - rng.randint(8, 35)) for c in dark)
        draw.rectangle((x-width//2, y, x+width//2, h), fill=(*shade, 255))
        if theme_id == "japan":
            draw.polygon([(x-width, y), (x+width, y), (x, y-int(width*.34))], fill=(*shade, 255))
        elif theme_id == "egypt":
            draw.polygon([(x-width//2, y), (x+width//2, y), (x, y-height//2)], fill=(*shade, 230))
        else:
            for col in range(3):
                cx = x-width//3 + col*width//3
                draw.rectangle((cx-6, y, cx+6, h), fill=(*light, 145))

    # Fine lines and organic foreground keep every tile visually distinctive.
    for i in range(14):
        points = []
        phase = rng.random() * math.pi
        for x in range(0, w + 1, 64):
            y = int(h * (.62 + i*.019) + math.sin(x/180 + phase) * (20+i*2))
            points.append((x, y))
        draw.line(points, fill=(*light, 35 + i*3), width=5)
    for _ in range(70):
        x, y = rng.randrange(w), rng.randrange(h)
        r = rng.randrange(2, 10)
        draw.ellipse((x-r, y-r, x+r, y+r), fill=(*light, rng.randrange(20, 85)))

    image = image.filter(ImageFilter.GaussianBlur(.35))
    draw = ImageDraw.Draw(image, "RGBA")
    label = f"{info['name']}  ·  {level:02d}"
    font = ImageFont.truetype(FONT_BOLD, 42)
    draw.text((90, 90), label, font=font, fill=(255, 255, 255, 205))
    return image


def wallpaper(theme_id):
    base = art(theme_id, 6).resize((1440, 1440), Image.Resampling.LANCZOS)
    canvas = gradient((1440, 3200), THEMES[theme_id]["colors"][0], (4, 7, 9))
    canvas.paste(base, (0, 410))
    draw = ImageDraw.Draw(canvas, "RGBA")
    draw.rectangle((0, 1650, 1440, 3200), fill=(5, 8, 10, 115))
    title_font = ImageFont.truetype(FONT_BOLD, 118)
    sub_font = ImageFont.truetype(FONT, 38)
    draw.text((100, 1860), THEMES[theme_id]["name"], font=title_font, fill=(255, 255, 255, 240))
    draw.text((108, 2005), "MOSAICO · JORNADAS VISUAIS", font=sub_font, fill=(255, 255, 255, 145))
    return canvas


def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    for theme_id in THEMES:
        folder = ROOT / theme_id
        folder.mkdir(parents=True, exist_ok=True)
        images = []
        for level in range(1, 7):
            image = art(theme_id, level)
            image.save(folder / f"{theme_id}_{level:02d}.webp", "WEBP", quality=86, method=6)
            images.append(image)
        images[0].resize((1080, 1080), Image.Resampling.LANCZOS).save(
            folder / f"{theme_id}_thumbnail.webp", "WEBP", quality=86, method=6
        )
        wallpaper(theme_id).save(folder / f"{theme_id}_wallpaper.webp", "WEBP", quality=88, method=6)


if __name__ == "__main__":
    main()
