"""Ses efektlerini yumuşatır: bas azaltılır (yüksek geçiren filtre), tiz kenar hafif kısılır, seviye eşitlenir.
Kaynak: assets/audio/sfx_orig/*.ogg (orijinaller)  ->  assets/audio/sfx/*.ogg
Kullanım: python3 tools/audio/soften_sfx.py"""
import os, glob, subprocess, tempfile, shutil
import numpy as np
from scipy.io import wavfile
from dsp import *
ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")
SRC = os.path.join(ROOT, "sfx_orig"); DST = os.path.join(ROOT, "sfx")
HEAVY = {"boom", "cannon", "drumroll", "war", "lose", "win", "alarm", "horn", "siren", "capture", "volley", "mg"}
def load(p):
    tmp = tempfile.mktemp(suffix=".wav")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", p, "-ar", str(SR), "-ac", "1", "-c:a", "pcm_f32le", tmp], check=True)
    sr, x = wavfile.read(tmp); os.remove(tmp); return x.astype(np.float64)
for f in sorted(glob.glob(os.path.join(SRC, "*.ogg"))):
    name = os.path.splitext(os.path.basename(f))[0]
    x = load(f)
    fc = 260 if name in HEAVY else 150
    if name.startswith("amb"):
        fc = 180
    x = hp(x, fc, 3)
    x = lp(x, 7500 if name in HEAVY else 9500, 2)
    # yumuşak sınırlayıcı: ani tepeleri törpüle
    x = np.tanh(x / (np.max(np.abs(x)) + 1e-9) * 1.2)
    kind = "amb" if name.startswith("amb") else "sfx"
    save_ogg(os.path.join(DST, name + ".ogg"), x, q=4, kind=kind)
    print(name, flush=True)
