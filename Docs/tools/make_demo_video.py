#!/usr/bin/env python3
"""Renders the CivAware demo video frames + audio from real app screenshots.

Usage: python3 make_demo_video.py   (then run encode_video.swift, see build_demo_video.sh)
No third-party tools: PIL for frames, the standard library for audio.
"""
import math, os, random, struct, sys, wave
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H, FPS = 1280, 720, 24
HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, "..", "screenshots")
SOUNDS = os.path.join(HERE, "..", "..", "CongressionalAppChallenge", "Resources", "Sounds")
OUT = "/tmp/civaware_demo"
FRAMES = os.path.join(OUT, "frames")
FONT = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"
os.makedirs(FRAMES, exist_ok=True)

GOLD, WHITE, SOFT = (252, 196, 46), (255, 255, 255), (214, 225, 255)

def font(size): return ImageFont.truetype(FONT, size)

# ---------- scenes ----------
# kind: "center" (text only) or "split" (phone on the right, text on the left)
SCENES = [
    dict(dur=5, kind="center", title="CivAware", size=120, lines=[("Stay aware. Stay involved.", 48, GOLD)], sfx=[(0.2, "sparkle", 0.7)]),
    dict(dur=8, kind="center", title="The problem", size=60, lines=[
        ("Many students reach voting age without ever practicing how government actually works,", 36, WHITE),
        ("or how to tell what's true online.", 36, WHITE)], sfx=[(0.0, "whoosh", 0.5)]),
    dict(dur=7, kind="split", shot="01-home.png", title="A civics app built for phones", size=46, lines=[
        ("Short daily habit: a daily question,", 30, SOFT), ("streaks, XP and badges.", 30, SOFT)], sfx=[(0.0, "whoosh", 0.5)]),
    dict(dur=8, kind="split", shot="02-learn.png", title="Learn", size=56, lines=[
        ("14 short lessons in 7 units:", 30, SOFT), ("how a bill becomes law, the three", 30, SOFT), ("branches, elections, your rights,", 30, SOFT),
        ("and how to check your sources.", 30, SOFT)], sfx=[(0.0, "whoosh", 0.5), (3.0, "pop", 0.6)]),
    dict(dur=7, kind="split", shot="03-quiz.png", title="Quiz with instant feedback", size=44, lines=[
        ("Every lesson ends with a quiz", 30, SOFT), ("and links to official sources.", 30, SOFT)], sfx=[(0.0, "whoosh", 0.5), (2.2, "correct", 0.9)]),
    dict(dur=9, kind="split", shot="06-build-a-bill.png", title="Simulate: Build a Bill", size=44, lines=[
        ("Take your idea through committee,", 30, SOFT), ("the House, the Senate and the President.", 30, SOFT),
        ("Most bills never make it,", 30, SOFT), ("just like real life.", 30, SOFT)], sfx=[(0.0, "whoosh", 0.5), (5.5, "gavel", 0.9)]),
    dict(dur=8, kind="split", shot="05-spot-the-spin.png", title="Simulate: Spot the Spin", size=42, lines=[
        ("Sort made-up posts into trustworthy", 30, SOFT), ("news, opinion, or needs checking,", 30, SOFT), ("and learn the tells.", 30, SOFT)],
         sfx=[(0.0, "whoosh", 0.5), (3.0, "correct", 0.9)]),
    dict(dur=10, kind="split", shot="07-act-reps.png", title="Act: your real representatives", size=40, lines=[
        ("Enter a ZIP code (and an address", 30, SOFT), ("for your exact district) to see your", 30, SOFT),
        ("two Senators and House member,", 30, SOFT), ("with phone numbers and contact links.", 30, SOFT)], sfx=[(0.0, "whoosh", 0.5), (5.0, "sparkle", 0.7)]),
    dict(dur=7, kind="split", shot="08-me.png", title="Track your progress", size=44, lines=[
        ("Levels, streaks and badges", 30, SOFT), ("keep students coming back.", 30, SOFT)], sfx=[(0.0, "whoosh", 0.5)]),
    dict(dur=7, kind="center", title="Private by design", size=60, lines=[
        ("No accounts. No ads. No tracking.", 40, WHITE), ("Your progress stays on your phone.", 40, GOLD)], sfx=[(0.0, "whoosh", 0.5)]),
    dict(dur=9, kind="center", title="CivAware", size=96, lines=[
        ("Stay aware. Stay involved.", 40, GOLD), ("github.com/e10than/civaware", 32, WHITE),
        ("Built by Ethan Lee for the Congressional App Challenge", 26, SOFT),
        ("Built with the help of Claude Code (AI), as disclosed in the application", 22, SOFT)], sfx=[(0.3, "complete", 0.9)]),
]

# ---------- helpers ----------
def ease(t): t = max(0.0, min(1.0, t)); return 1 - (1 - t) ** 3

def make_background():
    bg = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(bg)
    for y in range(H):
        t = y / H
        d.line([(0, y), (W, y)], fill=(int(18 + 24 * t), int(30 + 50 * t), int(80 + 110 * t)))
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(ov)
    cx, cy, r = 1010, 330, 470
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        rad = r if k % 2 == 0 else r * 0.42
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    od.polygon(pts, fill=(255, 255, 255, 14))
    return Image.alpha_composite(bg.convert("RGBA"), ov).convert("RGB")

