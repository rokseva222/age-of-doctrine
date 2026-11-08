"""Age of Doctrine ses efektleri (kodla sentez). Çıktı: assets/audio/sfx/*.ogg (mono)."""
import sys, os
import numpy as np
from dsp import *

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "sfx")


def hz(ns):
    return [midi(n) for n in ns]


def pad_to(x, n):
    out = np.zeros(n)
    out[: min(len(x), n)] = x[:n]
    return out


def place(buf, sig, t0, g=1.0):
    i = int(t0 * SR)
    j = min(i + len(sig), len(buf))
    if i < len(buf):
        buf[i:j] += sig[: j - i] * g


def verb(x, rt=1.2, wet=0.3, damp=4000):
    ir = reverb_ir(rt, damp)[0]
    y = ss.fftconvolve(x, ir)[: len(x) + int(rt * SR)]
    out = np.zeros(len(y))
    out[: len(x)] += x
    return out + y * wet * 3.0


def fx_click():
    n = int(0.05 * SR)
    t = tarr(n)
    return (np.sin(2 * np.pi * 1400 * t) * np.exp(-t * 110) * 0.6 + hp(noise(n), 3500) * np.exp(-t * 400) * 0.3)


def fx_tap():
    n = int(0.09 * SR)
    t = tarr(n)
    return np.sin(2 * np.pi * (380 + 700 * t) * t) * np.exp(-t * 38) * 0.6 + lp(noise(n), 900) * np.exp(-t * 90) * 0.25


def fx_tick():
    return tick_wood(0.9, 1800.0)


def fx_tock():
    return tick_wood(0.8, 1250.0)


def fx_key():
    n = int(0.07 * SR)
    t = tarr(n)
    return (hp(noise(n), 1800) * np.exp(-t * 90) * 0.7 + np.sin(2 * np.pi * 520 * t) * np.exp(-t * 120) * 0.4)


def fx_bell():
    return bell(2400.0, 1.2, 0.8)[: int(1.2 * SR)] * 0.8


def fx_news():  # teleks: hızlı tuş dizisi + zil
    buf = np.zeros(int(1.0 * SR))
    for k in range(7):
        place(buf, fx_key() * (0.7 + 0.3 * rng.random()), 0.02 + k * 0.055 + rng.random() * 0.01, 0.8)
    place(buf, fx_bell(), 0.5, 0.45)
    return buf


def fx_stamp():  # mühür
    n = int(0.5 * SR)
    t = tarr(n)
    s = np.sin(2 * np.pi * np.cumsum(120 * np.exp(-t * 12) + 55) / SR) * np.exp(-t * 14)
    s += lp(noise(n), 1500) * np.exp(-t * 60) * 0.7
    return np.tanh(s * 1.4) * 0.8


def fx_paper():
    n = int(0.25 * SR)
    t = tarr(n)
    return bp(noise(n), 1500, 7000) * (np.exp(-t * 14) * (0.6 + 0.4 * np.sin(2 * np.pi * 38 * t) ** 2)) * 0.45


def fx_coin():
    buf = np.zeros(int(0.7 * SR))
    place(buf, bell(2637.0, 0.5, 0.9), 0.0, 0.7)
    place(buf, bell(3520.0, 0.5, 0.9), 0.07, 0.7)
    place(buf, hp(noise(int(0.04 * SR)), 4000) * 0.5, 0.0, 0.5)
    return buf


def fx_horn():
    n = int(1.6 * SR)
    f = 92.0
    sig = saw(f, n) + 0.8 * saw(f * 1.5, n) + 0.5 * saw(f * 2.01, n)
    sig = lp(sig, 900)
    env = adsr(n, 0.15, 0.2, 0.85, 0.7)
    return verb(sig * env * 0.4, 1.5, 0.25)


def fx_cannon():
    n = int(2.0 * SR)
    t = tarr(n)
    body = np.sin(2 * np.pi * np.cumsum(55 + 160 * np.exp(-t * 18)) / SR) * np.exp(-t * 4.5)
    crack = hp(noise(n), 1200) * np.exp(-t * 40) * 0.9
    rumble = lp(noise(n), 250) * np.exp(-t * 2.4) * 1.2
    s = np.tanh((body + crack + rumble) * 1.5) * 0.9
    return verb(s, 1.8, 0.35)


def fx_boom():
    return pad_to(boom(2.6, 1.0), int(2.6 * SR))


def fx_volley():
    buf = np.zeros(int(1.6 * SR))
    for k in range(34):
        t0 = float(rng.uniform(0, 0.55))
        n = int(0.1 * SR)
        t = tarr(n)
        shot = hp(noise(n), 900) * np.exp(-t * 70) * rng.uniform(0.4, 1.0)
        place(buf, shot, t0, 0.5)
    for k in range(18):
        t0 = float(rng.uniform(0.5, 1.4))
        n = int(0.08 * SR)
        place(buf, hp(noise(n), 1200) * np.exp(-tarr(n) * 80) * rng.uniform(0.1, 0.4), t0, 0.5)
    return verb(buf, 1.4, 0.3)


