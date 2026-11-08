"""Age of Doctrine müzikleri: tamamen kodla üretilir (numpy). Çıktı: assets/audio/music/*.ogg (döngüsel).
Kullanım: python3 tools/audio/make_music.py [menu|peace|war|ww1|ww2 ...]"""
import sys, os
import numpy as np
from dsp import *

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "music")


def chord(root, kind):
    iv = {"m": (0, 3, 7), "M": (0, 4, 7), "5": (0, 7, 12), "7": (0, 4, 7, 10), "dim": (0, 3, 6)}[kind]
    return [root + i for i in iv]


def hz(ms):
    return [midi(m) for m in ms]


# ------------------------------------------------------------------ MENÜ: soğuk, tehditkâr ambiyans (Re minör)
def track_menu():
    bpm = 60.0
    beat = 60.0 / bpm
    bars = 16
    dur = bars * 4 * beat
    m = Mix(dur)
    prog = [(nm("D2"), "m"), (nm("Bb1"), "M"), (nm("G2"), "m"), (nm("A1"), "7")]
    for k in range(4):
        i = k * 8.0 * beat
        root, kind = prog[k % 4]
        for rep in range(2):
            t0 = (rep * 32 + k * 8) * beat
            ch = chord(root + 12, kind)
            m.add(pad(hz(ch + [ch[0] + 12]), 8 * beat - 0.5, bright=1100, a=2.5, r=2.5), t0, 0.5, send=0.5)
            m.add(sub(midi(root), 8 * beat, 0.9), t0, 0.6, send=0.1)
            m.add(choir(hz([ch[1] + 12, ch[2] + 12]), 8 * beat - 1.0, a=3.0, r=3.0), t0, 0.14 if rep else 0.08, pan=-0.2 + 0.4 * rep, send=0.7)
    # kalp atışı
    for b in range(bars):
        for off, v in ((0.0, 0.5), (0.75, 0.32)):
            m.add(kick(v, 40.0), (b * 4 + off) * beat, 0.7, send=0.3)
    # seyrek pluck melodisi (Re minör pentatonik)
    scale = [nm("D4"), nm("F4"), nm("G4"), nm("A4"), nm("C5"), nm("D5")]
    for b in range(bars):
        for q in range(4):
            if rng.random() < 0.32:
                n_ = scale[int(rng.integers(0, len(scale)))]
                t0 = (b * 4 + q + rng.choice([0.0, 0.5])) * beat
                m.add(pluck(midi(n_), 2.5, 0.8, 0.7), t0, 0.5, pan=float(rng.uniform(-0.6, 0.6)), send=0.9)
    # sonar / telsiz
    for b in (2, 10):
        m.add(bell(midi(nm("A5")), 3.0, 0.6), b * 4 * beat + 2 * beat, 0.35, pan=0.5, send=1.0)
    for _ in range(40):
        t0 = float(rng.uniform(0, dur - 1))
        m.add(hp(noise(int(0.012 * SR)), 2500) * 0.4, t0, 0.18, pan=float(rng.uniform(-1, 1)), send=0.3)
    return m.render(rt=4.2, damp=2800)


