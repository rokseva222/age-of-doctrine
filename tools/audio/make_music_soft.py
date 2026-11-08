"""Age of Doctrine - YUMUŞAK fon müzikleri (sakin, davulsuz, hi-hat/tıkırtı yok, bas çok hafif).
Çıktı: assets/audio/music/*.ogg (döngüsel). Kullanım: python3 tools/audio/make_music_soft.py [menu|peace|war|ww1|ww2|coldwar]"""
import sys, os
import numpy as np
from dsp import *

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "music")


def chord(root, kind):
    iv = {"m": (0, 3, 7), "M": (0, 4, 7), "7": (0, 4, 7, 10), "sus": (0, 5, 7)}[kind]
    return [root + i for i in iv]


def hz(ms):
    return [midi(x) for x in ms]


def cello(f, d, vel=1.0):
    """Yumuşak, uzun yaylı nota (testere + hafif vibrato, düşük parlaklık)."""
    n = int((d + 0.5) * SR)
    t = tarr(n)
    vib = 1.0 + 0.005 * np.sin(2 * np.pi * 5.0 * t) * np.clip((t - 0.4) / 0.8, 0, 1)
    ph = 2 * np.pi * np.cumsum(f * vib) / SR
    sig = np.zeros(n)
    for k in range(1, 8):
        sig += np.sin(k * ph) / (k ** 1.3)
        sig += 0.6 * np.sin(k * ph * 1.004) / (k ** 1.3)
    return lp(sig, 1500) * adsr(n, 0.35, 0.3, 0.85, 0.5) * 0.22 * vel


def soft_horn(f, d, vel=1.0):
    n = int((d + 0.5) * SR)
    sig = saw(f, n) + 0.6 * saw(f * 0.997, n, 0.3)
    vib = 1.0 + 0.003 * np.sin(2 * np.pi * 4.6 * tarr(n))
    return lp(sig * vib, 900) * adsr(n, 0.5, 0.3, 0.8, 0.6) * 0.2 * vel


def felt(f, d=2.2, vel=1.0):
    """Yumuşak piyano: sabit, yumuşak vuruş."""
    n = int(d * SR)
    t = tarr(n)
    s = np.zeros(n)
    for k in range(1, 6):
        s += (1.0 / k ** 1.4) * np.sin(2 * np.pi * f * k * t) * np.exp(-t * (1.1 + k * 0.9))
    return lp(s, 2400) * 0.4 * vel * adsr(n, 0.012, 0.02, 1.0, 0.2)


def ping(f, d=3.5, vel=1.0):
    n = int(d * SR)
    t = tarr(n)
    return np.sin(2 * np.pi * f * t) * np.exp(-t * 1.6) * 0.18 * vel * adsr(n, 0.01, 0.01, 1.0, 0.4)


def soft_timp(f=98.0, vel=1.0):
    n = int(2.2 * SR)
    t = tarr(n)
    body = np.sin(2 * np.pi * (f + 14 * np.exp(-t * 14)) * t) * np.exp(-t * 2.6)
    return lp(body, 600) * 0.28 * vel * adsr(n, 0.01, 0.1, 0.9, 0.2)


def melody(scale, bars, bpm, rng_, chords_by_bar, density=0.55, lo=0, hi=None):
    """Seyrek, adım adım ilerleyen melodi: [(bar, beat, midi_note, beats)]"""
    hi = hi or len(scale) - 1
    idx = (lo + hi) // 2
    out = []
    for b in range(bars):
        beat = 0.0
        while beat < 4.0:
            if rng_.random() < density:
                step = int(rng_.choice([-2, -1, -1, 0, 1, 1, 2]))
                idx = int(np.clip(idx + step, lo, hi))
                note = scale[idx]
                if beat == 0.0:  # bar başında akor sesine yaklaş
                    ch = chords_by_bar[b]
                    cands = [c for c in range(lo, hi + 1) if scale[c] % 12 in [x % 12 for x in ch]]
                    if cands:
                        idx = min(cands, key=lambda c: abs(c - idx))
                        note = scale[idx]
                ln = float(rng_.choice([2.0, 3.0, 4.0]))
                ln = min(ln, 4.0 - beat) if beat + ln > 4.0 else ln
                out.append((b, beat, note, ln))
                beat += ln
            else:
                beat += 1.0
    return out


