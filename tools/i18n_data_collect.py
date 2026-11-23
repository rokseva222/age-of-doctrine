#!/usr/bin/env python3
"""Veri dosyalarındaki (çağ, an kartı, senaryo) Türkçe metinleri toplar; 13 dilde karşılığı olmayanları tools/i18n/data_src.json'a yazar:
{tr: en_veya_null}. Çalıştır: python3 tools/i18n_data_collect.py"""
import json, glob, os, re
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
de = json.load(open(os.path.join(ROOT, "data/i18n/de.json")))["exact"]
TR = re.compile(r"[çğışöüÇĞİŞÖÜ]|\b(ve|bir|için|ile|bu|olarak|ama|gibi)\b")
SKIP = {"en", "moments_en", "id", "icon", "scene", "requires", "forbid", "fx", "default_fx", "flag", "color", "emblem", "look", "setup", "capital", "split", "absorb", "arsenal", "defs", "leaders", "pop_f", "suggest", "base", "family", "pack", "mood", "country", "type", "kind", "members", "wars", "truce", "vassals", "nukes", "carriers", "inherit_until", "inherit_exclude"}
src = {}
def en_map(d):
    m = {}
    if isinstance(d, dict):
        for k in ("en", "moments_en"):
            if isinstance(d.get(k), dict):
                for a, b in d[k].items():
                    if isinstance(b, str): m[a] = b
    return m
def walk(o, en, enblock):
    if isinstance(o, dict):
        for k, v in o.items():
            if k in SKIP and k not in ("setup",):
                continue
            walk(v, en, enblock)
        # eski biçim: era "en" bloğu (indeks tabanlı) -> metni konumundan eşle
    elif isinstance(o, list):
        for v in o: walk(v, en, enblock)
    elif isinstance(o, str):
        s = o.strip()
        if len(s) >= 6 and TR.search(s) and s not in de and "\n" not in s[:0]:
            src.setdefault(o, en.get(o))
def era_en(d):
    """Çağ dosyası: en bloğu indeks/id tabanlı; TR kaynağıyla eşleştir."""
    e = d.get("en", {}); m = {}
    if not isinstance(e, dict): return m
    for k, v in (("name", d.get("name")), ("sub", d.get("sub")), ("blurb", d.get("blurb"))):
        if v and e.get(k): m[v] = e[k]
    st = d.get("setup", {}) if isinstance(d.get("setup"), dict) else {}
    if st.get("intro") and e.get("setup_intro"): m[st["intro"]] = e["setup_intro"]
    for i, ev in enumerate(d.get("events", []) if isinstance(d.get("events"), list) else []):
        t = e.get("events", {}).get(str(i)) if isinstance(e.get("events"), dict) else None
        if t and isinstance(ev, dict) and ev.get("t"): m[ev["t"]] = t
    ob = d.get("objectives", {})
    if isinstance(ob, dict):
        for v in ob.values():
            for o in v if isinstance(v, list) else []:
                if isinstance(o, dict) and o.get("text") and isinstance(e.get("objectives"), dict) and e["objectives"].get(o.get("id")):
                    m[o["text"]] = e["objectives"][o["id"]]
    return m
for pat in ("data/eras/*.json", "data/moments/*.json", "data/scenarios/*.json", "data/scn_moments/*.json"):
    for f in sorted(glob.glob(os.path.join(ROOT, pat))):
        if f.endswith("index.json"): continue
        d = json.load(open(f))
        en = en_map(d)
        if "/eras/" in f and isinstance(d, dict): en.update(era_en(d))
        walk(d, en, None)
os.makedirs(os.path.join(ROOT, "tools/i18n"), exist_ok=True)
json.dump(src, open(os.path.join(ROOT, "tools/i18n/data_src.json"), "w"), ensure_ascii=False, indent=0)
print("benzersiz çevrilecek:", len(src), " İngilizcesi olan:", sum(1 for v in src.values() if v), " karakter:", sum(len(k) for k in src))
