#!/usr/bin/env python3
"""Synthesizes CivAware's sound effects (original, royalty-free) as 16-bit mono WAVs.

Design goals: warm and rewarding, never harsh. Bell/marimba partials give
body, a soft attack avoids clicks, pitch glides add "juice", and a small
Schroeder reverb adds space. Wrong answers are gentle, never a buzzer.
"""
import math, random, struct, wave, os

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "../../CongressionalAppChallenge/Resources/Sounds")
random.seed(11)

# ---------- building blocks ----------
def bell(freq, dur, vol=1.0, decay=5.0, attack=0.003, brightness=1.0):
    """Struck-bell timbre: inharmonic partials, higher ones die faster."""
    partials = [(1.0, 1.0, 1.0), (2.0, 0.45, 1.6), (2.76, 0.30 * brightness, 2.2), (5.4, 0.12 * brightness, 3.4)]
    n = int(SR * dur)
    out = [0.0] * n
    for ratio, amp, dmul in partials:
        w = 2 * math.pi * freq * ratio / SR
        for i in range(n):
            t = i / SR
            env = min(1.0, t / attack) * math.exp(-decay * dmul * t)
            out[i] += amp * env * math.sin(w * i)
    norm = sum(a for _, a, _ in partials)
    return [vol * s / norm for s in out]

def marimba(freq, dur, vol=1.0, decay=9.0):
    """Warm wooden mallet: fundamental plus a fast-fading 4th harmonic."""
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e1 = min(1.0, t / 0.002) * math.exp(-decay * t)
        e2 = math.exp(-decay * 3.2 * t)
        s = math.sin(2 * math.pi * freq * t) * e1 + 0.35 * math.sin(2 * math.pi * freq * 4.0 * t) * e2
        out.append(vol * s / 1.3)
    return out

def glide(f0, f1, dur, vol=1.0, decay=10.0, shape=3.0):
    """Sine with an exponential pitch glide (bloops, thumps)."""
    n = int(SR * dur)
    out, phase = [], 0.0
    for i in range(n):
        t = i / SR
        f = f1 + (f0 - f1) * math.exp(-shape * t / dur * 3)
        phase += 2 * math.pi * f / SR
        out.append(vol * math.exp(-decay * t) * math.sin(phase) * min(1.0, t / 0.002))
    return out

def noise(dur, vol=1.0, decay=40.0):
    return [vol * random.uniform(-1, 1) * math.exp(-decay * i / SR) for i in range(int(SR * dur))]

def lowpass(x, cutoff):
    a = 1 - math.exp(-2 * math.pi * cutoff / SR)
    y, out = 0.0, []
    for s in x:
        y += a * (s - y)
        out.append(y)
    return out

def swept_lowpass(x, c0, c1):
    y, out, n = 0.0, [], len(x)
    for i, s in enumerate(x):
        p = i / n
        c = c0 + (c1 - c0) * math.sin(math.pi * p)   # up then back down
        y += (1 - math.exp(-2 * math.pi * c / SR)) * (s - y)
        out.append(y)
    return out

def highpass(x, cutoff):
    lp = lowpass(x, cutoff)
    return [a - b for a, b in zip(x, lp)]

def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    return out

def at(track, seconds):
    return [0.0] * int(SR * seconds) + track

def reverb(x, wet=0.22, tail=0.6):
    """Small Schroeder reverb: 4 combs + 2 allpasses."""
    x = x + [0.0] * int(SR * tail)
    def comb(sig, delay_ms, fb):
        d = int(SR * delay_ms / 1000)
        buf, out = [0.0] * d, []
        idx = 0
        for s in sig:
            y = buf[idx]
            buf[idx] = s + y * fb
            idx = (idx + 1) % d
            out.append(y)
        return out
    def allpass(sig, delay_ms, g=0.5):
        d = int(SR * delay_ms / 1000)
        buf, out = [0.0] * d, []
        idx = 0
        for s in sig:
            b = buf[idx]
            y = -g * s + b
            buf[idx] = s + g * b
            idx = (idx + 1) % d
            out.append(y)
        return out
    combs = [comb(x, d, f) for d, f in ((29.7, 0.77), (37.1, 0.74), (41.1, 0.71), (43.7, 0.69))]
    wet_sig = [sum(c[i] for c in combs) / 4 for i in range(len(x))]
    wet_sig = allpass(allpass(wet_sig, 5.0), 1.7)
    return [d + wet * w for d, w in zip(x, wet_sig)]

