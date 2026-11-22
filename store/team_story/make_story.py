#!/usr/bin/env python3
"""Rok Games Studios - "Ekibimizi Tanıyın" Instagram story üreticisi.

Kullanım:
    python3 store/team_story/make_story.py [team.json] [--config config.json] [--out klasör] [--only hepsi|grup|tekli]

Yalnızca Python3 + Pillow gerekir. Ayrıntılar için README.md.
"""
import argparse
import json
import math
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
FONT_DIR = os.path.join(REPO, "assets", "fonts")

# --- Varsayılan ayarlar (config.json bunların üstüne yazar) -----------------
DEFAULTS = {
    "width": 1080,
    "height": 1920,
    # Instagram arayüzü üstte ve altta içeriği kapatır: önemli şeyleri bu sınırların içinde tut.
    "safe_top": 170,
    "safe_bottom": 210,
    "margin_x": 70,
    "logo": "assets/rok_logo.png",
    "logo_height": 150,
    "title": "EKİBİMİZİ TANIYIN",
    "subtitle": "ROK GAMES STUDIOS",
    "game_name": "Age of Doctrine",
    "badge": "YAKINDA · GOOGLE PLAY",
    "footer_note": "",            # istersen oyun adının altına kısa bir cümle (boşsa görünmez)
    "member_label": "PERSONEL",   # tekli karelerde "PERSONEL 02 / 05" etiketi (boşsa gizli)
    "show_index": True,           # kartlarda 01, 02... numarası
    "name_case": "upper",         # "upper" = BÜYÜK HARF (Türkçe kurallı), "as_is" = olduğu gibi
    "photo_shape": "circle",      # "circle" veya "rounded"
    "photo_focus": [0.5, 0.2],    # kırpmada kaydırma payı: x orta, y yukarı ağırlıklı (yüz için)
    "placeholder_name": "İSİM SOYİSİM",
    "placeholder_role": "Unvan",
    "colors": {
        "bg": "#0b0e12",
        "panel": "#14181e",
        "panel_hi": "#20262e",
        "line": "#39414b",
        "paper": "#ece6d6",
        "paper_dim": "#cfc8b6",
        "text": "#ede9de",
        "muted": "#9aa2ad",
        "faint": "#646c77",
        "red": "#e5482f",
    },
}

MAX_PER_PAGE = 8


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


# --- Türkçe metin yardımcıları ------------------------------------------------
def tr_upper(s):
    return s.replace("i", "İ").replace("ı", "I").upper()


def slugify(s):
    tbl = str.maketrans("çğıöşüÇĞİÖŞÜ", "cgiosuCGIOSU")
    s = s.translate(tbl).lower()
    s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
    return s or "uye"


def initials(name):
    words = [w for w in re.split(r"\s+", name.strip()) if w]
    if not words:
        return "?"
    if len(words) == 1:
        return tr_upper(words[0][:2])
    return tr_upper(words[0][0] + words[-1][0])


# --- Yazı tipi ----------------------------------------------------------------
_font_cache = {}


def font(fname, size):
    key = (fname, int(size))
    if key not in _font_cache:
        _font_cache[key] = ImageFont.truetype(os.path.join(FONT_DIR, fname), int(size))
    return _font_cache[key]


HEAD = "BigShoulders-Bold.ttf"
BODY = "InstrumentSans-Regular.ttf"
BODY_B = "InstrumentSans-Bold.ttf"
MONO = "IBMPlexMono-Regular.ttf"
MONO_B = "IBMPlexMono-Bold.ttf"


def text_w(text, f, tracking=0):
    if not text:
        return 0
    return f.getlength(text) + tracking * (len(text) - 1)


def draw_text(d, xy, text, f, fill, anchor="la", tracking=0):
    """Harf aralıklı yazı desteği olan metin çizimi. anchor: l/m/r + a (üst) / s (taban) / m (orta)."""
    x, y = xy
    if tracking == 0:
        d.text((x, y), text, font=f, fill=fill, anchor=anchor)
        return
    w = text_w(text, f, tracking)
    h = anchor[0]
    x0 = x if h == "l" else (x - w / 2 if h == "m" else x - w)
    v = "l" + anchor[1]
    for ch in text:
        d.text((x0, y), ch, font=f, fill=fill, anchor=v)
        x0 += f.getlength(ch) + tracking


