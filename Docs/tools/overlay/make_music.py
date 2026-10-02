#!/usr/bin/env python3
"""A short original, gentle looping tune (C - G - Am - F ...) for the demo video.
Soft marimba arpeggio + glassy bell melody + light bass, with a little room reverb. 20 s, loops seamlessly."""
import math, random
SR = 44100
BPM = 96
BEAT = 60 / BPM            # 0.625 s
BAR = 4 * BEAT             # 2.5 s
BARS = 8
LOOP = BAR * BARS          # 20 s

def marimba(freq, dur, vol, decay=7.0):
    n = int(SR * dur); out = []
    for i in range(n):
        t = i / SR
        e1 = min(1.0, t / 0.003) * math.exp(-decay * t)
        e2 = math.exp(-decay * 3.4 * t)
        out.append(vol * (math.sin(2 * math.pi * freq * t) * e1 + 0.30 * math.sin(2 * math.pi * freq * 4.0 * t) * e2) / 1.3)
    return out

def bell(freq, dur, vol, decay=3.2):
    parts = [(1.0, 1.0, 1.0), (2.0, 0.35, 1.7), (2.76, 0.18, 2.4)]
    n = int(SR * dur); out = [0.0] * n
    for ratio, amp, dm in parts:
        w = 2 * math.pi * freq * ratio / SR
        for i in range(n):
            t = i / SR
            out[i] += amp * min(1.0, t / 0.01) * math.exp(-decay * dm * t) * math.sin(w * i)
    return [vol * s / 1.53 for s in out]

def bass(freq, dur, vol):
    n = int(SR * dur)
    return [vol * min(1.0, (i / SR) / 0.01) * math.exp(-2.6 * i / SR) * (math.sin(2 * math.pi * freq * i / SR) + 0.25 * math.sin(4 * math.pi * freq * i / SR)) / 1.25 for i in range(n)]

def reverb(x, wet=0.28, tail=1.2):
    x = x + [0.0] * int(SR * tail)
    def comb(sig, ms, fb):
        d = int(SR * ms / 1000); buf, out, idx = [0.0] * d, [], 0
        for s in sig:
            y = buf[idx]; buf[idx] = s + y * fb; idx = (idx + 1) % d; out.append(y)
        return out
    cs = [comb(x, ms, fb) for ms, fb in ((29.7, 0.78), (37.1, 0.75), (41.1, 0.72), (43.7, 0.70))]
    w = [sum(c[i] for c in cs) / 4 for i in range(len(x))]
    return [a + wet * b for a, b in zip(x, w)]

# note frequencies
N = dict(G2=98.0, A2=110.0, F2=87.31, C3=130.81, A3=220.0, B3=246.94, C4=261.63, D4=293.66, E4=329.63, F3=174.61, G3=196.0,
         G4=392.0, A4=440.0, B4=493.88, C5=523.25, D5=587.33, E5=659.25, F5=698.46, G5=783.99, A5=880.0)
CH = {"C": ([N["C4"], N["E4"], N["G4"]], N["C3"]), "G": ([N["G3"], N["B3"], N["D4"]], N["G2"]),
      "Am": ([N["A3"], N["C4"], N["E4"]], N["A2"]), "F": ([N["F3"], N["A3"], N["C4"]], N["F2"])}
PROG = ["C", "G", "Am", "F", "C", "G", "F", "G"]
MEL = [  # (beat, freq, beats) per bar
    [(0, N["E5"], 2), (2, N["G5"], 1), (3, N["E5"], 1)], [(0, N["D5"], 2), (2, N["B4"], 1), (3, N["D5"], 1)],
    [(0, N["C5"], 2), (2, N["E5"], 1), (3, N["A4"], 1)], [(0, N["A4"], 1), (1, N["C5"], 1), (2, N["F5"], 2)],
    [(0, N["G5"], 2), (2, N["E5"], 1), (3, N["C5"], 1)], [(0, N["B4"], 2), (2, N["D5"], 1), (3, N["G5"], 1)],
    [(0, N["A5"], 2), (2, N["F5"], 1), (3, N["C5"], 1)], [(0, N["D5"], 3)],
]
PAT = [0, 1, 2, 1, 0, 1, 2, 1]

def music_loop():
    n = int(SR * LOOP); buf = [0.0] * n
    def put(tone, at):
        s = int(at * SR)
        for j, v in enumerate(tone):
            if s + j < n: buf[s + j] += v
    for b, name in enumerate(PROG):
        tones, root = CH[name]; t0 = b * BAR
        for e in range(8):
            put(marimba(tones[PAT[e]], 0.7, 0.20), t0 + e * BEAT / 2)
        put(bass(root, 1.8, 0.34), t0); put(bass(root, 1.2, 0.22), t0 + 2 * BEAT)
        for beat, f, beats in MEL[b]:
            put(bell(f, 1.6, 0.28), t0 + beat * BEAT)
    full = reverb(buf)
    out = full[:n]
    for i, v in enumerate(full[n:]):          # wrap the reverb tail onto the start so the loop is seamless
        if i < n: out[i] += v
    peak = max(abs(v) for v in out) or 1
    return [v / peak for v in out]
