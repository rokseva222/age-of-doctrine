#!/usr/bin/env python3
"""Gemini ikon ızgarasını keser: python3 tools/place_icons.py <ızgara.png> <sütun> <satır> <ad1,ad2,...> [çıkış=assets/icons]
Her hücre: beyaz arka plan şeffaflaştırılır (kenardan taşma ile), içerik kırpılır, kare tuvale ortalanır, 256x256 <ad>_c.png yazılır."""
import sys
from PIL import Image, ImageDraw
src, cols, rows, names = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4].split(",")
out = sys.argv[5] if len(sys.argv) > 5 else "assets/icons"
im = Image.open(src).convert("RGBA")
W, H = im.size
cw, ch = W / cols, H / rows
for i, n in enumerate(names):
    r, c = divmod(i, cols)
    cell = im.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch))).convert("RGBA")
    # kenardan beyaz arka planı şeffaflaştır
    w, h = cell.size
    px = cell.load()
    seen = [[False] * h for _ in range(w)]
    stack = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    def is_bg(p): return p[0] > 236 and p[1] > 236 and p[2] > 236
    while stack:
        x, y = stack.pop()
        if x < 0 or y < 0 or x >= w or y >= h or seen[x][y]:
            continue
        seen[x][y] = True
        if not is_bg(px[x, y]):
            continue
        px[x, y] = (255, 255, 255, 0)
        stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    bb = cell.getbbox()
    if bb is None:
        print("boş hücre:", n); continue
    cell = cell.crop(bb)
    s = max(cell.size)
    pad = int(s * 0.06)
    canvas = Image.new("RGBA", (s + 2 * pad, s + 2 * pad), (0, 0, 0, 0))
    canvas.paste(cell, ((s + 2 * pad - cell.size[0]) // 2, (s + 2 * pad - cell.size[1]) // 2), cell)
    canvas = canvas.resize((256, 256), Image.LANCZOS)
    canvas.save("%s/%s_c.png" % (out, n))
    print("yazıldı:", n)
