#!/usr/bin/env python3
"""Capitol icon v3: bold and simple. One center axis, proportional widths, 4 chunky columns, ribbed dome, star on the lantern."""
import math, os
from PIL import Image, ImageDraw, ImageFilter, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "icon_options"); os.makedirs(OUT, exist_ok=True)
S, CX = 2048, 1024
CREAM, SHADE, SHADE2 = (255, 247, 228), (230, 222, 200), (205, 196, 170)
GOLD, GOLD_D = (252, 196, 46), (214, 150, 20)

def gradient(top, bottom):
    img = Image.new("RGB", (S, S)); d = ImageDraw.Draw(img)
    for y in range(S):
        t = y / S; d.line([(0, y), (S, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img
def star(d, cx, cy, r, fill):
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5; rad = r if k % 2 == 0 else r * 0.42
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    d.polygon(pts, fill=fill)

def build(dome, dome_shade, accent, name):
    im = gradient((20, 34, 100), (46, 92, 232)).convert("RGBA")
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([CX - 620, 520, CX + 620, 1700], fill=(130, 175, 255, 80))
    im = Image.alpha_composite(im, glow.filter(ImageFilter.GaussianBlur(130)))
    d = ImageDraw.Draw(im)

    # base steps
    d.rounded_rectangle([CX - 720, 1706, CX + 720, 1796], 30, fill=GOLD)
    d.rounded_rectangle([CX - 630, 1626, CX + 630, 1714], 24, fill=CREAM)
    # 4 chunky columns, evenly spaced, with capitals/bases and a shaded right side
    n, cw, span = 4, 150, 800
    for i in range(n):
        x = CX - span / 2 + i * (span - cw) / (n - 1)
        d.rounded_rectangle([x, 1226, x + cw, 1630], 30, fill=CREAM)
        d.rounded_rectangle([x + cw * 0.66, 1236, x + cw * 0.94, 1620], 16, fill=SHADE)
        d.rounded_rectangle([x - 20, 1206, x + cw + 20, 1250], 14, fill=CREAM)
        d.rounded_rectangle([x - 20, 1596, x + cw + 20, 1640], 14, fill=CREAM)
    # entablature (flat roof band) with a gold stripe
    d.rounded_rectangle([CX - 520, 1056, CX + 520, 1112], 18, fill=CREAM)          # cornice
    d.rectangle([CX - 470, 1100, CX + 470, 1212], fill=CREAM)                       # frieze
    d.rectangle([CX - 470, 1170, CX + 470, 1192], fill=accent)                      # stripe
    # drum with evenly spaced slits
    d.rounded_rectangle([CX - 300, 886, CX + 300, 1066], 18, fill=CREAM)
    for i in range(7):
        x = CX - 252 + i * 84
        d.rounded_rectangle([x, 920, x + 32, 1030], 12, fill=SHADE2)
    d.rounded_rectangle([CX - 336, 862, CX + 336, 902], 14, fill=CREAM)             # cornice under dome
    # dome: half ellipse + ribs + band
    cy, rx, ry = 866, 320, 330
    d.pieslice([CX - rx, cy - ry, CX + rx, cy + ry], 180, 360, fill=dome)
    for k in range(-3, 4):
        x_top = CX + k * 20; x_bot = CX + k * (rx / 3.4)
        d.line([(x_top, cy - ry + 40 + abs(k) * 6), (x_bot, cy - 6)], fill=dome_shade, width=10)
    d.rounded_rectangle([CX - rx, cy - 26, CX + rx, cy + 6], 8, fill=accent)
    # lantern, then the star sitting directly on it
    d.rounded_rectangle([CX - 44, 430, CX + 44, 560], 14, fill=dome)
    d.rounded_rectangle([CX - 62, 420, CX + 62, 452], 12, fill=accent)
    star(d, CX, 318, 120, GOLD)
    im.convert("RGB").resize((1024, 1024), Image.LANCZOS).save(os.path.join(OUT, name + ".png"))

build(CREAM, SHADE, GOLD, "icon_2b_capitol_cream")
build(GOLD, GOLD_D, CREAM, "icon_2c_capitol_gold_dome")
sheet = Image.new("RGB", (2 * 440 + 40, 540), (245, 242, 235)); d = ImageDraw.Draw(sheet)
f = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf", 28)
for i, (n, label) in enumerate([("icon_2b_capitol_cream", "2B: cream"), ("icon_2c_capitol_gold_dome", "2C: gold dome")]):
    im = Image.open(os.path.join(OUT, n + ".png")).convert("RGB").resize((400, 400))
    m = Image.new("L", (400, 400), 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, 399, 399], 90, fill=255)
    sheet.paste(im, (30 + i * 440, 40), m); d.text((30 + i * 440 + 120, 460), label, font=f, fill=(20, 33, 84))
sheet.save(os.path.join(OUT, "capitol_options.png")); print("ok")