def fx_mg():
    buf = np.zeros(int(1.2 * SR))
    for k in range(18):
        n = int(0.06 * SR)
        shot = hp(noise(n), 1000) * np.exp(-tarr(n) * 90) + np.sin(2 * np.pi * 180 * tarr(n)) * np.exp(-tarr(n) * 70) * 0.5
        place(buf, shot, 0.03 + k * 0.058 + rng.random() * 0.004, 0.7)
    return verb(buf, 1.0, 0.25)


def fx_plane():  # pervane uçağı geçişi (Doppler)
    d = 3.6
    n = int(d * SR)
    t = tarr(n)
    fr = 70 + 25 * np.tanh((0.5 - t / d) * 4.0) * -1 + 25
    ph = np.cumsum(fr) / SR * 2 * np.pi
    eng = np.zeros(n)
    for h in range(1, 8):
        eng += np.sin(ph * h) / h
    eng = lp(eng * (1 + 0.3 * np.sin(2 * np.pi * 14 * t)), 1200)
    env = np.exp(-((t - d * 0.5) / (d * 0.28)) ** 2)
    pan_filter = lp(eng, 3000)
    return (pan_filter * env + lp(noise(n), 900) * env * 0.12) * 0.55


def fx_sonar():
    n = int(2.4 * SR)
    t = tarr(n)
    s = np.sin(2 * np.pi * 1180 * t) * np.exp(-t * 7) * adsr(n, 0.003, 0.01, 1.0, 0.01)
    return verb(s * 0.6, 2.0, 0.5, 3000)


def fx_siren():
    d = 3.8
    n = int(d * SR)
    t = tarr(n)
    f = 520 + 380 * (0.5 - 0.5 * np.cos(2 * np.pi * t / 1.9))
    ph = np.cumsum(f) / SR * 2 * np.pi
    s = np.sin(ph) + 0.4 * np.sin(2 * ph) + 0.2 * np.sin(3 * ph)
    s = lp(s, 3500) * adsr(n, 0.3, 0.1, 1.0, 0.8)
    return verb(s * 0.45, 1.8, 0.3)


def fx_radio():  # telsiz: statik + bip
    buf = np.zeros(int(0.9 * SR))
    place(buf, bp(noise(int(0.12 * SR)), 800, 3500) * 0.6, 0.0)
    place(buf, np.sin(2 * np.pi * 1000 * tarr(int(0.09 * SR))) * 0.3 * adsr(int(0.09 * SR), 0.005, 0.01, 1.0, 0.01), 0.14)
    place(buf, bp(noise(int(0.4 * SR)), 600, 3000) * np.exp(-tarr(int(0.4 * SR)) * 6) * 0.4, 0.25)
    return buf


def fx_order():  # emir: kısa telsiz blip
    buf = np.zeros(int(0.35 * SR))
    place(buf, bp(noise(int(0.05 * SR)), 900, 3500) * 0.5, 0.0)
    n = int(0.07 * SR)
    place(buf, np.sin(2 * np.pi * 1500 * tarr(n)) * 0.35 * adsr(n, 0.004, 0.01, 1.0, 0.01), 0.06)
    place(buf, bp(noise(int(0.08 * SR)), 900, 3500) * np.exp(-tarr(int(0.08 * SR)) * 25) * 0.4, 0.15)
    return buf


def fx_cyber():  # glitch
    buf = np.zeros(int(0.9 * SR))
    for k in range(9):
        n = int(rng.uniform(0.02, 0.07) * SR)
        f = float(rng.choice([300, 600, 1200, 2400, 4800]))
        seg = sq(f, n, 0.5) * 0.25 if rng.random() < 0.5 else noise(n) * 0.2
        place(buf, seg * adsr(n, 0.002, 0.01, 1.0, 0.005), k * 0.09 + rng.random() * 0.02, 1.0)
    return buf


def fx_alarm():
    buf = np.zeros(int(1.0 * SR))
    for k in range(4):
        n = int(0.12 * SR)
        place(buf, (sq(880, n, 0.5) * 0.3 + sq(1760, n) * 0.1) * adsr(n, 0.004, 0.02, 0.9, 0.02), k * 0.22)
    return buf


def fx_error():
    n = int(0.22 * SR)
    return sq(150, n) * 0.35 * np.exp(-tarr(n) * 12) + sq(112, n) * 0.25 * np.exp(-tarr(n) * 12)


def fx_capture():
    buf = np.zeros(int(1.3 * SR))
    for k, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
        place(buf, brass(f, 0.28, 0.9) * 1.6, k * 0.11, 0.8)
    place(buf, timp(98.0, 0.9, 0.9), 0.0, 0.6)
    return verb(buf, 1.4, 0.25)


def fx_peace():
    buf = np.zeros(int(2.4 * SR))
    for k, f in enumerate([261.63, 329.63, 392.0, 523.25]):
        place(buf, pad([f], 1.2, 2500, 0.2, 1.0), k * 0.18, 0.8)
        place(buf, bell(f * 4, 1.5, 0.5), k * 0.18, 0.4)
    return verb(buf, 2.0, 0.3)


