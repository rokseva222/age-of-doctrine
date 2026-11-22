#!/usr/bin/env python3
"""tools/i18n/add_*.py içindeki T tablosunu data/i18n/<dil>.json 'exact' bölümüne işler.
Var olan çeviriye dokunmaz; yalnız eksik/boş ya da değeri Türkçe kaynakla aynı (çevrilmemiş) olanı yazar. Kullanım: python3 tools/i18n_merge_add.py tools/i18n/add_20261122.py"""
import json, sys, os, runpy
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
mod = runpy.run_path(os.path.join(root, sys.argv[1]))
T, L = mod["T"], mod["L"]
for l in L:
    p = os.path.join(root, "data/i18n/%s.json" % l)
    d = json.load(open(p, encoding="utf-8"))
    ex = d["exact"]
    n = 0
    for k, v in T.items():
        t = v[l]
        cur = ex.get(k)
        if cur is None or str(cur).strip() == "" or cur == k:
            ex[k] = t
            n += 1
    json.dump(d, open(p, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print(l, "yazıldı", n)
