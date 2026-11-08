#!/usr/bin/env python3
"""tools/i18n/items.tsv (id, Türkçe, dosya) + tools/i18n/<lang>_*.txt (id|çeviri) -> data/i18n/<lang>.json
Kullanım: python3 tools/i18n_build.py [dil ...]   (varsayılan: en ve diğer bulunanlar)"""
import glob, json, os, sys, re
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
items = {}
for ln in open(os.path.join(root, "tools/i18n/items.tsv"), encoding="utf8"):
    p = ln.rstrip("\n").split("\t")
    if len(p) >= 2:
        items[int(p[0])] = p[1].replace("\\n", "\n").replace("\\t", "\t")
EXTRA = {
 "en": {"Bağımsızlık Cephesi": "Independence Front", "Gölge Ağı": "Shadow Network", "Dağ Milisleri": "Mountain Militia",
        "Halk Birliği": "People's Union", "Özgürlük Ordusu": "Freedom Army", "Kuzey Direnişi": "Northern Resistance",
        "Yeraltı Hareketi": "Underground Movement", "şans %%%d": "%d%% chance", "Piyade Tüfeği": "Infantry Rifle", "Tank": "Tank", "Zırhlı Araç": "Armored Vehicle", "Top & Roketatar": "Artillery & Rockets", "Uçak & İHA": "Aircraft & UAV", "Denizaltı": "Submarine",
        "Daire": "Circle", "Kalkan": "Shield", "Altıgen": "Hexagon", "Elmas": "Diamond", "Sekizgen": "Octagon", "Rozet": "Badge", "Güneş": "Sun", "Kare": "Square", "Düz": "Plain", "İç çerçeve": "Inner frame", "İç daire": "Inner circle",
        "Kurgusal": "Fictional", "aşırılıkçı yeniden doğuş": "extremist rebirth", "otoriter yeniden diriliş": "authoritarian resurgence", "kuzeyde büyük savaş": "great war in the north", "Napolyon çağı geri dönüyor": "the Napoleonic age returns", "siber çağ": "cyber age", "silahsız cephe": "the unarmed front", "siber çağ, silahsız cephe": "cyber age, the unarmed front",
        "Kasa": "Treasury", "HABER": "NEWS", "SAVAŞ": "WAR", "FETİH": "CONQUEST", "KAYIP": "LOSS", "BARIŞ": "PEACE", "OLAY": "EVENT", "ÇATIŞMA": "CLASH", "SON": "END", "İSYAN": "REVOLT", "İTTİFAK": "ALLIANCE", "SIRALAMA": "RANKING", "SİBER": "CYBER", "TEDARİK": "SUPPLY", "ZAFER": "VICTORY", "YENİLGİ": "DEFEAT", "SERBEST": "FREE", "GERÇEK KRİZ": "REAL CRISIS", "KURGUSAL": "FICTIONAL", "Dil": "Language", "/hf": "/wk", "Gelir/hf": "Income/wk", "Şafak Tugayı": "Dawn Brigade", "Sınır Muhafızları": "Border Guards"},
}
META = {
 "en": {"months": ["January","February","March","April","May","June","July","August","September","October","November","December"],
        "units": {"tr": "T", "mr": "B", "mn": "M"}, "dec": ".", "thou": ","},
}
def build(lang):
    ex = {}
    for f in sorted(glob.glob(os.path.join(root, "tools/i18n/%s_*.txt" % lang))):
        for ln in open(f, encoding="utf8"):
            ln = ln.rstrip("\n")
            if "|" not in ln: continue
            i, t = ln.split("|", 1)
            if not i.isdigit() or int(i) not in items: continue
            t = t.replace("\\n", "\n").replace("\\t", "\t")
            if t.strip() and t.strip() != "=" and t != items[int(i)]:
                ex[items[int(i)]] = t
    xp = os.path.join(root, "tools/i18n/%s_extra.tsv" % lang)
    if os.path.exists(xp):
        for ln in open(xp, encoding="utf8"):
            ln = ln.rstrip("\n")
            if "\t" in ln:
                k, v = ln.split("\t", 1)
                ex[k.replace("\\n", "\n")] = v.replace("\\n", "\n")
    if lang == "en":
        w = json.load(open(os.path.join(root, "data/world.json"), encoding="utf8"))
        for c in w["countries"]:
            if c["name"] != c["name_en"]:
                ex.setdefault(c["name"], c["name_en"])
    ex.update(EXTRA.get(lang, {}))
    out = {"exact": ex}
    out.update(META.get(lang, {}))
    jp = os.path.join(root, "tools/i18n/meta_%s.json" % lang)
    if os.path.exists(jp):
        out.update(json.load(open(jp, encoding="utf8")))
    os.makedirs(os.path.join(root, "data/i18n"), exist_ok=True)
    with open(os.path.join(root, "data/i18n/%s.json" % lang), "w", encoding="utf8") as o:
        json.dump(out, o, ensure_ascii=False, separators=(",", ":"))
    print(lang, len(ex), "çeviri")
langs = sys.argv[1:] or sorted({re.match(r".*/([a-z]+)_[a-z0-9]+\.txt$", f).group(1) for f in glob.glob(os.path.join(root, "tools/i18n/*_*.txt"))})
for l in langs: build(l)
