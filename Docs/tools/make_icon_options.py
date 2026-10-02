#!/usr/bin/env python3
"""Three alternative 1024x1024 app icon concepts. Drawn at 2x and downscaled for clean edges."""
import math, os
from PIL import Image, ImageDraw, ImageChops
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "icon_options"); os.makedirs(OUT, exist_ok=True)
S = 2048
GOLD, CREAM, INK = (252, 196, 46), (255, 247, 228), (12, 20, 52)

def grad(top, bottom):
    img = Image.new("RGB", (S, S)); d = ImageDraw.Draw(img)
    for y in range(S):
        t = y / S; d.line([(0, y), (S, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img
def star(d, cx, cy, r, fill, inner=0.42, rot=-math.pi / 2):
    pts = []
    for k in range(10):
        a = rot + k * math.pi / 5; rad = r if k % 2 == 0 else r * inner
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    d.polygon(pts, fill=fill)
def save(img, name): img.resize((1024, 1024), Image.LANCZOS).save(os.path.join(OUT, name + ".png"))

# 1: The Aware Eye: an eye (awareness) whose pupil is a star (civics).
im = grad((24, 40, 110), (47, 91, 234)); d = ImageDraw.Draw(im)
R, off = 1500, 1020
lens = ImageChops.multiply(Image.new("L", (S, S), 0).point(lambda v: 0), Image.new("L", (S, S), 0))
a = Image.new("L", (S, S), 0); ImageDraw.Draw(a).ellipse([S / 2 - R, S / 2 - off - R, S / 2 + R, S / 2 - off + R], fill=255)
b = Image.new("L", (S, S), 0); ImageDraw.Draw(b).ellipse([S / 2 - R, S / 2 + off - R, S / 2 + R, S / 2 + off + R], fill=255)
lens = ImageChops.multiply(a, b)
white = Image.new("RGB", (S, S), CREAM); im.paste(white, (0, 0), lens)
d = ImageDraw.Draw(im)
d.ellipse([S / 2 - 400, S / 2 - 400, S / 2 + 400, S / 2 + 400], fill=(24, 44, 130))
d.ellipse([S / 2 - 400, S / 2 - 400, S / 2 + 400, S / 2 + 400], outline=(14, 28, 90), width=26)
star(d, S / 2, S / 2 + 14, 300, GOLD)
d.ellipse([S / 2 - 250, S / 2 - 330, S / 2 - 150, S / 2 - 230], fill=(255, 255, 255))
save(im, "icon_1_aware_eye")

# 2: Capitol dome, simplified and bold, with a star on top.
im = grad((24, 40, 110), (47, 91, 234)); d = ImageDraw.Draw(im)
cx = S / 2
d.rounded_rectangle([cx - 760, 1640, cx + 760, 1730], 30, fill=GOLD)             # base step
d.rounded_rectangle([cx - 700, 1560, cx + 700, 1640], 24, fill=CREAM)            # lower step
for i in range(6):                                                                 # columns
    x = cx - 620 + i * 250; d.rounded_rectangle([x, 1120, x + 120, 1560], 30, fill=CREAM)
d.rounded_rectangle([cx - 720, 1020, cx + 720, 1120], 26, fill=CREAM)            # entablature
d.rounded_rectangle([cx - 400, 880, cx + 400, 1020], 24, fill=CREAM)             # drum
d.pieslice([cx - 420, 520, cx + 420, 1220], 180, 360, fill=CREAM)                 # dome
d.rounded_rectangle([cx - 60, 400, cx + 60, 560], 20, fill=CREAM)                 # lantern
star(d, cx, 330, 150, GOLD)
save(im, "icon_2_capitol_dome")

# 3: Speech bubble with a star: your voice, your involvement.
im = grad((124, 77, 255), (47, 91, 234)); d = ImageDraw.Draw(im)
d.rounded_rectangle([330, 440, 1718, 1400], 340, fill=CREAM)
d.polygon([(640, 1340), (640, 1760), (1000, 1340)], fill=CREAM)
d.rounded_rectangle([330, 440, 1718, 1400], 340, outline=None, fill=CREAM)
star(d, S / 2, 930, 360, (47, 91, 234))
star(d, S / 2, 930, 230, GOLD)
save(im, "icon_3_voice_star")
print("wrote", os.path.abspath(OUT))
