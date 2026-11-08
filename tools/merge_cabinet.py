#!/usr/bin/env python3
"""data/research/cab_*.json dosyalarını data/cabinet.json içine birleştirir (mevcut isimler korunur, yeni roller eklenir)."""
import json, glob, os, re
root = os.path.join(os.path.dirname(__file__), "..")
p = os.path.join(root, "data/cabinet.json")
base = json.load(open(p))
mins = base["ministers"]
world = json.load(open(os.path.join(root, "data/world.json")))
valid = {c.get("name_en", c.get("name")) for c in world["countries"]}
ok = re.compile(r"^[^\d<>{}\[\]/\\]{3,60}(\|f)?$")
added = 0
files = sorted(glob.glob(os.path.join(root, "data/research/cabv_*.json"))) + sorted(f for f in glob.glob(os.path.join(root, "data/research/cab_*.json")) if not f.endswith("cab_exist.json")) + [os.path.join(root, "data/research/cab_exist.json")]
for f in files:
    verified = os.path.basename(f).startswith("cabv_")
    if not os.path.exists(f):
        continue
    try:
        d = json.load(open(f))
    except Exception as e:
        print("okunamadı", f, e); continue
    for country, roles in d.items():
        if country not in valid:
            print("bilinmeyen ülke:", country); continue
        for role, name in roles.items():
            if role not in ("def", "for", "fin", "int", "hlt", "spy") or not isinstance(name, str) or not ok.match(name.strip()):
                continue
            e = mins.setdefault(country, {})
            if verified or role not in e:
                e[role] = name.strip(); added += 1
base["_source"] = "Wikipedia ve resmî hükümet siteleri (Kasım 2026); yalnızca metin. Eksik görevlerde isim kültürüne göre rastgele isim üretilir."
json.dump(base, open(p, "w"), ensure_ascii=False, indent=1)
print("eklenen rol:", added, "ülke:", len(mins))
