#!/usr/bin/env python3
"""Düz renkli (vektörsü) ikon/portre PNG'lerini keskinleştirir: renk paleti çıkarır, 4x büyütür,
kenarları yumuşatıp her pikseli en yakın palet rengine atar. Kullanım: crisp.py girdi.png çıktı.png [k=14] [ölçek=4]"""
import sys, numpy as np
from PIL import Image
from scipy import ndimage
def crisp(src, k=14, scale=4):
    im = Image.open(src).convert("RGBA")
    a = np.array(im).astype(np.float32)
    h, w = a.shape[:2]
    alpha = a[:, :, 3] / 255.0
    rgb = a[:, :, :3]
    # palet: opak piksellerde k-means (basit, birkaç yineleme)
    px = rgb[alpha > 0.9].reshape(-1, 3)
    rng = np.random.default_rng(1)
    cent = px[rng.choice(len(px), k, replace=False)]
    for _ in range(12):
        d = ((px[:, None, :] - cent[None]) ** 2).sum(-1)
        lab = d.argmin(1)
        for i in range(k):
            m = px[lab == i]
            if len(m): cent[i] = m.mean(0)
    # çok yakın renkleri birleştir
    keep = []
    for i in range(k):
        if all(np.linalg.norm(cent[i] - cent[j]) > 18 for j in keep): keep.append(i)
    cent = cent[keep]
    big = np.array(im.resize((w * scale, h * scale), Image.BICUBIC)).astype(np.float32)
    big_rgb = ndimage.gaussian_filter(big[:, :, :3], sigma=(scale * 0.55, scale * 0.55, 0))
    big_a = ndimage.gaussian_filter(big[:, :, 3] / 255.0, scale * 1.1)
    d = ((big_rgb[:, :, None, :] - cent[None, None]) ** 2).sum(-1)
    idx = d.argmin(2)
    idx = ndimage.median_filter(idx, size=scale * 2 + 1)
    out_rgb = cent[idx]
    # alfa: yumuşak eşik (kenar antialias)
    al = np.clip((big_a - 0.5) * 9.0 + 0.5, 0, 1)
    out = np.dstack([out_rgb, al * 255]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")
if __name__ == "__main__":
    k = int(sys.argv[3]) if len(sys.argv) > 3 else 14
    s = int(sys.argv[4]) if len(sys.argv) > 4 else 4
    crisp(sys.argv[1], k, s).save(sys.argv[2])
