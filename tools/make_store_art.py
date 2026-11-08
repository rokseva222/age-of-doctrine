"""Play Store görselleri: simge, uyarlanabilir simge, öne çıkan görsel.
Marka görselleri sabittir: assets/brand/emblem.png ve wordmark.png. Kullanım: python3 tools/make_store_art.py"""
import os, shutil
from PIL import Image, ImageDraw, ImageFont, ImageEnhance

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "store", "art")
PAPER = (236, 230, 214)
BG = (11, 15, 18)
FONT_B = os.path.join(ROOT, "assets", "fonts", "BigShoulders-Bold.ttf")
FONT_M = os.path.join(ROOT, "assets", "fonts", "IBMPlexMono-Bold.ttf")
EM = Image.open(os.path.join(ROOT, "assets", "brand", "emblem.png")).convert("RGBA")
WM = Image.open(os.path.join(ROOT, "assets", "brand", "wordmark.png")).convert("RGBA")


def fit_h(im, h):
    return im.resize((round(im.width * h / im.height), h), Image.LANCZOS)


def fit_w(im, w):
    return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)


def put_center(base, im, cx, cy):
    base.alpha_composite(im, (round(cx - im.width / 2), round(cy - im.height / 2)))


def icon(size):
    img = Image.new("RGBA", (size, size), BG + (255,))
    put_center(img, fit_h(EM, round(size * 0.66)), size / 2, size / 2)
    return img.convert("RGB")


def adaptive_fg(size=432):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    put_center(img, fit_h(EM, round(size * 0.52)), size / 2, size / 2)  # güvenli bölge içinde
    return img


def feature():
    W, H = 1024, 500
    bgp = os.path.join("/tmp/store_shots", "map_bg.png")
    img = Image.open(bgp).convert("RGB")
    ch = int(1920 * H / W)
    img = img.crop((0, 1080 - ch, 1920, 1080)).resize((W, H), Image.LANCZOS)
    img = ImageEnhance.Brightness(img).enhance(0.5)
    grad = Image.new("RGBA", (W, H))
    gd = ImageDraw.Draw(grad)
    for x in range(W):
        a = int(240 * max(0.0, 1 - x / (W * 0.8)) ** 1.1)
        gd.line([x, 0, x, H], fill=BG + (a,))
    img = Image.alpha_composite(img.convert("RGBA"), grad)
    put_center(img, fit_h(EM, 330), 190, H / 2)
    w = fit_w(WM, 560)
    put_center(img, w, 640, H / 2 - 48)
    d = ImageDraw.Draw(img)
    f2 = ImageFont.truetype(FONT_B, 40)
    d.text((372, 345), "DÜNYAYI YÖNET. SAVAŞI KAZAN.", font=f2, fill=PAPER)
    f3 = ImageFont.truetype(FONT_M, 20)
    d.text((374, 400), "TUR TABANLI JEOPOLİTİK STRATEJİ", font=f3, fill=(154, 162, 173))
    return img.convert("RGB")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    icon(512).save(os.path.join(OUT, "icon_512.png"))
    icon(192).save(os.path.join(ROOT, "icon_192.png"))
    adaptive_fg().save(os.path.join(ROOT, "icon_fg_432.png"))
    Image.new("RGB", (432, 432), BG).save(os.path.join(ROOT, "icon_bg_432.png"))
    feature().save(os.path.join(OUT, "feature_1024x500.png"))
    for n in ("s0_splash", "s1_menu", "s2_select", "s3_game", "s4_assault", "s5_report", "s6_budget", "s7_ww2"):
        src = f"/tmp/store_shots/{n}.png"
        if os.path.exists(src):
            shutil.copy(src, os.path.join(ROOT, "store", "screens", n + ".png"))
    print("tamam")
