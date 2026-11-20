#!/usr/bin/env python3
"""Beyaz zeminli siyah siluet amblem sayfalarını keser -> assets/icons/fl_<ad>.png (256x256, beyaz + şeffaf; bayrak rengine boyanır)
Kullanım: python3 tools/slice_masks.py sayfa.png ad1,ad2,...   (satır satır, soldan sağa sırayla adlandırılır)"""
import sys, os
from PIL import Image, ImageFilter
import numpy as np
from collections import deque
src = sys.argv[1]
names = sys.argv[2].split(",")
want = len(names)
pref = "fl"
im = Image.open(src).convert("RGB"); a = np.array(im).astype(int); H, W, _ = a.shape
bg = (a.min(axis=2) >= 243)          # beyaz zemin
# zemin = kenardan ulaşılan beyaz bölge
seen = np.zeros((H, W), bool); dq = deque()
for x in range(W):
    for y in (0, H - 1):
        if bg[y, x] and not seen[y, x]: seen[y, x] = True; dq.append((y, x))
for y in range(H):
    for x in (0, W - 1):
        if bg[y, x] and not seen[y, x]: seen[y, x] = True; dq.append((y, x))
while dq:
    y, x = dq.popleft()
    for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
        ny, nx = y + dy, x + dx
        if 0 <= ny < H and 0 <= nx < W and bg[ny, nx] and not seen[ny, nx]:
            seen[ny, nx] = True; dq.append((ny, nx))
fg = ~seen
# bileşenler
lab = np.zeros((H, W), int); n = 0; comps = []
for y0 in range(H):
    for x0 in range(W):
        if fg[y0, x0] and lab[y0, x0] == 0:
            n += 1; lab[y0, x0] = n; dq = deque([(y0, x0)]); pts = 0; ys = [y0]; xs = [x0]
            ymin = ymax = y0; xmin = xmax = x0
            while dq:
                y, x = dq.popleft(); pts += 1
                ymin = min(ymin, y); ymax = max(ymax, y); xmin = min(xmin, x); xmax = max(xmax, x)
                for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < H and 0 <= nx < W and fg[ny, nx] and lab[ny, nx] == 0:
                        lab[ny, nx] = n; dq.append((ny, nx))
            comps.append((n, pts, xmin, ymin, xmax, ymax))
comps = [c for c in comps if c[1] > 2500]
if want and len(comps) != want: print("UYARI: bulunan", len(comps), "beklenen", want)
# satırlara ayır (merkez y), sonra x'e göre sırala
comps.sort(key=lambda c: (c[3] + c[5]) / 2)
rows = []; 
for c in comps:
    cy = (c[3] + c[5]) / 2
    if rows and abs(cy - rows[-1][0]) < 70: rows[-1][1].append(c)
    else: rows.append([cy, [c]])
order = []
for _, r in rows: order += sorted(r, key=lambda c: c[2])
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "icons")
for i, (lid, pts, x0, y0, x1, y1) in enumerate(order):
    m = (lab[y0:y1+1, x0:x1+1] == lid)
    # kapalı iç boşlukları da doldur (tek bileşen içinde kalan beyazlar korunur)
    # siluet: koyuluk = opaklık (kenar yumuşatması korunur), renk beyaz
    lum = a[y0:y1+1, x0:x1+1].mean(axis=2)
    alpha = (np.clip((255 - lum) / 200.0, 0, 1) * 255 * m).astype(np.uint8)
    t = Image.fromarray(np.dstack([np.full(alpha.shape + (3,), 255, np.uint8), alpha]), "RGBA")
    w, h = t.size; s = max(w, h) + 8
    sq = Image.new("RGBA", (s, s), (0, 0, 0, 0)); sq.paste(t, ((s - w) // 2, (s - h) // 2))
    sq = sq.resize((256, 256), Image.LANCZOS)
    if i < len(names):
        sq.save(os.path.join(out, "fl_%s.png" % names[i]))
print(pref, len(order), "adet")
