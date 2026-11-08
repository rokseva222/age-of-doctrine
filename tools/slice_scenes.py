#!/usr/bin/env python3
"""Gemini sahne sayfasını (macenta zeminde 2 sütun x 4 satır, koyu lacivert yuvarlak panel) keser.
Kullanım: python3 tools/slice_scenes.py sayfa.png A|B   ->  assets/scenes/<ad>.jpg (1024x512)"""
import sys, os, numpy as np
from PIL import Image
from scipy import ndimage
SETS = {"A": ["assault", "barrage", "blitz", "naval", "air", "missile", "paradrop", "special"],
        "B": ["landing", "cyber", "spy", "sanction", "trade", "alliance", "war", "peace"]}
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
im = Image.open(sys.argv[1]).convert("RGB")
names = SETS[sys.argv[2].upper()]
a = np.array(im).astype(int)
mag = (a[:, :, 0] > 190) & (a[:, :, 1] < 110) & (a[:, :, 2] > 190)
lab, n = ndimage.label(~mag)
boxes = []
for sl in ndimage.find_objects(lab):
    h, w = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
    if h > im.height * 0.12 and w > im.width * 0.25:
        boxes.append((sl[0].start, sl[1].start, sl[0].stop, sl[1].stop))
rowh = im.height / 4.0
boxes.sort(key=lambda b: (int(((b[0] + b[2]) / 2) / rowh), b[1]))
print("bulunan panel:", len(boxes), "beklenen:", len(names))
out = os.path.join(root, "assets/scenes"); os.makedirs(out, exist_ok=True)
for name, (y0, x0, y1, x1) in zip(names, boxes):
    mh, mw = int((y1 - y0) * 0.035), int((x1 - x0) * 0.025)      # yuvarlak köşe/çerçeve payı
    cell = im.crop((x0 + mw, y0 + mh, x1 - mw, y1 - mh)).resize((1024, 512), Image.LANCZOS)
    cell.save(os.path.join(out, name + ".jpg"), quality=88)
print("kaydedildi ->", out)
