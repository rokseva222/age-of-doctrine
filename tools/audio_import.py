#!/usr/bin/env python3
"""Suno (veya başka) ses dosyalarını oyuna aktarır.
Kullanım: python3 tools/audio_import.py <klasör>
Dosya adları:  music_<ad>.mp3|wav|m4a  -> assets/audio/music/<ad>.ogg  (kesintisiz döngü yapılır, -16 LUFS)
               sfx_<ad>.mp3|wav|m4a    -> assets/audio/sfx/<ad>.ogg    (baş/son sessizlik kırpılır, tepe -1 dB)
Örn: music_menu.mp3, music_war.mp3, sfx_war.mp3, sfx_win.mp3"""
import sys, os, subprocess, tempfile, glob
import numpy as np
from scipy.io import wavfile
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SR = 44100
def run(*a): subprocess.run(a, check=True, capture_output=True)
def decode(src, tmp):
    run('ffmpeg', '-y', '-i', src, '-ac', '2', '-ar', str(SR), '-c:a', 'pcm_f32le', tmp)
    sr, x = wavfile.read(tmp); return x.astype(np.float32)
def loop(x, xf=4.0):
    n = int(xf * SR)
    if len(x) < n * 3: return x
    # baştaki/sondaki sessizliği kırp
    a = np.abs(x).max(axis=1); idx = np.where(a > 0.01)[0]
    x = x[idx[0]:idx[-1] + 1]
    head, tail = x[:n], x[-n:]
    t = np.linspace(0, 1, n)[:, None]
    mix = tail * np.cos(t * np.pi / 2) + head * np.sin(t * np.pi / 2)   # eşit güçlü çapraz geçiş
    return np.concatenate([mix, x[n:-n]])   # son kısım başa bağlanır
def trim_sfx(x):
    a = np.abs(x).max(axis=1); idx = np.where(a > 0.004)[0]
    if len(idx) == 0: return x
    x = x[max(0, idx[0] - 200): idx[-1] + 2000]
    f = int(0.02 * SR); x[-f:] *= np.linspace(1, 0, f)[:, None]
    return x
def norm_peak(x, db=-1.0):
    return x * (10 ** (db / 20) / max(1e-6, np.abs(x).max()))
def write_ogg(x, dst, lufs=None):
    with tempfile.TemporaryDirectory() as d:
        w = os.path.join(d, 'o.wav'); wavfile.write(w, SR, x.astype(np.float32))
        af = [f'loudnorm=I={lufs}:TP=-1.5:LRA=11'] if lufs else []
        cmd = ['ffmpeg', '-y', '-i', w] + (['-af', ','.join(af)] if af else []) + ['-c:a', 'libvorbis', '-q:a', '5', dst]
        run(*cmd)
def main():
    src = sys.argv[1]
    for f in sorted(glob.glob(os.path.join(src, '*'))):
        b = os.path.basename(f); stem, ext = os.path.splitext(b)
        if ext.lower() not in ('.mp3', '.wav', '.m4a', '.ogg', '.flac'): continue
        if stem.startswith('music_'): kind, name = 'music', stem[6:]
        elif stem.startswith('sfx_'): kind, name = 'sfx', stem[4:]
        else: print('atlandı (music_/sfx_ ile başlamıyor):', b); continue
        with tempfile.TemporaryDirectory() as d:
            x = decode(f, os.path.join(d, 'i.wav'))
        dst = os.path.join(ROOT, 'assets/audio', kind, name + '.ogg')
        if kind == 'music': write_ogg(loop(x), dst, lufs=-16)
        else: write_ogg(norm_peak(trim_sfx(x)), dst)
        print('tamam:', b, '->', os.path.relpath(dst, ROOT), '(%.1f sn)' % (len(x) / SR))
main()
