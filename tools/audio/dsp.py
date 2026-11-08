"""Küçük sentez kütüphanesi (numpy + scipy): osilatörler, filtreler, davul/enstrüman sesleri, yankı, miks."""
import numpy as np
import scipy.signal as ss

SR = 32000
rng = np.random.default_rng(2027)


def midi(n):
    return 440.0 * 2.0 ** ((n - 69) / 12.0)


NOTES = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def nm(s):
    """'D3' -> midi numarası"""
    name = s[:-1]
    octv = int(s[-1])
    return 12 * (octv + 1) + NOTES[name]


# ------------------------------------------------------------------ filtreler / zarflar

def lp(x, fc, order=2):
    return ss.sosfilt(ss.butter(order, min(fc, SR / 2 - 200), "low", fs=SR, output="sos"), x)


def hp(x, fc, order=2):
    return ss.sosfilt(ss.butter(order, fc, "high", fs=SR, output="sos"), x)


def bp(x, lo, hi, order=2):
    return ss.sosfilt(ss.butter(order, [lo, min(hi, SR / 2 - 200)], "band", fs=SR, output="sos"), x)


def adsr(n, a=0.01, d=0.1, s=0.7, r=0.1):
    e = np.full(n, s, dtype=np.float64)
    na = min(int(a * SR), n)
    if na > 0:
        e[:na] = np.linspace(0.0, 1.0, na, endpoint=False)
    nd = min(int(d * SR), max(n - na, 0))
    if nd > 0:
        e[na:na + nd] = 1.0 + (s - 1.0) * np.linspace(0.0, 1.0, nd, endpoint=False)
    nr = min(int(r * SR), n)
    if nr > 0:
        e[n - nr:] *= np.linspace(1.0, 0.0, nr)
    return e


def tarr(n):
    return np.arange(n) / SR


def saw(f, n, ph=0.0):
    return 2.0 * ((f * tarr(n) + ph) % 1.0) - 1.0


def sq(f, n, duty=0.5):
    return np.where(((f * tarr(n)) % 1.0) < duty, 1.0, -1.0)


def sine(f, n, ph=0.0):
    return np.sin(2 * np.pi * f * tarr(n) + ph)


def noise(n):
    return rng.standard_normal(n)


def norm(x, peak=1.0):
    m = np.max(np.abs(x))
    return x / m * peak if m > 0 else x


# ------------------------------------------------------------------ enstrümanlar

def pad(freqs, d, bright=1600, a=1.2, r=1.5, spread=9.0):
    n = int((d + r) * SR)
    sig = np.zeros(n)
    for f in freqs:
        for c in (-spread, 0.0, spread):
            sig += saw(f * 2 ** (c / 1200.0), n, rng.random())
    sig = lp(sig, bright) / (len(freqs) * 3)
    return sig * adsr(n, a, 0.4, 0.85, r)


def choir(freqs, d, a=1.5, r=1.8):
    p = pad(freqs, d, bright=3000, a=a, r=r, spread=14.0)
    return (bp(p, 600, 1000) * 1.0 + bp(p, 1000, 1600) * 0.7 + bp(p, 2200, 2800) * 0.3) * 2.2


def strings_stac(f, d, vel=1.0):
    n = int((d + 0.08) * SR)
    sig = saw(f, n) + 0.8 * saw(f * 1.004, n, 0.3) + 0.8 * saw(f * 0.996, n, 0.6)
    return lp(sig, 2200) * adsr(n, 0.012, 0.08, 0.55, 0.06) * 0.22 * vel


def brass(f, d, vel=1.0, open_t=0.22):
    n = int((d + 0.15) * SR)
    sig = saw(f, n) + 0.7 * saw(f * 1.004, n, 0.4)
    o = np.clip(tarr(n) / open_t, 0, 1)
    sig = lp(sig, 650) * (1 - o) + lp(sig, 3600) * o
    return sig * adsr(n, 0.05, 0.2, 0.8, 0.14) * 0.3 * vel


def horn(f, d, vel=1.0):
    n = int((d + 0.3) * SR)
    sig = saw(f, n) + 0.6 * saw(f * 0.998, n, 0.2) + 0.4 * sq(f * 2, n)
    vib = 1.0 + 0.004 * np.sin(2 * np.pi * 5.2 * tarr(n)) * np.clip(tarr(n) / 0.5, 0, 1)
    sig = lp(sig * vib, 1400)
    return sig * adsr(n, 0.08, 0.2, 0.85, 0.25) * 0.28 * vel


