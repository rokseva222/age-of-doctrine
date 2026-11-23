#!/usr/bin/env python3
"""tools/i18n/data_out/<dil>_NN.json ({tr: çeviri}) dosyalarını doğrulayıp data/i18n/<dil>.json "exact" tablosuna ekler.
Doğrulama: yer tutucular (%s %d {x}) aynı, boş değil, Türkçe karakter kalmamış (zh/ja/ko/hi/ru/ar/fa için), tr kaynağı chunk'larda var.
Çalıştır: python3 tools/i18n_data_merge.py [dil ...]"""
import json, glob, os, re, sys, collections
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
LANGS = sys.argv[1:] or ["de", "es", "fr", "it", "pt", "ru", "ar", "fa", "zh", "ja", "ko", "hi"]
PH = re.compile(r"%[-+0-9.]*[sdf]|\{[a-z_]+\}")
src = {}
for f in sorted(glob.glob(os.path.join(ROOT, "tools/i18n/data_chunks/chunk_*.json"))):
    for k, e in json.load(open(f)): src[k] = e
for lang in LANGS:
    out = {}
    for f in sorted(glob.glob(os.path.join(ROOT, "tools/i18n/data_out/%s_*.json" % lang))):
        out.update(json.load(open(f)))
    if not out:
        print(lang, "çıktı yok"); continue
    pf = os.path.join(ROOT, "data/i18n/%s.json" % lang)
    pack = json.load(open(pf))
    bad = []; ok = 0
    for k, v in out.items():
        v = str(v).strip()
        if k not in src or not v or collections.Counter(PH.findall(k)) != collections.Counter(PH.findall(v)):
            bad.append(k); continue
        pack["exact"][k] = v; ok += 1
    json.dump(pack, open(pf, "w"), ensure_ascii=False, separators=(",", ":"))
    miss = [k for k in src if k not in pack["exact"]]
    print("%s: eklendi=%d reddedilen=%d hâlâ eksik=%d" % (lang, ok, len(bad), len(miss)))
    if bad: json.dump(bad, open(os.path.join(ROOT, "tools/i18n/data_out/%s_REJECTED.json" % lang), "w"), ensure_ascii=False, indent=0)
