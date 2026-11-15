#!/usr/bin/env python3
"""Boğuk (yalnızca <2 kHz enerjili) üretilmiş müzikleri parlatır: harmonik uyarıcı (exciter) + alçak frekans temizliği.
Kullanım: python3 tools/audio/brighten_music.py  (assets/audio/music/*.ogg dosyalarını yerinde günceller; 44.1 kHz q6 çıktı)"""
import os, subprocess, tempfile, glob
import numpy as np
import scipy.signal as ss
from scipy.io import wavfile
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MUSIC = os.path.join(ROOT, "assets", "audio", "music")
SR = 44100

def decode(src, tmp):
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", src, "-ac", "2", "-ar", str(SR), "-c:a", "pcm_f32le", tmp], check=True)
    _, x = wavfile.read(tmp)
    return x.astype(np.float32)

def sos(kind, fc, order=2):
    return ss.butter(order, fc, kind, fs=SR, output="sos")

def brighten(x):
    out = np.zeros_like(x)
    for ch in range(x.shape[1]):
        s = x[:, ch].astype(np.float64)
        # 1) bulanık alt bölgeyi temizle: 150 Hz altını kıs
        low = ss.sosfilt(sos("low", 150), s)
        s = s - 0.5 * low
        # 2) harmonik uyarıcı: 700 Hz-2 kHz bandı zarfa göre doyur -> 2.4 kHz üstünde yeni harmonikler
        band = ss.sosfilt(sos("high", 700), s)
        env = ss.sosfilt(sos("low", 15), np.abs(band)) + 1e-4
        drive = np.tanh(4.0 * band / env) * env * 0.5
        exc = ss.sosfilt(sos("high", 2600, 3), drive)
        # 3) hava: bandı ikinci kez doyur (>5 kHz)
        env2 = ss.sosfilt(sos("low", 15), np.abs(exc)) + 1e-4
        air = ss.sosfilt(sos("high", 5200, 2), np.tanh(4.0 * exc / env2) * env2 * 0.5)
        s = s + 4.0 * exc + 2.0 * air
        out[:, ch] = s
    return out

def main():
    files = sorted(glob.glob(os.path.join(MUSIC, "*.ogg")))
    for f in files:
        with tempfile.TemporaryDirectory() as d:
            w = os.path.join(d, "a.wav")
            x = decode(f, w)
            before_rms = float(np.sqrt((x ** 2).mean()))
            y = brighten(x)
            y *= before_rms / max(1e-6, float(np.sqrt((y ** 2).mean())))   # aynı ses seviyesi
            pk = float(np.abs(y).max())
            if pk > 0.89:
                y *= 0.89 / pk
            wavfile.write(w, SR, y.astype(np.float32))
            tmp_ogg = os.path.join(d, "o.ogg")
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", w, "-c:a", "libvorbis", "-q:a", "6", tmp_ogg], check=True)
            os.replace(tmp_ogg, f) if os.path.dirname(tmp_ogg) == os.path.dirname(f) else open(f, "wb").write(open(tmp_ogg, "rb").read())
        print("ok", os.path.basename(f))

if __name__ == "__main__":
    main()