def fx_win():
    n = int(7.0 * SR)
    buf = np.zeros(n)
    notes = [(0.0, "C4", 0.5), (0.5, "G4", 0.5), (1.0, "C5", 0.5), (1.5, "E5", 1.0), (2.5, "D5", 0.5), (3.0, "G5", 2.5)]
    for t0, nn, d in notes:
        f = midi(nm(nn))
        place(buf, brass(f, d, 1.1) * 1.5, t0, 0.8)
        place(buf, brass(f / 2, d, 0.9) * 1.2, t0, 0.5)
    for t0 in (0.0, 1.5, 3.0):
        place(buf, timp(midi(nm("C3")), 1.5, 1.0), t0, 0.8)
    place(buf, cym_swell(3.0, 1.0), 0.0, 0.0)
    place(buf, pad(hz([nm("C4"), nm("E4"), nm("G4"), nm("C5")]), 4.0, 2800, 0.6, 2.0), 2.8, 0.5)
    place(buf, boom(2.5, 0.6), 3.0, 0.5)
    return verb(buf, 2.4, 0.3)


def fx_lose():
    n = int(7.0 * SR)
    buf = np.zeros(n)
    notes = [(0.0, "C4", 1.0), (1.2, "Bb3", 1.0), (2.4, "Ab3", 1.2), (3.8, "G3", 3.0)]
    for t0, nn, d in notes:
        f = midi(nm(nn))
        place(buf, horn(f, d, 1.0) * 1.3, t0, 0.8)
        place(buf, horn(f / 2, d, 0.8), t0, 0.5)
    for t0 in (0.0, 2.4, 3.8):
        place(buf, timp(midi(nm("C2")), 2.2, 1.0), t0, 0.9)
    place(buf, pad(hz([nm("C3"), nm("Eb3"), nm("G3")]), 4.0, 1200, 1.0, 2.5), 3.6, 0.6)
    return verb(buf, 3.0, 0.35)


def fx_war():  # savaş ilanı
    n = int(3.6 * SR)
    buf = np.zeros(n)
    place(buf, pad(hz([nm("E2"), nm("B2"), nm("E3")]), 2.4, 900, 0.3, 1.5), 0.0, 0.9)
    for k in range(3):
        place(buf, timp(midi(nm("E2")), 1.6, 1.0), k * 0.5, 0.9)
    place(buf, riser(1.6, 1.0), 0.0, 0.6)
    place(buf, boom(2.2, 1.0), 1.5, 0.9)
    place(buf, brass(midi(nm("E3")), 1.8, 1.0) * 1.4, 1.5, 0.7)
    return verb(buf, 2.0, 0.3)


def fx_drumroll():
    n = int(2.0 * SR)
    buf = np.zeros(n)
    k = 0
    t0 = 0.0
    while t0 < 1.7:
        place(buf, snare_march(0.25 + 0.7 * (t0 / 1.7)), t0, 0.8)
        t0 += 0.045
    place(buf, cym_swell(0.3, 0.8), 1.7, 0.5)
    return verb(buf, 1.0, 0.2)


def fx_recruit():  # kısa borazan/komut
    buf = np.zeros(int(0.9 * SR))
    for k, f in enumerate([392.0, 392.0, 523.25]):
        place(buf, brass(f, 0.18, 1.0, 0.05) * 1.6, k * 0.2, 0.7)
    return verb(buf, 0.8, 0.2)


def fx_amb_war():  # döngüsel savaş ambiyansı: rüzgâr + uzak top gürültüsü
    d = 24.0
    n = int(d * SR)
    t = tarr(n)
    wind = bp(noise(n), 120, 700) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 8.0 + 1.0) ** 2) * 0.4
    rum = lp(noise(n), 160) * 0.3
    buf = wind + rum
    for k in range(9):
        t0 = float(rng.uniform(0.5, d - 4))
        b = lp(noise(int(3.0 * SR)), 220) * np.exp(-tarr(int(3.0 * SR)) * 1.6) * rng.uniform(0.5, 1.0)
        place(buf, b, t0, 0.9)
        if rng.random() < 0.6:
            place(buf, hp(noise(int(0.2 * SR)), 600) * np.exp(-tarr(int(0.2 * SR)) * 25) * 0.15, t0, 0.5)
    # kesintisiz döngü: sonu başa çapraz geçiş
    fade = int(1.5 * SR)
    head = buf[:fade].copy()
    tailv = buf[-fade:].copy()
    w = np.linspace(0, 1, fade)
    buf[:fade] = head * w + tailv * (1 - w)
    return buf[: n - fade]


FX = {n[3:]: f for n, f in globals().items() if n.startswith("fx_")}

if __name__ == "__main__":
    which = sys.argv[1:] or list(FX)
    for name in which:
        x = FX[name]()
        x = np.nan_to_num(x)
        x = np.tanh(x * 1.1)
        pk = np.max(np.abs(x))
        x = x / pk * (0.9 if name != "amb_war" else 0.7)
        save_ogg(os.path.join(OUT, name + ".ogg"), x, q=5, kind="amb" if name == "amb_war" else "sfx")
        print("%-10s %.2f sn  tepe=%.2f" % (name, len(x) / SR, pk), flush=True)
