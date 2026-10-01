#!/usr/bin/env python3
"""Builds the 600x800 (3:4) contest cover from a real app screenshot."""
import sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math

shot_path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/shots/home.png"
OUT = os.path.join(os.path.dirname(__file__), "..")
W, H = 1200, 1600  # drawn at 2x, exported at 600x800
FONT = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"

img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
for y in range(H):  # navy -> blue gradient
    t = y / H
    d.line([(0, y), (W, y)], fill=(int(20 + 22 * t), int(33 + 55 * t), int(84 + 120 * t)))

# soft big star watermark
def star(draw, cx, cy, r, fill, inner=0.42):
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        rad = r if k % 2 == 0 else r * inner
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    draw.polygon(pts, fill=fill)

overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
od = ImageDraw.Draw(overlay)
star(od, 980, 520, 520, (255, 255, 255, 16))
img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
d = ImageDraw.Draw(img)

gold = (252, 196, 46)
# small row of stars
for i in range(5):
    star(d, 420 + i * 90, 130, 30, gold)

# wordmark
f_big = ImageFont.truetype(FONT, 178)
f_tag = ImageFont.truetype(FONT, 62)
title = "CivAware"
w = d.textlength(title, font=f_big)
d.text(((W - w) / 2 + 6, 206), title, font=f_big, fill=(10, 20, 58))     # shadow
d.text(((W - w) / 2, 200), title, font=f_big, fill=(255, 255, 255))
tag = "Stay aware. Stay involved."
w = d.textlength(tag, font=f_tag)
d.text(((W - w) / 2, 430), tag, font=f_tag, fill=gold)

# phone
shot = Image.open(shot_path).convert("RGB")
pw = 660
ph = int(shot.height * pw / shot.width)
shot = shot.resize((pw, ph), Image.LANCZOS)
r = 78
mask = Image.new("L", (pw, ph), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, pw, ph], r, fill=255)
px, py = (W - pw) // 2, 600
# shadow
sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(sh).rounded_rectangle([px - 6, py + 10, px + pw + 6, py + ph + 30], r + 12, fill=(0, 0, 0, 120))
sh = sh.filter(ImageFilter.GaussianBlur(28))
img = Image.alpha_composite(img.convert("RGBA"), sh).convert("RGB")
d = ImageDraw.Draw(img)
d.rounded_rectangle([px - 16, py - 16, px + pw + 16, py + ph + 16], r + 16, fill=(12, 16, 34))
img.paste(shot, (px, py), mask)

os.makedirs(OUT, exist_ok=True)
img.resize((600, 800), Image.LANCZOS).save(os.path.join(OUT, "cover_600x800.jpg"), quality=92, optimize=True)
img.save(os.path.join(OUT, "cover_1200x1600.png"))
print("wrote cover")