def build(name, bpm, prog, scale, seed, cfg):
    beat = 60.0 / bpm
    bars = cfg["bars"]
    m = Mix(bars * 4 * beat)
    r = np.random.default_rng(seed)
    chords = []
    for b in range(bars):
        root, kind = prog[(b // cfg.get("bars_per_chord", 2)) % len(prog)]
        chords.append(chord(root, kind))
    for b in range(bars):
        t0 = b * 4 * beat
        ch = chords[b]
        root = ch[0]
        first = (b % cfg.get("bars_per_chord", 2)) == 0
        if first:
            span = cfg.get("bars_per_chord", 2) * 4 * beat
            m.add(pad(hz([c + 12 for c in ch]), span - 0.5, bright=cfg.get("bright", 1100), a=2.8, r=3.0), t0, cfg.get("pad", 0.38), send=0.6)
            if cfg.get("bass", True):
                m.add(cello(midi(root + 12), span - 0.4, 0.9), t0, 0.5, pan=-0.2, send=0.4)
            if b >= cfg.get("strings_from", 4):
                m.add(choir(hz([ch[1] + 12, ch[2] + 12]), span - 0.8, a=3.2, r=3.4), t0, cfg.get("choir", 0.10), pan=0.2, send=0.8)
        # piyano / arp
        if cfg.get("arp") and b >= cfg.get("arp_from", 2):
            pat = cfg["arp"]
            for q, pidx in pat:
                note = ch[pidx % len(ch)] + 24
                m.add(felt(midi(note), 2.4, 0.8), t0 + q * beat, cfg.get("arp_g", 0.32), pan=-0.2 + 0.4 * ((q * 2) % 2), send=0.7)
        if cfg.get("timp") and b >= 4 and b % 2 == 0:
            m.add(soft_timp(midi(root + 12), 0.8), t0, cfg["timp"], send=0.6)
        if cfg.get("ping") and b % 4 == 2:
            m.add(ping(midi(ch[2] + 36), 3.5, 0.8), t0 + 1 * beat, cfg["ping"], pan=0.6, send=1.0)
            m.add(ping(midi(ch[2] + 36), 3.5, 0.3), t0 + 1 * beat + 0.75, cfg["ping"], pan=-0.6, send=1.0)
    # ana melodi
    if cfg.get("mel"):
        inst, g = cfg["mel"]
        notes = melody(scale, bars, bpm, r, chords, cfg.get("density", 0.5), cfg.get("lo", 2), cfg.get("hi"))
        for (b, bt, note, ln) in notes:
            if b < cfg.get("mel_from", 6):
                continue
            t = (b * 4 + bt) * beat
            f = midi(note)
            if inst == "felt":
                m.add(felt(f, 2.8, 0.9), t, g, pan=0.15, send=0.8)
            elif inst == "cello":
                m.add(cello(f, ln * beat * 0.95, 1.0), t, g, pan=0.1, send=0.6)
            elif inst == "horn":
                m.add(soft_horn(f, ln * beat * 0.95, 1.0), t, g, pan=0.15, send=0.7)
            elif inst == "bell":
                m.add(felt(f, 3.0, 0.8), t, g, pan=0.2, send=0.9)
    L, R = m.render(rt=3.6, damp=2600)
    return bp(L, 95, 6000), bp(R, 95, 6000)


S_DMIN = [nm(x) for x in ("D3", "E3", "F3", "G3", "A3", "Bb3", "C4", "D4", "E4", "F4", "G4", "A4", "Bb4", "C5", "D5")]
S_CMAJ = [nm(x) for x in ("C3", "D3", "E3", "G3", "A3", "C4", "D4", "E4", "G4", "A4", "C5", "D5", "E5", "G5")]
S_EMIN = [nm(x) for x in ("E3", "G3", "A3", "B3", "D4", "E4", "G4", "A4", "B4", "D5", "E5")]
S_EBMAJ = [nm(x) for x in ("Eb3", "F3", "G3", "Bb3", "C4", "Eb4", "F4", "G4", "Bb4", "C5", "Eb5")]
S_AMIN = [nm(x) for x in ("A3", "B3", "C4", "D4", "E4", "G4", "A4", "B4", "C5", "D5", "E5")]


def track_menu():
    return build("menu", 66, [(nm("D2"), "m"), (nm("Bb1"), "M"), (nm("G2"), "m"), (nm("A1"), "7")], S_DMIN, 11,
                 {"bars": 24, "arp": [(0, 0), (2, 1)], "arp_g": 0.26, "mel": ("felt", 0.30), "density": 0.45, "bright": 1000, "choir": 0.09, "timp": 0.18})


def track_peace():
    return build("peace", 60, [(nm("C3"), "M"), (nm("A2"), "m"), (nm("F2"), "M"), (nm("G2"), "M")], S_CMAJ, 21,
                 {"bars": 24, "arp": [(0, 0), (1, 1), (2, 2), (3, 1)], "arp_g": 0.2, "arp_from": 1, "mel": ("bell", 0.28), "density": 0.4, "bright": 1300, "pad": 0.34, "choir": 0.07, "strings_from": 8})


def track_war():
    return build("war", 72, [(nm("E2"), "m"), (nm("C2"), "M"), (nm("A2"), "m"), (nm("B1"), "M")], S_EMIN, 31,
                 {"bars": 24, "mel": ("cello", 0.55), "density": 0.55, "bright": 900, "pad": 0.36, "choir": 0.08, "timp": 0.22, "mel_from": 4, "lo": 0, "hi": 6, "strings_from": 2})


def track_ww1():
    return build("ww1", 56, [(nm("D2"), "m"), (nm("G2"), "m"), (nm("A1"), "m"), (nm("D2"), "m"), (nm("Bb1"), "M"), (nm("F2"), "M"), (nm("C2"), "M"), (nm("A1"), "7")], S_DMIN, 41,
                 {"bars": 32, "arp": [(0, 0), (2, 2)], "arp_g": 0.18, "arp_from": 4, "mel": ("cello", 0.6), "density": 0.5, "bright": 900, "pad": 0.3, "choir": 0.06, "mel_from": 2, "lo": 0, "hi": 7})


def track_ww2():
    return build("ww2", 70, [(nm("Eb2"), "M"), (nm("Bb1"), "M"), (nm("C2"), "m"), (nm("Ab1"), "M")], S_EBMAJ, 51,
                 {"bars": 24, "mel": ("horn", 0.5), "density": 0.5, "bright": 1100, "pad": 0.36, "choir": 0.1, "timp": 0.2, "mel_from": 4, "lo": 1, "hi": 8})


def track_coldwar():
    return build("coldwar", 52, [(nm("A1"), "m"), (nm("F2"), "M"), (nm("D2"), "m"), (nm("E2"), "m")], S_AMIN, 61,
                 {"bars": 24, "arp": [(0, 2)], "arp_g": 0.2, "arp_from": 4, "mel": ("felt", 0.22), "density": 0.3, "bright": 800, "pad": 0.4, "choir": 0.0, "ping": 0.5, "bass": False, "mel_from": 8})


TRACKS = {"menu": track_menu, "peace": track_peace, "war": track_war, "ww1": track_ww1, "ww2": track_ww2, "coldwar": track_coldwar}

if __name__ == "__main__":
    which = sys.argv[1:] or list(TRACKS)
    for name in which:
        L, R = TRACKS[name]()
        st = finish(L, R, drive=1.0)
        path = os.path.join(OUT, name + ".ogg")
        save_ogg(path, st, q=4, kind="music")
        print(name, "%.1f sn" % (st.shape[1] / SR), "tepe=%.2f" % np.max(np.abs(st)), os.path.getsize(path) // 1024, "KB", flush=True)
