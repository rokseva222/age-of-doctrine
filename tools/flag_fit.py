#!/usr/bin/env python3
"""Kullanıcı görsellerini 480x320 era_<slug>.png'ye çevirir. 3:2'ye yakın bayraklar gerilir; amblem/flama gibi
oranı çok farklı olanlar kenar renginde zemine ortalanır. Kullanım: python3 tools/flag_fit.py src.png slug [zemin_hex]"""
import sys
from PIL import Image
W, H = 480, 320
def fit(src, slug, bg=None):
    im = Image.open(src).convert('RGBA')
    r = im.size[0] / im.size[1]
    if 1.4 <= r <= 2.1:
        out = im.resize((W, H), Image.LANCZOS)
        base = Image.new('RGBA', (W, H), (255, 255, 255, 255)); base.alpha_composite(out); out = base
    else:
        if bg is None:
            px = im.getpixel((3, im.size[1] // 2)); bg = '#%02x%02x%02x' % px[:3] if px[3] > 200 else '#ffffff'
        col = Image.new('RGBA', (W, H), bg)
        s = min(W / im.size[0], H / im.size[1]) * 0.92
        sm = im.resize((int(im.size[0] * s), int(im.size[1] * s)), Image.LANCZOS)
        col.alpha_composite(sm, ((W - sm.size[0]) // 2, (H - sm.size[1]) // 2)); out = col
    out.convert('RGB').save('assets/flags/era_%s.png' % slug)
if __name__ == '__main__':
    fit(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