def accordion(f, d, vel=1.0):
    n = int((d + 0.05) * SR)
    sig = sq(f, n, 0.35) + 0.8 * sq(f * 1.006, n, 0.45) + 0.5 * saw(f * 2, n)
    return bp(sig, 250, 3200) * adsr(n, 0.03, 0.1, 0.8, 0.05) * 0.16 * vel


def pluck(f, d=1.2, vel=1.0, bright=1.0):
    n = int(d * SR)
    t = tarr(n)
    s = np.zeros(n)
    for k in range(1, 9):
        s += (1.0 / k ** 1.1) * np.sin(2 * np.pi * f * k * t * (1 + 0.0004 * k * k)) * np.exp(-t * (2.0 + k * 1.8 / bright))
    return s * 0.35 * vel * adsr(n, 0.002, 0.01, 1.0, 0.05)


def bell(f, d=2.0, vel=1.0):
    n = int(d * SR)
    t = tarr(n)
    mod = np.sin(2 * np.pi * f * 3.5 * t) * 2.2 * np.exp(-t * 3.0)
    return np.sin(2 * np.pi * f * t + mod) * np.exp(-t * 2.2) * 0.3 * vel


def sub(f, d, vel=1.0):
    n = int((d + 0.1) * SR)
    s = np.sin(2 * np.pi * f * tarr(n)) + 0.25 * np.sin(4 * np.pi * f * tarr(n))
    return np.tanh(s * 1.4) * adsr(n, 0.01, 0.1, 0.9, 0.1) * 0.5 * vel


def tuba(f, d, vel=1.0):
    n = int((d + 0.05) * SR)
    s = saw(f, n) + 0.5 * sq(f, n)
    return lp(s, 500) * adsr(n, 0.015, 0.08, 0.7, 0.06) * 0.5 * vel


# ------------------------------------------------------------------ davullar ve efekt dokuları

def kick(vol=1.0, low=45.0):
    n = int(0.45 * SR)
    t = tarr(n)
    f = low + 90 * np.exp(-t * 28)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 8)
    s += noise(n) * np.exp(-t * 400) * 0.25
    return np.tanh(s * 1.6) * 0.8 * vol


def snare(vol=1.0, tone=190.0):
    n = int(0.3 * SR)
    t = tarr(n)
    s = hp(noise(n), 1400) * np.exp(-t * 16) * 0.8 + np.sin(2 * np.pi * tone * t) * np.exp(-t * 28) * 0.5
    return s * vol


def snare_march(vol=1.0):
    n = int(0.14 * SR)
    t = tarr(n)
    return (hp(noise(n), 2000) * np.exp(-t * 40) * 0.7 + np.sin(2 * np.pi * 230 * t) * np.exp(-t * 60) * 0.3) * vol


def tom(f=100.0, d=0.7, vol=1.0):
    n = int(d * SR)
    t = tarr(n)
    fr = f * (1 + 0.6 * np.exp(-t * 22))
    s = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t * 5.5)
    s += lp(noise(n), 800) * np.exp(-t * 80) * 0.3
    return np.tanh(s * 1.3) * 0.8 * vol


def timp(f=70.0, d=1.6, vol=1.0):
    n = int(d * SR)
    t = tarr(n)
    fr = f * (1 + 0.25 * np.exp(-t * 18))
    s = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t * 2.6) + 0.35 * np.sin(2 * np.pi * np.cumsum(fr) * 1.5 / SR) * np.exp(-t * 4)
    s += lp(noise(n), 1200) * np.exp(-t * 60) * 0.25
    return s * 0.7 * vol


def hat(open_=False, vol=1.0):
    n = int((0.25 if open_ else 0.05) * SR)
    t = tarr(n)
    return hp(noise(n), 7500) * np.exp(-t * (14 if open_ else 70)) * 0.35 * vol


def tick_wood(vol=1.0, f=1700.0):
    n = int(0.06 * SR)
    t = tarr(n)
    return (np.sin(2 * np.pi * f * t) * np.exp(-t * 160) + hp(noise(n), 3000) * np.exp(-t * 300) * 0.4) * 0.6 * vol


def cym_swell(d, vol=1.0):
    n = int(d * SR)
    t = tarr(n)
    return hp(noise(n), 4500) * (t / d) ** 2.2 * 0.35 * vol * np.concatenate([np.ones(n - int(0.2 * SR)), np.linspace(1, 0, int(0.2 * SR))])[:n]


