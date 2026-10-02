#!/usr/bin/env python3
"""Builds the branded frame, caption images and music bed for the screen-recording overlay.
usage: make_overlay_assets.py <screen_recording.mov> [timeline.json]
Writes /tmp/civaware_overlay/manifest.json for compose_overlay.swift.
"""
import json, math, os, struct, subprocess, sys, wave
from PIL import Image, ImageDraw, ImageFilter
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
from make_demo_video import make_background, text_block, font, with_alpha, WHITE, GOLD, SOFT, W, H  # noqa

OUT = "/tmp/civaware_overlay"
os.makedirs(OUT, exist_ok=True)
video = sys.argv[1]
tl = json.load(open(sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "timeline.json")))

def dims(path):
    probe = "/tmp/probe_video"
    if not os.path.exists(probe):
        subprocess.run(["swiftc", "-O", os.path.join(HERE, "probe_video.swift"), "-o", probe], check=True)
    out = subprocess.run([probe, path], capture_output=True, text=True).stdout.split()[0]
    w, h = out.split("x")
    return int(w), int(h)

vw, vh = dims(video)
if vw > vh: sys.exit("This tool expects a portrait (phone) recording.")
screen_h = 610
screen_w = round(vw * screen_h / vh)
bezel, rad = 12, 46
pw, ph = screen_w + 2 * bezel, screen_h + 2 * bezel
px = 790 + (260 - pw) // 2                      # phone body left
py = (H - ph) // 2
hole = (px + bezel, py + bezel, screen_w, screen_h)   # x, y(top), w, h

# frame.png: background + phone body, with a transparent rounded "screen" hole
bg = make_background().convert("RGBA")
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle([px - 4, py + 12, px + pw + 4, py + ph + 24], rad + 10, fill=(0, 0, 0, 120))
bg = Image.alpha_composite(bg, shadow.filter(ImageFilter.GaussianBlur(18)))
ImageDraw.Draw(bg).rounded_rectangle([px, py, px + pw, py + ph], rad + bezel, fill=(12, 16, 34, 255))
holemask = Image.new("L", (W, H), 255)
ImageDraw.Draw(holemask).rounded_rectangle([hole[0], hole[1], hole[0] + hole[2], hole[1] + hole[3]], rad, fill=0)
frame = bg.copy(); frame.putalpha(holemask)
frame.save(os.path.join(OUT, "frame.png"))

layers = []
def add_text(title, size, lines, start, end):
    max_w, gap = 560, 14
    elems = [text_block(title, size, WHITE, max_w)] + [text_block(t, 30, SOFT, max_w) for t in lines]
    heights = [e.height + (gap if i else 0) + (22 if i == 1 else 0) for i, e in enumerate(elems)]
    y = (H - sum(heights)) // 2
    for i, e in enumerate(elems):
        y += (gap if i else 0) + (22 if i == 1 else 0)
        name = f"cap_{len(layers)}.png"
        e.save(os.path.join(OUT, name))
        layers.append(dict(png=name, x=70, y=y, w=e.width, h=e.height, start=start + 0.3 * i, end=end, fade=0.5))
        y += e.height

# Walk the segments to get output times, then give each caption id a window across its segments.
segs, cursor, windows = [], 0.0, {}
for sg in tl["segments"]:
    rate = sg.get("rate", 1.0)
    dur = (sg["src"][1] - sg["src"][0]) / rate
    segs.append(dict(start=sg["src"][0], end=sg["src"][1], rate=rate))
    w = windows.setdefault(sg["cap"], [cursor, cursor + dur])
    w[1] = cursor + dur
    cursor += dur
video_out = cursor
for cid, (a0, a1) in windows.items():
    c = tl["captions"][cid]
    add_text(c["title"], 46, c["lines"], tl["pad_start"] + a0 + 0.3, tl["pad_start"] + a1 - 0.2)

# intro / outro full-frame cards
def card(name, title, tsize, lines):
    img = make_background().convert("RGBA")
    blocks = [(text_block(title, tsize, WHITE, 1000), 0)] + [(text_block(t, s, col, 1000), 16) for (t, s, col) in lines]
    total = sum(b.height + g for b, g in blocks)
    y = (H - total) // 2
    for b, g in blocks:
        y += g
        tw = b.getbbox()[2] if b.getbbox() else b.width
        img.alpha_composite(b, ((W - tw) // 2, y)); y += b.height
    img.save(os.path.join(OUT, name))
card("intro.png", tl["intro"]["title"], 120, [(tl["intro"]["subtitle"], 48, GOLD)])
o = tl["outro"]
ol = [(o["lines"][0], 40, GOLD), (o["lines"][1], 32, WHITE)] + [(t, 24, SOFT) for t in o["lines"][2:]]
card("outro.png", o["title"], 96, ol)

# ---- audio: quiet original music + sound effects synced to the footage, mixed into one track ----
from make_music import music_loop, SR as MSR
sr = MSR
total = tl["pad_start"] + video_out + tl["pad_end"]
n = int(total * sr)
mix = [0.0] * n
loop = music_loop()
MUSIC_GAIN = 0.20
for i in range(n):
    t = i / sr
    fade = min(1.0, t / 1.5, (total - t) / 3.5)
    mix[i] = MUSIC_GAIN * fade * loop[i % len(loop)]

SOUNDS = os.path.join(HERE, "..", "..", "..", "CongressionalAppChallenge", "Resources", "Sounds")
def read_wav(name):
    w = wave.open(os.path.join(SOUNDS, name + ".wav")); raw = w.readframes(w.getnframes())
    return [v / 32768 for v in struct.unpack("<" + "h" * (len(raw) // 2), raw)]
def out_time(src_t):
    c = tl["pad_start"]
    for sg in tl["segments"]:
        rate = sg.get("rate", 1.0); a0, a1 = sg["src"]
        if a0 <= src_t <= a1: return c + (src_t - a0) / rate
        c += (a1 - a0) / rate
    return None
cache = {}
def sfx(name, at, gain):
    if at is None: return
    if name not in cache: cache[name] = read_wav(name)
    st = int(at * sr)
    for j, v in enumerate(cache[name]):
        if st + j < n: mix[st + j] += v * gain * 0.55
events = [("sparkle", 0.3, 0.8), ("complete", total - tl["pad_end"] + 0.4, 0.9)]
if tl.get("auto_whoosh"):
    c = tl["pad_start"]
    for k, sg in enumerate(tl["segments"]):
        if k: events.append(("whoosh", c, 0.5))
        c += (sg["src"][1] - sg["src"][0]) / sg.get("rate", 1.0)
for e in tl.get("sfx", []):
    events.append((e["name"], out_time(e["src"]), e.get("gain", 0.8)))
for name, at, gain in events: sfx(name, at, gain)
peak = max(abs(v) for v in mix) or 1; scale = min(1.0, 0.92 / peak)
with wave.open(os.path.join(OUT, "bed.wav"), "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v * scale)) * 32767)) for v in mix))
print("audio: music loop", round(len(loop) / sr, 1), "s,", len(events), "sound effects")

json.dump(dict(width=W, height=H, hole=hole, pad_start=tl["pad_start"], pad_end=tl["pad_end"], layers=layers,
               segments=segs, video_out=video_out, video_size=[vw, vh]),
          open(os.path.join(OUT, "manifest.json"), "w"), indent=1)
print("assets ready:", len(layers), "caption layers; screen", screen_w, "x", screen_h)
