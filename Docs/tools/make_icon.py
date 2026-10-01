#!/usr/bin/env python3
"""Draws the CivAware app icon: navy, a gold capitol-style building, and a star."""
from PIL import Image, ImageDraw
import math, os

S = 1024
img = Image.new("RGB", (S, S), (20, 33, 61))
d = ImageDraw.Draw(img)
# vertical gradient
for y in range(S):
    t = y / S
    d.line([(0, y), (S, y)], fill=(int(28 + 20 * t), int(48 + 30 * t), int(110 + 50 * t)))

gold, cream = (252, 196, 46), (255, 246, 226)
# pediment
d.polygon([(232, 470), (512, 300), (792, 470)], fill=cream)
# roof bar
d.rounded_rectangle([212, 470, 812, 520], 14, fill=cream)
# columns
for i in range(5):
    x = 262 + i * 122
    d.rounded_rectangle([x, 540, x + 60, 760], 14, fill=cream)
# base steps
d.rounded_rectangle([212, 780, 812, 820], 12, fill=cream)
d.rounded_rectangle([172, 830, 852, 872], 12, fill=gold)

def star(cx, cy, r, fill):
    pts = []
    for k in range(10):
        ang = -math.pi / 2 + k * math.pi / 5
        rad = r if k % 2 == 0 else r * 0.42
        pts.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
    d.polygon(pts, fill=fill)
star(512, 415, 78, gold)

out = os.path.join(os.path.dirname(__file__), "../../CongressionalAppChallenge/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
img.save(out)
print("wrote", os.path.abspath(out))
