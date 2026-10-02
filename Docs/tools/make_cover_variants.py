#!/usr/bin/env python3
"""Three alternative 600x800 contest covers (A typographic, B hero phone, C phone fan)."""
import math, os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter
HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, "..", "screenshots")
OUT = os.path.join(HERE, "..", "cover_options"); os.makedirs(OUT, exist_ok=True)
ICON = os.path.join(HERE, "..", "..", "CongressionalAppChallenge", "Assets.xcassets", "AppIcon.appiconset", "icon-1024.png")
FONT = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"
W, H = 1200, 1600
NAVY, GOLD, CREAM, BLUE = (20, 33, 84), (252, 196, 46), (247, 242, 232), (47, 91, 234)
def f(s): return ImageFont.truetype(FONT, s)
def center(d, text, y, size, fill, shadow=None):
    ft = f(size); w = d.textlength(text, font=ft)
    if shadow: d.text(((W - w) / 2 + 6, y + 6), text, font=ft, fill=shadow)
    d.text(((W - w) / 2, y), text, font=ft, fill=fill)
def gradient(top, bottom):
    img = Image.new("RGB", (W, H)); d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H; d.line([(0, y), (W, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img
def star(d, cx, cy, r, fill):
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5; rad = r if k % 2 == 0 else r * 0.42
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    d.polygon(pts, fill=fill)
def phone(name, width):
    shot = Image.open(os.path.join(SHOTS, name)).convert("RGB")
    sh = round(shot.height * width / shot.width); shot = shot.resize((width, sh), Image.LANCZOS)
    pad, rad = 16, 70
    body = Image.new("RGBA", (width + 2 * pad, sh + 2 * pad), (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle([0, 0, body.width - 1, body.height - 1], rad + pad, fill=(12, 16, 34, 255))
    m = Image.new("L", shot.size, 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, width, sh], rad, fill=255)
    body.paste(shot, (pad, pad), m)
    return body
def drop(img, canvas, pos, angle=0, blur=26, off=(0, 24), alpha=140):
    im = img.rotate(angle, expand=True, resample=Image.BICUBIC) if angle else img
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0)); sh.paste((0, 0, 0, alpha), mask=im.getchannel("A"))
    pad = blur * 3; big = Image.new("RGBA", (im.width + 2 * pad, im.height + 2 * pad), (0, 0, 0, 0)); big.paste(sh, (pad, pad))
    big = big.filter(ImageFilter.GaussianBlur(blur))
    canvas.alpha_composite(big, (pos[0] - pad + off[0], pos[1] - pad + off[1])); canvas.alpha_composite(im, pos)
def save(img, name):
    img.convert("RGB").resize((600, 800), Image.LANCZOS).save(os.path.join(OUT, name + ".jpg"), quality=92, optimize=True)

# A: typographic, light, icon-led. Very readable as a thumbnail.
a = Image.new("RGBA", (W, H), CREAM + (255,)); d = ImageDraw.Draw(a)
for i, c in enumerate([(47, 91, 234), (124, 77, 255), (47, 181, 107), (255, 138, 31), (229, 72, 77)]):
    d.rectangle([i * 240, 0, i * 240 + 240, 36], fill=c)
icon = Image.open(ICON).convert("RGBA").resize((520, 520), Image.LANCZOS)
m = Image.new("L", icon.size, 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, 519, 519], 116, fill=255)
icon.putalpha(m)
drop(icon, a, ((W - 520) // 2, 230), 0, 22, (0, 18), 90)
d = ImageDraw.Draw(a)
center(d, "CivAware", 830, 210, NAVY)
center(d, "Stay aware. Stay involved.", 1090, 66, BLUE)
x = 150
for label, col in [("Learn", (47, 91, 234)), ("Simulate", (124, 77, 255)), ("Act", (47, 181, 107))]:
    ft = f(54); w = int(d.textlength(label, font=ft)) + 90
    d.rounded_rectangle([x, 1300, x + w, 1420], 60, fill=col); d.text((x + 45, 1322), label, font=ft, fill="white"); x += w + 36
center(d, "A civics app for students", 1480, 44, (90, 100, 130))
save(a, "cover_A_typographic")

# B: one big tilted phone on navy, bold headline.
b = gradient((14, 24, 66), (47, 91, 234)).convert("RGBA")
ov = Image.new("RGBA", (W, H), (0, 0, 0, 0)); star(ImageDraw.Draw(ov), 930, 1010, 560, (255, 255, 255, 22))
b = Image.alpha_composite(b, ov); d = ImageDraw.Draw(b)
center(d, "LEARN IT.", 110, 150, "white"); center(d, "USE IT.", 270, 150, GOLD)
d.rounded_rectangle([430, 450, 770, 462], 6, fill=GOLD)
center(d, "CivAware", 500, 96, "white")
p = phone("06-build-a-bill.png", 560)
drop(p, b, (320, 700), -7, 30, (10, 30), 150)
d = ImageDraw.Draw(b)
save(b, "cover_B_hero_phone")

# C: three phones fanned on a light background with brand colors.
c = gradient((247, 242, 232), (222, 230, 255)).convert("RGBA"); d = ImageDraw.Draw(c)
center(d, "CivAware", 70, 170, NAVY); center(d, "Stay aware. Stay involved.", 270, 58, BLUE)
drop(phone("02-learn.png", 400), c, (110, 560), -10, 24, (0, 20), 110)
drop(phone("07-act-reps.png", 400), c, (690, 560), 10, 24, (0, 20), 110)
drop(phone("06-build-a-bill.png", 460), c, (370, 480), 0, 30, (0, 26), 150)
save(c, "cover_C_three_phones")
print("wrote", OUT)
