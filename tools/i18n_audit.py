#!/usr/bin/env python3
"""Çeviri denetimi: kodda geçen Türkçe metinlerin her dilde karşılığı var mı, yer tutucular tutuyor mu, değer Türkçe kalmış mı.
Çalıştır: python3 tools/i18n_audit.py [--list-missing]  -> tools/i18n/missing_en.txt, audit_report.txt"""
import re, glob, os, json, sys, collections
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
sys.argv_ = sys.argv
exec(open(os.path.join(root, "tools/i18n_extract.py")).read().split("keys = list(items.keys())")[0])   # items: kaynak -> dosya
LANGS = ["en", "de", "es", "fr", "it", "pt", "ru", "ar", "fa", "zh", "ja", "ko", "hi"]
PH = re.compile(r"%[-+0-9.]*[sdf]|\{[a-z_]+\}")
TRCH = set("ğışĞİŞ")        # ö ü hem Almanca hem Türkçe: yalnızca ç ğ ı ş
packs = {l: json.load(open(os.path.join(root, "data/i18n/%s.json" % l)))["exact"] for l in LANGS}
en = packs["en"]
out = []
def P(s=""):
    out.append(s); print(s)

missing = [k for k in items if k not in en]
P("kodda Türkçe metin: %d, en.json eksik: %d" % (len(items), len(missing)))
open(os.path.join(root, "tools/i18n/missing_en.txt"), "w").write("\n".join(m.replace("\n", "\\n") for m in missing))
for l in LANGS:
    p = packs[l]
    miss = [k for k in en if k not in p or str(p[k]).strip() == ""]
    bad_ph = []
    tr_left = []
    for k, v in p.items():
        v = str(v)
        if collections.Counter(PH.findall(k)) != collections.Counter(PH.findall(v)) and v.strip():
            bad_ph.append(k)
        if v.strip() and (v == k) and any(c in TRCH for c in k):
            tr_left.append(k)
        elif l not in ("ar", "fa", "zh", "ja", "ko", "hi", "ru") and any(c in TRCH for c in v):
            tr_left.append(k)
    P("%s: değer=%d en'e göre eksik/boş=%d yer-tutucu-uyumsuz=%d Türkçe-kalan=%d" % (l, len(p), len(miss), len(bad_ph), len(tr_left)))
    if "--list-missing" in sys.argv:
        for k in miss[:5]: P("    eksik: " + k[:80])
        for k in bad_ph[:5]: P("    ph: %s => %s" % (k[:60], str(p[k])[:60]))
        for k in tr_left[:5]: P("    tr: %s => %s" % (k[:60], str(p[k])[:60]))
    json.dump({"missing": miss, "bad_ph": bad_ph, "tr_left": tr_left}, open("/tmp/audit_%s.json" % l, "w"), ensure_ascii=False)