def make_phone(path, screen_h=600):
    shot = Image.open(path).convert("RGB")
    sw = round(shot.width * screen_h / shot.height)
    shot = shot.resize((sw, screen_h), Image.LANCZOS)
    pad, rad = 12, 46
    pw, ph = sw + pad * 2, screen_h + pad * 2
    canvas = Image.new("RGBA", (pw + 60, ph + 60), (0, 0, 0, 0))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([30, 44, 30 + pw, 44 + ph], rad + 8, fill=(0, 0, 0, 130))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(18)))
    body = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle([30, 30, 30 + pw, 30 + ph], rad + 8, fill=(12, 16, 34, 255))
    canvas = Image.alpha_composite(canvas, body)
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw, screen_h], rad, fill=255)
    canvas.paste(shot, (30 + pad, 30 + pad), mask)
    return canvas

def text_block(text, size, color, max_w):
    f = font(size)
    words, lines, cur = text.split(), [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        if f.getlength(trial) <= max_w or not cur: cur = trial
        else: lines.append(cur); cur = w
    lines.append(cur)
    lh = int(size * 1.25)
    img = Image.new("RGBA", (max_w, lh * len(lines) + 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, ln in enumerate(lines):
        d.text((0, i * lh + 3), ln, font=f, fill=color + (255,))
    return img

def with_alpha(img, a):
    img = img.copy()
    img.putalpha(img.getchannel("A").point(lambda v: int(v * max(0.0, min(1.0, a)))))
    return img

# ---------- render frames ----------
def render():
    bg = make_background()
    n = 0
    starts, t0 = [], 0.0
    for sc in SCENES:
        starts.append(t0); t0 += sc["dur"]
        sc["phone"] = make_phone(os.path.join(SHOTS, sc["shot"])) if sc["kind"] == "split" else None
        max_w = 560 if sc["kind"] == "split" else 1000
        elems = [text_block(sc["title"], sc["size"], WHITE, max_w)]
        for (txt, size, col) in sc["lines"]:
            elems.append(text_block(txt, size, col, max_w))
        sc["elems"] = elems
    total = t0
    for si, sc in enumerate(SCENES):
        frames = int(sc["dur"] * FPS)
        for fi in range(frames):
            t = fi / FPS
            layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            # layout
            gap = 14
            heights = [e.height + (gap if i else 0) + (22 if i == 1 else 0) for i, e in enumerate(sc["elems"])]
            block_h = sum(heights)
            y = (H - block_h) // 2
            for i, e in enumerate(sc["elems"]):
                y += (gap if i else 0) + (22 if i == 1 else 0)
                a = ease((t - 0.25 - 0.3 * i) / 0.5)
                if sc["kind"] == "center":
                    x = (W - e.width) // 2
                    # center each line by its own width using measured text
                    tw = e.getbbox()[2] if e.getbbox() else e.width
                    x = (W - tw) // 2
                else:
                    x = 70
                dy = int((1 - a) * 18)
                layer.alpha_composite(with_alpha(e, a), (x, y + dy))
                y += e.height
            if sc["phone"] is not None:
                p = sc["phone"]
                a = ease(t / 0.8)
                px = 760 + int((1 - a) * 260)
                py = (H - p.height) // 2 + int(5 * math.sin(t * 1.4))
                layer.alpha_composite(with_alpha(p, a), (px, py))
            # fade the whole scene in/out
            fade = min(1.0, t / 0.4, (sc["dur"] - t) / 0.4)
            layer = with_alpha(layer, fade)
            frame = bg.copy()
            frame.paste(layer, (0, 0), layer)
            frame.save(os.path.join(FRAMES, f"f{n:05d}.jpg"), quality=90)
            n += 1
        print(f"scene {si + 1}/{len(SCENES)} done", flush=True)
    return starts, total, n

# ---------- audio ----------
def read_wav(name):
    w = wave.open(os.path.join(SOUNDS, name + ".wav"))
    raw = w.readframes(w.getnframes())
    return [s / 32768 for s in struct.unpack("<" + "h" * (len(raw) // 2), raw)]

def build_audio(starts, total):
    sr = 44100
    n = int(total * sr)
    mix = [0.0] * n
    # soft pad: a calm C major add9 with slow shimmer
    notes = [130.81, 196.0, 261.63, 329.63, 392.0]
    for i in range(n):
        t = i / sr
        env = min(1.0, t / 3.0, (total - t) / 4.0)
        s = sum(math.sin(2 * math.pi * f * t + 0.3 * math.sin(2 * math.pi * 0.2 * t)) for f in notes) / len(notes)
        mix[i] = 0.07 * env * (0.8 + 0.2 * math.sin(2 * math.pi * 0.11 * t)) * s
    cache = {}
    for sc, st in zip(SCENES, starts):
        for off, name, gain in sc["sfx"]:
            if name not in cache: cache[name] = read_wav(name)
            start = int((st + off) * sr)
            for j, v in enumerate(cache[name]):
                if start + j < n: mix[start + j] += v * gain * 0.7
    peak = max(abs(v) for v in mix) or 1
    scale = min(1.0, 0.9 / peak)
    with wave.open(os.path.join(OUT, "audio.wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v * scale)) * 32767)) for v in mix))

if __name__ == "__main__":
    starts, total, n = render()
    build_audio(starts, total)
    print(f"frames={n} duration={total:.1f}s fps={FPS}")