def save(name, samples, level=0.8):
    # fade the last 15 ms so nothing clicks
    fade = int(SR * 0.015)
    for i in range(min(fade, len(samples))):
        samples[-1 - i] *= i / fade
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = level / peak
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767)) for s in samples))

# Notes (Hz). C major pentatonic keeps everything consonant.
C5, D5, E5, G5, A5, C6, D6, E6, G6 = 523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66, 1318.5, 1567.98

# ---------- the sounds ----------

# Tap: a soft, dry "tick", like a fingertip on wood. Very quiet.
tick = mix(lowpass(noise(0.03, 1.0, 140), 2800), glide(1700, 1300, 0.04, 0.5, decay=90))
save("tap", tick, level=0.32)

# Pop: a quick rising bubble-bloop. Feels like selecting something.
save("pop", mix(glide(380, 760, 0.11, 1.0, decay=22, shape=1.5), noise(0.008, 0.25, 300)), level=0.5)

# Correct: two bright marimba/bell notes rising a fifth ("ding-DING!"), with sparkle and room.
correct = mix(
    marimba(G5, 0.5, 0.9, decay=7), bell(G5 * 2, 0.5, 0.25, decay=8),
    at(marimba(D6, 0.8, 1.0, decay=5), 0.085), at(bell(D6 * 2, 0.8, 0.3, decay=6), 0.085),
)
save("correct", reverb(correct, wet=0.2, tail=0.5), level=0.8)

# Wrong: a soft, low, falling "bloop-bop". Gentle and never a buzzer.
wrong = mix(
    lowpass(glide(300, 240, 0.22, 1.0, decay=9), 1400),
    at(lowpass(glide(240, 175, 0.32, 1.0, decay=8), 1200), 0.14),
)
save("wrong", reverb(wrong, wet=0.1, tail=0.3), level=0.6)

# Complete: rising pentatonic run that lands on a shimmering held chord.
run = [C5, E5, G5, C6, E6]
notes = [at(bell(f, 0.9, 0.7, decay=4.5) if i < 4 else bell(f, 1.6, 0.9, decay=2.8), i * 0.085) for i, f in enumerate(run)]
chord = mix(at(bell(C6, 1.2, 0.5, decay=3.2), 0.42), at(bell(E6, 1.2, 0.45, decay=3.2), 0.42), at(bell(G6, 1.2, 0.4, decay=3.2), 0.42))
save("complete", reverb(mix(*notes, chord), wet=0.3, tail=0.5), level=0.85)

# Sparkle: a quick cascade of high bell notes (badges, checkmarks).
seq = [E6, G6, C6 * 2, G6, D6 * 2, C6 * 2 * 1.26]
sp = [at(bell(f, 0.5, 0.6, decay=9, brightness=1.4), i * 0.055) for i, f in enumerate(seq)]
save("sparkle", reverb(mix(*sp), wet=0.25, tail=0.5), level=0.6)

# Gavel: one crisp wooden knock: sharp transient, a woody thunk, short room.
knock = mix(
    highpass(lowpass(noise(0.05, 1.0, 90), 3500), 500),
    glide(220, 95, 0.22, 1.1, decay=17, shape=2.0),
    lowpass(glide(520, 300, 0.08, 0.6, decay=45), 1800),
)
save("gavel", reverb(knock, wet=0.18, tail=0.4), level=0.9)

# Whoosh: airy filtered noise that swells and fades. Used for moving on.
air = swept_lowpass(noise(0.34, 1.0, 0.0), 350, 4200)
air = [s * math.sin(math.pi * i / len(air)) ** 1.6 for i, s in enumerate(air)]
save("whoosh", air, level=0.32)

print("wrote sounds to", os.path.abspath(OUT))