def wrap_lines(text, f, width, max_lines):
    """Kelimelere göre böl. 2 satırda en dengeli bölünmeyi seçer; sığmazsa None."""
    words = text.split()
    if not words:
        return [""]
    if text_w(text, f) <= width:
        return [text]
    if max_lines == 1:
        return None
    if max_lines == 2:
        best = None
        for i in range(1, len(words)):
            a, b = " ".join(words[:i]), " ".join(words[i:])
            m = max(text_w(a, f), text_w(b, f))
            if m <= width and (best is None or m < best[0]):
                best = (m, [a, b])
        return best[1] if best else None
    lines, cur = [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if text_w(t, f) <= width:
            cur = t
        else:
            if not cur:
                return None
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    if len(lines) > max_lines or any(text_w(l, f) > width for l in lines):
        return None
    return lines


def ellipsize(text, f, width):
    if text_w(text, f) <= width:
        return text
    while text and text_w(text + "…", f) > width:
        text = text[:-1]
    return text.rstrip() + "…"


def fit_text(text, fname, width, max_size, min_size, max_lines=2, single_shrink=0.75):
    """Önce tek satırda küçülterek (max_size*single_shrink'e kadar), sonra çok satıra bölerek,
    en son min_size'da '…' ile keserek sığdır. (satırlar, yazı tipi, satır yüksekliği) döner."""
    text = " ".join(text.split())
    max_size, min_size = int(max_size), int(max(8, min_size))
    max_size = max(max_size, min_size)
    plan = []
    lo1 = max(min_size, int(max_size * single_shrink))
    plan.append((1, range(max_size, lo1 - 1, -2)))
    if max_lines >= 2:
        plan.append((max_lines, range(max_size, min_size - 1, -2)))
    for nl, sizes in plan:
        for s in sizes:
            f = font(fname, s)
            lines = wrap_lines(text, f, width, nl)
            if lines:
                return lines, f, s * 1.14
    # son çare: min boyutta kes ve '…' koy
    f = font(fname, min_size)
    lines = wrap_lines(text, f, width, max_lines)
    if lines is None:
        words, lines, cur = text.split(), [], ""
        for w in words:
            t = (cur + " " + w).strip()
            if text_w(t, f) <= width or not cur and len(lines) >= max_lines - 1:
                cur = t
            elif len(lines) < max_lines - 1:
                lines.append(cur)
                cur = w
            else:
                cur = t
        lines.append(cur)
        lines = lines[:max_lines]
        lines[-1] = ellipsize(lines[-1], f, width)
    return lines, f, min_size * 1.14


def draw_block(d, x, y, lines, f, lh, fill, align="l"):
    """Satırları üstten başlayarak çizer; toplam yüksekliği döndürür."""
    anchor = {"l": "la", "m": "ma", "r": "ra"}[align]
    for i, l in enumerate(lines):
        d.text((x, y + i * lh), l, font=f, fill=fill, anchor=anchor)
    return lh * len(lines)


# --- Fotoğraf -----------------------------------------------------------------
def crop_square(im, focus):
    w, h = im.size
    s = min(w, h)
    fx, fy = focus
    x0 = int(round((w - s) * fx))
    y0 = int(round((h - s) * fy))
    return im.crop((x0, y0, x0 + s, y0 + s))


def shape_mask(size, shape, ss=4):
    big = Image.new("L", (size * ss, size * ss), 0)
    d = ImageDraw.Draw(big)
    if shape == "rounded":
        d.rounded_rectangle((0, 0, size * ss - 1, size * ss - 1), radius=int(size * ss * 0.14), fill=255)
    else:
        d.ellipse((0, 0, size * ss - 1, size * ss - 1), fill=255)
    return big.resize((size, size), Image.LANCZOS)


def make_portrait(member, size, cfg, col, base_dir):
    """Maskelenmiş, çerçeveli fotoğraf (RGBA, size x size). Fotoğraf yoksa baş harfli yer tutucu."""
    shape = cfg["photo_shape"]
    ring = max(3, size // 70)       # dış ince çizgi
    gap = max(5, size // 40)        # çizgi ile fotoğraf arası boşluk
    inner = size - 2 * (ring + gap)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ss = 4

    def ring_layer():
        big = Image.new("L", (size * ss, size * ss), 0)
        dd = ImageDraw.Draw(big)
        if shape == "rounded":
            r = int(size * ss * 0.14)
            dd.rounded_rectangle((0, 0, size * ss - 1, size * ss - 1), radius=r, fill=255)
            dd.rounded_rectangle((ring * ss, ring * ss, (size - ring) * ss - 1, (size - ring) * ss - 1),
                                 radius=max(1, r - ring * ss), fill=0)
        else:
            dd.ellipse((0, 0, size * ss - 1, size * ss - 1), fill=255)
            dd.ellipse((ring * ss, ring * ss, (size - ring) * ss - 1, (size - ring) * ss - 1), fill=0)
        return big.resize((size, size), Image.LANCZOS)

    ph = None
    path = (member.get("photo") or "").strip()
    if path:
        p = path if os.path.isabs(path) else os.path.join(base_dir, path)
        if os.path.isfile(p):
            try:
                im = ImageOps.exif_transpose(Image.open(p)).convert("RGB")
                focus = member.get("focus") or cfg["photo_focus"]
                ph = crop_square(im, focus).resize((inner, inner), Image.LANCZOS)
            except Exception as e:  # bozuk dosya
                print(f"  ! Fotoğraf okunamadı ({path}): {e} -> yer tutucu kullanılıyor", file=sys.stderr)
        else:
            print(f"  ! Fotoğraf bulunamadı: {p} -> yer tutucu kullanılıyor", file=sys.stderr)

    if ph is None:
        ph = Image.new("RGB", (inner, inner), col["panel_hi"])
        pd = ImageDraw.Draw(ph)
        step = max(10, inner // 14)           # ince çapraz tarama (harita/kâğıt hissi)
        for k in range(-inner, inner * 2, step):
            pd.line([(k, inner), (k + inner, 0)], fill=col["panel"], width=1)
        f = font(HEAD, int(inner * 0.46))
        pd.text((inner / 2, inner / 2 + inner * 0.02), initials(member.get("name", "")), font=f,
                fill=col["paper"], anchor="mm")

    pm = shape_mask(inner, shape)
    out.paste(ph, (ring + gap, ring + gap), pm)
    paper = Image.new("RGBA", (size, size), col["paper"] + (255,))
    out.paste(paper, (0, 0), ring_layer())
    return out


# --- Arka plan ve ortak parçalar -----------------------------------------------
def make_background(cfg, col):
    W, H = cfg["width"], cfg["height"]
    im = Image.new("RGB", (W, H), col["bg"])
    d = ImageDraw.Draw(im)
    grid = tuple(int(a * 0.82 + b * 0.18) for a, b in zip(col["bg"], col["line"]))
    step = 90
    for x in range(0, W + 1, step):
        d.line([(x, 0), (x, H)], fill=grid, width=1)
    for y in range(0, H + 1, step):
        d.line([(0, y), (W, y)], fill=grid, width=1)
    # üstte yumuşak ışık (vinyet)
    glow = Image.new("L", (W, H), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse((-W * 0.3, -H * 0.18, W * 1.3, H * 0.30), fill=70)
    glow = glow.filter(ImageFilter.GaussianBlur(160))
    im.paste(Image.new("RGB", (W, H), col["panel_hi"]), (0, 0), glow)
    d = ImageDraw.Draw(im)
    # köşe işaretleri (kırpma/kayıt işaretleri)
    m, L = 36, 46
    for cx, cy, sx, sy in [(m, m, 1, 1), (W - m, m, -1, 1), (m, H - m, 1, -1), (W - m, H - m, -1, -1)]:
        d.line([(cx, cy), (cx + sx * L, cy)], fill=col["faint"], width=2)
        d.line([(cx, cy), (cx, cy + sy * L)], fill=col["faint"], width=2)
    return im


def draw_header(im, cfg, col):
    """Logo + başlık + alt başlık. Başlığın bittiği y değerini döndürür."""
    W = cfg["width"]
    d = ImageDraw.Draw(im)
    y = cfg["safe_top"]
    logo_path = cfg["logo"] if os.path.isabs(cfg["logo"]) else os.path.join(HERE, cfg["logo"])
    if os.path.isfile(logo_path):
        lg = Image.open(logo_path).convert("RGBA")
        lh = cfg["logo_height"]
        lw = int(lg.width * lh / lg.height)
        lg = lg.resize((lw, lh), Image.LANCZOS)
        im.paste(lg, ((W - lw) // 2, y), lg)
        y += lh + 26
    else:
        print(f"  ! Logo bulunamadı: {logo_path}", file=sys.stderr)
    lines, f, lh = fit_text(cfg["title"], HEAD, W - 2 * cfg["margin_x"], 118, 56, max_lines=2)
    h = draw_block(d, W / 2, y, lines, f, lh, col["paper"], "m")
    y += h + 6
    # alt başlık: yanlarda ince çizgiler
    sub = cfg["subtitle"]
    sf = font(MONO_B, 30)
    tr = 7
    sw = text_w(sub, sf, tr)
    draw_text(d, (W / 2, y), sub, sf, col["paper_dim"], "ma", tr)
    ly = y + 17
    x1 = W / 2 - sw / 2 - 26
    x2 = W / 2 + sw / 2 + 26
    d.line([(cfg["margin_x"], ly), (x1, ly)], fill=col["line"], width=2)
    d.line([(x2, ly), (W - cfg["margin_x"], ly)], fill=col["line"], width=2)
    d.rectangle((W / 2 - 40, y + 52, W / 2 + 40, y + 55), fill=col["red"])  # kırmızı vurgu çubuğu
    return y + 76


def draw_footer(im, cfg, col):
    """Oyun adı + 'Yakında / Google Play' etiketi. Footer'ın başladığı y değerini döndürür."""
    W, H = cfg["width"], cfg["height"]
    d = ImageDraw.Draw(im)
    bottom = H - cfg["safe_bottom"]
    mx = cfg["margin_x"]
    badge = cfg["badge"]
    note = cfg.get("footer_note", "")
    y = bottom  # aşağıdan yukarı yerleştir
    if badge:
        bf = font(MONO_B, 27)
        tr = 4
        bw = text_w(badge, bf, tr) + 48 + 34
        bh = 58
        x0 = (W - bw) / 2
        y -= bh
        d.rounded_rectangle((x0, y, x0 + bw, y + bh), radius=bh // 2, outline=col["paper_dim"], width=2, fill=col["panel"])
        d.ellipse((x0 + 22, y + bh / 2 - 6, x0 + 34, y + bh / 2 + 6), fill=col["red"])
        draw_text(d, (x0 + 48, y + bh / 2 + 1), badge, bf, col["paper"], "lm", tr)
        y -= 22
    if note:
        nf = font(BODY, 28)
        y -= 34
        d.text((W / 2, y), note, font=nf, fill=col["muted"], anchor="ma")
        y -= 10
    lines, gf, glh = fit_text(tr_upper(cfg["game_name"]), HEAD, W - 2 * mx, 84, 44, max_lines=1)
    y -= glh * len(lines)
    draw_block(d, W / 2, y, lines, gf, glh, col["paper"], "m")
    y -= 26
    d.line([(mx, y), (W - mx, y)], fill=col["line"], width=2)
    return y - 22


def draw_panel(d, box, col, accent=True):
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=col["panel"], outline=col["line"], width=2)
    if accent:
        d.rectangle((x0, y0, x0 + 6, y1), fill=col["paper"])


# --- Kartlar ---------------------------------------------------------------------
def display_name(m, cfg):
    n = (m.get("name") or "").strip() or cfg["placeholder_name"]
    return tr_upper(n) if cfg["name_case"] == "upper" else n


def display_role(m, cfg):
    return (m.get("role") or "").strip() or cfg["placeholder_role"]


def card_list(im, cfg, col, m, idx, box, base_dir):
    """Yatay kart: solda fotoğraf, sağda numara + isim + unvan (+ varsa kısa biyografi)."""
    d = ImageDraw.Draw(im)
    x0, y0, x1, y1 = [int(v) for v in box]
    h = y1 - y0
    draw_panel(d, (x0, y0, x1, y1), col)
    pad = max(18, int(h * 0.10))
    ps = min(h - 2 * pad, 300)
    px = x0 + 6 + pad + 8
    py = y0 + (h - ps) // 2
    pt = make_portrait(m, ps, cfg, col, base_dir)
    im.paste(pt, (px, py), pt)
    tx = px + ps + 34
    tw = x1 - tx - 30
    bio = (m.get("bio_short") or "").strip()

    idx_h = 30 if cfg["show_index"] else 0
    scale = 1.0
    while True:  # metin bloğu kartın yüksekliğine sığana kadar yazıyı küçült
        name_lines, nf, nlh = fit_text(display_name(m, cfg), HEAD, tw, min(92, int(h * 0.36)) * scale, 30, max_lines=2)
        role_lines, rf, rlh = fit_text(display_role(m, cfg), BODY_B, tw, min(36, int(h * 0.15)) * scale, 20, max_lines=2)
        bio_lines, bf, blh = [], None, 0
        if bio and h >= 260:
            bio_lines, bf, blh = fit_text(bio, BODY, tw, 26 * scale, 18, max_lines=3)
        total = idx_h + nlh * len(name_lines) + 18 + 2 + 14 + rlh * len(role_lines)
        if bio_lines:
            total += 14 + blh * len(bio_lines)
        if total <= h - 30 or scale < 0.45:
            break
        scale -= 0.06
    y = y0 + (h - total) / 2
    if cfg["show_index"]:
        draw_text(d, (tx, y), f"{idx:02d}", font(MONO_B, 24), col["red"], "la", 3)
        y += idx_h
    y += draw_block(d, tx, y, name_lines, nf, nlh, col["paper"], "l") + 18
    d.line([(tx, y), (tx + 70, y)], fill=col["paper_dim"], width=2)
    y += 16
    y += draw_block(d, tx, y, role_lines, rf, rlh, col["paper_dim"], "l")
    if bio_lines:
        y += 14
        draw_block(d, tx, y, bio_lines, bf, blh, col["muted"], "l")


def card_cell(im, cfg, col, m, idx, box, base_dir):
    """Izgara hücresi: solda büyük fotoğraf, sağda numara + isim + unvan."""
    d = ImageDraw.Draw(im)
    x0, y0, x1, y1 = [int(v) for v in box]
    w, h = x1 - x0, y1 - y0
    draw_panel(d, (x0, y0, x1, y1), col, accent=False)
    d.rectangle((x0, y0, x1, y0 + 4), fill=col["paper"])
    pad = 14
    ps = max(60, min(h - 2 * pad - 4, int(w * 0.46)))
    px = x0 + pad + 4
    py = y0 + (h - ps) // 2 + 2
    pt = make_portrait(m, ps, cfg, col, base_dir)
    im.paste(pt, (px, py), pt)
    tx = px + ps + 18
    tw = x1 - tx - 14
    scale = 1.0
    while True:
        name_lines, nf, nlh = fit_text(display_name(m, cfg), HEAD, tw, min(54, int(h * 0.24)) * scale, 20, max_lines=2)
        role_lines, rf, rlh = fit_text(display_role(m, cfg), BODY_B, tw, min(24, int(h * 0.11)) * scale, 13, max_lines=3)
        idx_h = 26 if cfg["show_index"] else 0
        text_h = idx_h + nlh * len(name_lines) + 10 + rlh * len(role_lines)
        if text_h <= h - 28 or scale < 0.5:
            break
        scale -= 0.07
    y = y0 + (h - text_h) / 2 + 2
    if cfg["show_index"]:
        draw_text(d, (tx, y), f"{idx:02d}", font(MONO_B, 20), col["red"], "la", 2)
        y += idx_h
    y += draw_block(d, tx, y, name_lines, nf, nlh, col["paper"], "l") + 10
    draw_block(d, tx, y, role_lines, rf, rlh, col["paper_dim"], "l")


def card_single(im, cfg, col, m, idx, total, box, base_dir):
    """Tek üye: büyük fotoğraf, büyük isim, unvan ve kısa biyografi (varsa)."""
    d = ImageDraw.Draw(im)
    x0, y0, x1, y1 = [int(v) for v in box]
    W = cfg["width"]
    w, h = x1 - x0, y1 - y0
    tw = w - 80
    bio = (m.get("bio_short") or "").strip()
    label = ""
    if cfg["member_label"]:
        label = f'{cfg["member_label"]}  {idx:02d} / {total:02d}' if total > 1 else cfg["member_label"]
    label_h = 34 if label else 0
    scale = 1.0
    while True:
        role_lines, rf, rlh = fit_text(display_role(m, cfg), BODY_B, tw, 36 * scale, 22, max_lines=2)
        name_lines, nf, nlh = fit_text(display_name(m, cfg), HEAD, tw, 96 * scale, 44, max_lines=2)
        bio_lines, bf, blh = [], None, 0
        if bio:
            bio_lines, bf, blh = fit_text(bio, BODY, tw - 40, 34 * scale, 20, max_lines=5)
        text_h = label_h + 14 + nlh * len(name_lines) + 14 + 2 + 20 + rlh * len(role_lines)
        if bio_lines:
            text_h += 34 + blh * len(bio_lines) + 40
        ps = int(min(700, h - text_h - 24 - 6, w - 60))
        if ps >= 300 or scale < 0.5:
            break
        scale -= 0.07
    ps = max(ps, 200)
    block = ps + 28 + text_h
    y = y0 + max(0, (h - block) / 2)
    pt = make_portrait(m, ps, cfg, col, base_dir)
    im.paste(pt, ((W - ps) // 2, int(y)), pt)
    y += ps + 28
    if label:
        draw_text(d, (W / 2, y), label, font(MONO_B, 26), col["red"], "ma", 5)
        y += label_h + 14
    y += draw_block(d, W / 2, y, name_lines, nf, nlh, col["paper"], "m") + 14
    d.line([(W / 2 - 50, y), (W / 2 + 50, y)], fill=col["paper_dim"], width=2)
    y += 22
    y += draw_block(d, W / 2, y, role_lines, rf, rlh, col["paper_dim"], "m")
    if bio_lines:
        y += 34
        bh = blh * len(bio_lines) + 40
        d.rectangle((x0 + 20, y, x1 - 20, y + bh), fill=col["panel"], outline=col["line"], width=2)
        d.rectangle((x0 + 20, y, x0 + 26, y + bh), fill=col["paper"])
        draw_block(d, W / 2, y + 20, bio_lines, bf, blh, col["muted"], "m")


# --- Düzenler --------------------------------------------------------------------
def render_group(members, cfg, col, base_dir):
    n = len(members)
    im = make_background(cfg, col)
    top = draw_header(im, cfg, col) + 6
    foot = draw_footer(im, cfg, col)
    W = cfg["width"]
    mx = cfg["margin_x"]
    area = (mx, top + 16, W - mx, foot - 4)
    ah = area[3] - area[1]
    gap = 22
    if n == 1:
        card_single(im, cfg, col, members[0], 1, 1, area, base_dir)
    elif n <= 4:
        rh = min(360, (ah - gap * (n - 1)) / n)
        total = rh * n + gap * (n - 1)
        y = area[1] + (ah - total) / 2
        for i, m in enumerate(members):
            card_list(im, cfg, col, m, i + 1, (area[0], y, area[2], y + rh), base_dir)
            y += rh + gap
    else:
        rows = math.ceil(n / 2)
        cw = (area[2] - area[0] - gap) / 2
        rh = min(330, (ah - gap * (rows - 1)) / rows)
        total = rh * rows + gap * (rows - 1)
        y = area[1] + (ah - total) / 2
        for r in range(rows):
            row = members[r * 2:r * 2 + 2]
            if len(row) == 1:  # tek kalan kartı ortala
                x = area[0] + (area[2] - area[0] - cw) / 2
                card_cell(im, cfg, col, row[0], r * 2 + 1, (x, y, x + cw, y + rh), base_dir)
            else:
                for c, m in enumerate(row):
                    x = area[0] + c * (cw + gap)
                    card_cell(im, cfg, col, m, r * 2 + c + 1, (x, y, x + cw, y + rh), base_dir)
            y += rh + gap
    return im


def render_single(m, idx, total, cfg, col, base_dir):
    im = make_background(cfg, col)
    top = draw_header(im, cfg, col) + 6
    foot = draw_footer(im, cfg, col)
    mx = cfg["margin_x"]
    card_single(im, cfg, col, m, idx, total, (mx, top + 16, cfg["width"] - mx, foot - 4), base_dir)
    return im


# --- Giriş/çıkış -------------------------------------------------------------------
def deep_merge(a, b):
    out = dict(a)
    for k, v in b.items():
        out[k] = deep_merge(out[k], v) if isinstance(v, dict) and isinstance(out.get(k), dict) else v
    return out


def load_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def main():
    ap = argparse.ArgumentParser(description="Rok Games 'Ekibimizi Tanıyın' story üreticisi")
    ap.add_argument("team", nargs="?", default=os.path.join(HERE, "team.json"))
    ap.add_argument("--config", default=os.path.join(HERE, "config.json"))
    ap.add_argument("--out", default=os.path.join(HERE, "out"))
    ap.add_argument("--only", choices=["hepsi", "grup", "tekli"], default="hepsi",
                    help="hepsi: toplu + tekli kareler (varsayılan)")
    ap.add_argument("--prefix", default="", help="çıktı dosya adlarının başına eklenir (örn. ornek3_)")
    args = ap.parse_args()

    cfg = dict(DEFAULTS)
    if os.path.isfile(args.config):
        cfg = deep_merge(DEFAULTS, load_json(args.config))
    team = load_json(args.team)
    if isinstance(team, dict):
        cfg = deep_merge(cfg, team.get("config", {}))
        members = team.get("members", [])
    else:
        members = team
    members = [m for m in members if isinstance(m, dict)]
    if not members:
        sys.exit("team.json içinde üye yok.")
    col = {k: hexrgb(v) for k, v in cfg["colors"].items()}
    base_dir = os.path.dirname(os.path.abspath(args.team))
    os.makedirs(args.out, exist_ok=True)
    made = []

    def save(im, name):
        p = os.path.join(args.out, args.prefix + name)
        im.save(p, "PNG", optimize=True)
        made.append(p)

    n = len(members)
    if args.only in ("hepsi", "grup"):
        pages = [members[i:i + MAX_PER_PAGE] for i in range(0, n, MAX_PER_PAGE)]
        for pi, page in enumerate(pages):
            name = "grup.png" if len(pages) == 1 else f"grup_{pi + 1}.png"
            save(render_group(page, cfg, col, base_dir), name)
    if args.only in ("hepsi", "tekli"):
        for i, m in enumerate(members, 1):
            slug = slugify(m.get("name") or f"uye{i}")
            save(render_single(m, i, n, cfg, col, base_dir), f"uye_{i:02d}_{slug}.png")
    print(f"{len(made)} dosya üretildi ({n} üye):")
    for p in made:
        print("  " + p)


if __name__ == "__main__":
    main()