# ------------------------------------------------------------------ BARIŞ: stratejik, saat tiktaklı (Do minör)
def track_peace():
    bpm = 96.0
    beat = 60.0 / bpm
    bars = 24
    dur = bars * 4 * beat
    m = Mix(dur)
    prog = [(nm("C3"), "m"), (nm("Ab2"), "M"), (nm("Eb3"), "M"), (nm("Bb2"), "M")]
    for b in range(bars):
        root, kind = prog[b % 4]
        t0 = b * 4 * beat
        ch = chord(root, kind)
        m.add(pad(hz([c + 12 for c in ch] + [ch[0] + 24]), 4 * beat, bright=1800, a=0.9, r=1.2), t0, 0.35, send=0.45)
        m.add(sub(midi(root - 12), 4 * beat, 0.8), t0, 0.55, send=0.1)
        if b >= 4:  # arpej
            pat = [0, 1, 2, 1, 2, 1, 0, 1]
            for q in range(8):
                note = ch[pat[q] % len(ch)] + 24
                m.add(pluck(midi(note), 0.7, 0.8), t0 + q * 0.5 * beat, 0.42, pan=-0.3 + 0.1 * (q % 3), send=0.5)
        if b >= 8:  # saat tiktağı
            for q in range(8):
                m.add(tick_wood(0.8 if q % 2 == 0 else 0.5, 1700 if q % 2 == 0 else 1300), t0 + q * 0.5 * beat, 0.35, pan=0.4 if q % 2 else -0.4, send=0.15)
            m.add(kick(0.7, 48.0), t0, 0.7, send=0.1)
            m.add(kick(0.55, 48.0), t0 + 2 * beat, 0.7, send=0.1)
            for q in range(4):
                m.add(hat(False, 0.7), t0 + (q + 0.5) * beat, 0.5, pan=0.3, send=0.1)
        if 16 <= b < 24 and b % 2 == 0:  # melodi: yaylı/korno
            mel = [nm("G4"), nm("Eb4"), nm("F4"), nm("G4"), nm("Bb4"), nm("G4"), nm("F4"), nm("Eb4")]
            for q in range(4):
                m.add(horn(midi(mel[(b // 2 * 4 + q) % len(mel)]), 1.6 * beat, 0.8), t0 + q * 2 * beat, 0.3, pan=0.25, send=0.7)
    m.add(riser(2.0, 0.6), dur - 2.0, 0.3, send=0.1)
    return m.render(rt=2.6, damp=3800)


# ------------------------------------------------------------------ SAVAŞ: sürükleyici, davullu (Mi minör)
def track_war():
    bpm = 118.0
    beat = 60.0 / bpm
    bars = 32
    dur = bars * 4 * beat
    m = Mix(dur)
    prog = [(nm("E2"), "m"), (nm("C2"), "M"), (nm("G2"), "M"), (nm("D2"), "M")]
    for b in range(bars):
        root, kind = prog[b % 4]
        t0 = b * 4 * beat
        ch = chord(root + 12, kind)
        # alçak yaylı ostinato (8'lik)
        if b >= 2:
            for q in range(8):
                acc = 1.0 if q % 4 == 0 else 0.62
                m.add(strings_stac(midi(root), 0.38 * beat, acc), t0 + q * 0.5 * beat, 0.8, send=0.2)
        m.add(sub(midi(root - 12), 4 * beat, 0.9), t0, 0.5, send=0.05)
        m.add(pad(hz([c + 12 for c in ch]), 4 * beat, bright=2200, a=0.5, r=0.8), t0, 0.22, send=0.5)
        # davullar
        if b >= 4:
            m.add(kick(1.0, 42.0), t0, 0.9, send=0.15)
            m.add(kick(0.8, 42.0), t0 + 2.5 * beat, 0.8, send=0.15)
            m.add(snare(0.9), t0 + 1 * beat, 0.75, send=0.45)
            m.add(snare(0.9), t0 + 3 * beat, 0.75, send=0.45)
            for q in (0.75, 1.75, 3.5):
                m.add(tom(95 if q < 3 else 120, 0.6, 0.8), t0 + q * beat, 0.7, pan=-0.3 if q < 3 else 0.3, send=0.5)
        if b >= 8:
            for q in range(8):
                m.add(hat(q % 4 == 3, 0.7), t0 + q * 0.5 * beat, 0.45, pan=0.35, send=0.1)
        # korno darbeleri: güç akoru
        if b % 4 == 0 and b >= 4:
            for nt in (root + 12, root + 19, root + 24):
                m.add(brass(midi(nt), 2.2 * beat, 1.0), t0, 0.55, send=0.5)
        if b % 4 == 2 and b >= 12:
            for nt in (root + 24, root + 31):
                m.add(brass(midi(nt), 1.0 * beat, 0.9), t0 + 0 * beat, 0.4, pan=0.2, send=0.5)
        # koro
        if 16 <= b < 28:
            m.add(choir(hz([ch[1] + 12, ch[2] + 12, ch[0] + 24]), 4 * beat - 0.3, a=1.0, r=0.8), t0, 0.16, pan=-0.2, send=0.8)
        if b in (7, 15, 23, 31):
            m.add(riser(4 * beat, 0.8), t0, 0.35, send=0.2)
            m.add(cym_swell(4 * beat, 0.9), t0, 0.4, send=0.3)
            for q in range(8):
                m.add(snare_march(0.5 + 0.06 * q), t0 + (2 + q * 0.25) * beat, 0.7, send=0.3)
        if b in (8, 16, 24):
            m.add(boom(2.0, 0.7), t0, 0.5, send=0.4)
    return m.render(rt=2.2, damp=3200)


# ------------------------------------------------------------------ 1. DÜNYA SAVAŞI: marş, tuba/akordeon (Re minör)
def vintage(L, R):
    # gramofon hissi: bant sınırlama + hafif cızırtı
    L = bp(L, 140, 6500)
    R = bp(R, 140, 6500)
    n = len(L)
    hiss = hp(noise(n), 3000) * 0.0025
    crackle = np.zeros(n)
    idx = rng.integers(0, n, int(n / SR * 3.0))
    crackle[idx] = rng.uniform(0.02, 0.07, len(idx)) * rng.choice([-1, 1], len(idx))
    crackle = lp(crackle, 5000)
    return L + hiss + crackle, R + hiss + np.roll(crackle, 777)


def track_ww1():
    bpm = 92.0
    beat = 60.0 / bpm
    bars = 24
    dur = bars * 4 * beat
    m = Mix(dur)
    prog = [(nm("D2"), "m"), (nm("G2"), "m"), (nm("A2"), "M"), (nm("D2"), "m")]
    melA = [(0, "D4", 1), (1, "F4", .5), (1.5, "A4", .5), (2, "D5", 1.5), (3.5, "C5", .5),
            (4, "Bb4", 1), (5, "A4", .5), (5.5, "G4", .5), (6, "A4", 2),
            (8, "E4", 1), (9, "G4", .5), (9.5, "Bb4", .5), (10, "A4", 1.5), (11.5, "G4", .5),
            (12, "F4", 1), (13, "E4", .5), (14, "D4", .5), (14.5, "E4", .5), (15, "D4", 1)]
    for b in range(bars):
        root, kind = prog[b % 4]
        t0 = b * 4 * beat
        ch = chord(root + 12, kind)
        # oom-pah
        m.add(tuba(midi(root), 0.9 * beat, 1.0), t0, 0.7, send=0.2)
        m.add(tuba(midi(root + (7 if kind == "m" else 7)), 0.9 * beat, 0.9), t0 + 2 * beat, 0.7, send=0.2)
        for q in (1, 3):
            for nt in ch:
                m.add(accordion(midi(nt + 12), 0.55 * beat, 0.9), t0 + q * beat, 0.5, pan=-0.2, send=0.25)
        # trampet: marş ritmi
        for q, v in ((0, 1.0), (0.5, 0.5), (1, 0.8), (1.5, 0.5), (2, 1.0), (2.5, 0.5), (3, 0.8), (3.25, 0.5), (3.5, 0.7), (3.75, 0.5)):
            m.add(snare_march(0.6 * v), t0 + q * beat, 0.6, pan=0.3, send=0.25)
        if b % 4 == 0:
            m.add(timp(midi(root + 12), 1.8, 0.8), t0, 0.5, send=0.5)
        # melodi (4 ölçülük cümle, 8 ölçüde bir)
        if b >= 4 and (b // 4) % 2 == 0:
            for (off, nn, ln) in melA:
                if off // 4 == b % 4:
                    m.add(brass(midi(nm(nn)), ln * beat * 0.95, 0.9), t0 + (off - (b % 4) * 4) * beat, 0.55, pan=0.15, send=0.6)
        if b >= 12 and (b // 4) % 2 == 1:
            for (off, nn, ln) in melA:
                if off // 4 == b % 4:
                    m.add(accordion(midi(nm(nn)), ln * beat, 1.2), t0 + (off - (b % 4) * 4) * beat, 0.7, send=0.5)
        if b in (11, 23):
            for q in range(12):
                m.add(snare_march(0.4 + 0.05 * q), t0 + (2 + q * 0.16) * beat, 0.7, send=0.3)
    L, R = m.render(rt=1.6, damp=3000)
    return vintage(L, R)


# ------------------------------------------------------------------ 2. DÜNYA SAVAŞI: sinematik, bakır nefesli, timpani (Do minör)
def track_ww2():
    bpm = 84.0
    beat = 60.0 / bpm
    bars = 24
    dur = bars * 4 * beat
    m = Mix(dur)
    prog = [(nm("C2"), "m"), (nm("Ab1"), "M"), (nm("F2"), "m"), (nm("G2"), "M")]
    mel = {0: [(0, "G4", 2), (2, "C5", 1), (3, "Bb4", 1)], 1: [(0, "Ab4", 2), (2, "G4", 1), (3, "F4", 1)],
           2: [(0, "F4", 1.5), (1.5, "Ab4", .5), (2, "C5", 2)], 3: [(0, "D5", 2), (2, "B4", 1), (3, "G4", 1)]}
    for b in range(bars):
        root, kind = prog[b % 4]
        t0 = b * 4 * beat
        ch = chord(root + 12, kind)
        m.add(sub(midi(root), 4 * beat, 1.0), t0, 0.6, send=0.05)
        m.add(pad(hz([c + 12 for c in ch] + [ch[0] + 24]), 4 * beat, bright=1500, a=1.2, r=1.2), t0, 0.32, send=0.55)
        # tremolo yaylılar
        if b >= 2:
            f_ = midi(ch[1] + 12)
            for q in range(16):
                m.add(strings_stac(f_, 0.22 * beat, 0.8 if q % 4 else 1.0), t0 + q * 0.25 * beat, 0.55, pan=-0.3, send=0.4)
        # timpani kalp atışı
        m.add(timp(midi(root + 12), 1.4, 1.0), t0, 0.7, send=0.5)
        if b >= 6:
            m.add(timp(midi(root + 12), 1.0, 0.7), t0 + 1.5 * beat, 0.55, send=0.5)
            m.add(timp(midi(root + 19), 1.0, 0.6), t0 + 2.5 * beat, 0.5, send=0.5)
            m.add(tom(70, 0.8, 0.9), t0 + 3 * beat, 0.5, send=0.5)
        # alçak bakır ostinato
        if b >= 8:
            for q in (0, 1.5, 3):
                m.add(brass(midi(root + 12), 0.9 * beat, 1.0, 0.1), t0 + q * beat, 0.5, pan=0.15, send=0.4)
        # korno melodisi
        if b >= 4 and b < 20:
            for (off, nn, ln) in mel[b % 4]:
                m.add(horn(midi(nm(nn)), ln * beat * 0.97, 1.0), t0 + off * beat, 0.65 if b >= 12 else 0.45, pan=0.2, send=0.7)
                if b >= 12:
                    m.add(horn(midi(nm(nn)) / 2.0, ln * beat * 0.97, 0.8), t0 + off * beat, 0.4, pan=-0.2, send=0.7)
        if 12 <= b < 22:
            m.add(choir(hz([ch[2] + 24, ch[0] + 24]), 4 * beat - 0.3, a=1.2, r=1.0), t0, 0.14, send=0.8)
        if b in (7, 15, 23):
            m.add(riser(4 * beat, 0.9), t0, 0.35, send=0.2)
            m.add(cym_swell(4 * beat, 0.9), t0, 0.35, send=0.3)
            for q in range(12):
                m.add(snare_march(0.4 + 0.05 * q), t0 + (2 + q * 0.16) * beat, 0.6, send=0.3)
        if b in (8, 16):
            m.add(boom(2.4, 0.7), t0, 0.5, send=0.4)
    L, R = m.render(rt=2.8, damp=3000)
    return bp(L, 90, 9000), bp(R, 90, 9000)


TRACKS = {"menu": track_menu, "peace": track_peace, "war": track_war, "ww1": track_ww1, "ww2": track_ww2}

if __name__ == "__main__":
    which = sys.argv[1:] or list(TRACKS)
    for name in which:
        L, R = TRACKS[name]()
        st = finish(L, R)
        path = os.path.join(OUT, name + ".ogg")
        save_ogg(path, st, q=4, kind="music")
        print(name, "%.1f sn" % (st.shape[1] / SR), "tepe=%.2f rms=%.3f" % (np.max(np.abs(st)), np.sqrt(np.mean(st ** 2))), os.path.getsize(path) // 1024, "KB", flush=True)