def riser(d, vol=1.0, f0=300, f1=6000):
    n = int(d * SR)
    out = np.zeros(n)
    steps = 12
    seg = n // steps
    for k in range(steps):
        fc = f0 * (f1 / f0) ** (k / (steps - 1))
        i = k * seg
        j = n if k == steps - 1 else (k + 1) * seg
        out[i:j] = bp(noise(j - i), fc * 0.6, fc * 1.4)
    t = tarr(n)
    return out * (t / d) ** 1.8 * 0.6 * vol


def boom(d=2.0, vol=1.0):
    n = int(d * SR)
    t = tarr(n)
    s = lp(noise(n), 300) * np.exp(-t * 3.0) * 1.2 + np.sin(2 * np.pi * np.cumsum(38 + 60 * np.exp(-t * 6)) / SR) * np.exp(-t * 2.5)
    s += hp(noise(n), 800) * np.exp(-t * 14) * 0.25
    return np.tanh(s * 1.5) * 0.9 * vol


# ------------------------------------------------------------------ yankı ve miks

def reverb_ir(rt=2.5, damp=3500):
    n = int(rt * SR)
    t = tarr(n)
    outs = []
    for _ in range(2):
        ir = noise(n) * np.exp(-t * (6.9 / rt))
        ir = lp(ir, damp)
        ir[: int(0.01 * SR)] *= np.linspace(0, 1, int(0.01 * SR))
        outs.append(ir)
    return np.stack(outs) * 0.12


def fold(y, N):
    out = np.zeros(N)
    for k in range(0, len(y), N):
        seg = y[k:k + N]
        out[: len(seg)] += seg
    return out


class Mix:
    """Stereo miks: kuru + yankı gönderimi; döngü için kuyruk başa katlanır."""

    def __init__(self, dur, tail=6.0):
        self.N = int(dur * SR)
        self.T = int(tail * SR)
        self.L = np.zeros(self.N + self.T)
        self.R = np.zeros(self.N + self.T)
        self.WL = np.zeros(self.N + self.T)
        self.WR = np.zeros(self.N + self.T)

    def add(self, sig, t0, gain=1.0, pan=0.0, send=0.25):
        i = int(round(t0 * SR))
        if i >= len(self.L) or i < 0:
            return
        j = min(i + len(sig), len(self.L))
        seg = sig[: j - i] * gain
        l = np.cos((pan + 1) * np.pi / 4)
        r = np.sin((pan + 1) * np.pi / 4)
        self.L[i:j] += seg * l
        self.R[i:j] += seg * r
        if send > 0:
            self.WL[i:j] += seg * send * l
            self.WR[i:j] += seg * send * r

    def render(self, rt=2.8, damp=3500, wet=1.0):
        ir = reverb_ir(rt, damp)
        wl = ss.fftconvolve(self.WL, ir[0])
        wr = ss.fftconvolve(self.WR, ir[1])
        L = fold(self.L, self.N) + fold(wl, self.N) * wet
        R = fold(self.R, self.N) + fold(wr, self.N) * wet
        return L, R


def finish(L, R, peak=0.89, drive=1.15):
    st = np.stack([L, R])
    st = np.tanh(st * drive)
    st = st / np.max(np.abs(st)) * peak
    return st


LEVELS = {"music": (0.07, 0.80), "sfx": (0.10, 0.50), "amb": (0.045, 0.50)}


def active_rms(st):
    """Sessiz kısımları saymadan ortalama ses seviyesi (50 ms pencereler)."""
    m = st if st.ndim == 1 else st.mean(axis=0)
    w = int(0.05 * SR)
    n = len(m) // w
    if n < 1:
        return float(np.sqrt(np.mean(m ** 2)) + 1e-9)
    fr = (m[: n * w].reshape(n, w) ** 2).mean(axis=1)
    keep = fr > fr.max() * 0.01
    return float(np.sqrt(fr[keep].mean()) + 1e-9)


def save_ogg(path, st, q=4, kind=None):
    """st: (kanal, örnek) float; kind verilirse tüm sesler aynı seviyeye getirilir (müzik/efekt/ambiyans)."""
    import wave, subprocess, tempfile, os
    if st.ndim == 1:
        st = st[None, :]
    if kind is not None:
        tgt, cap = LEVELS[kind]
        g = tgt / active_rms(st)
        pk = np.max(np.abs(st)) + 1e-9
        g = min(g, cap / pk)
        st = st * g
    data = (np.clip(st, -1, 1).T * 32000).astype(np.int16)
    tmp = tempfile.mktemp(suffix=".wav")
    with wave.open(tmp, "wb") as w:
        w.setnchannels(st.shape[0])
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    os.makedirs(os.path.dirname(path), exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", str(q), path], check=True)
    os.remove(tmp)
