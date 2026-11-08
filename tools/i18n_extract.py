#!/usr/bin/env python3
"""scripts/*.gd içindeki çevrilecek Türkçe metinleri çıkarır -> tools/i18n/items.tsv (id<TAB>kaynak<TAB>dosya)."""
import re, glob, os, json
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SKIP = {"name_gen.gd", "flag_db.gd", "silhouette.gd", "world_data.gd", "icons.gd", "scene_art.gd", "arsenal.gd", "arsenal_era.gd", "emblem.gd", "logo.gd", "flags.gd", "sfx.gd", "loc.gd", "militias.gd"}
lit = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
TR = set("çğıöşüÇĞİÖŞÜ")
def unescape(t):
    return t.replace('\\n', '\n').replace('\\t', '\t').replace('\\"', '"').replace('\\\\', '\\')
items = {}
W = json.load(open(os.path.join(root, "data/world.json")))
NAMES_EN = {c["name_en"] for c in W["countries"]}
PROV = {p["name"] for p in W["provinces"]} | {p["city"] for p in W["provinces"]}
for f in sorted(glob.glob(os.path.join(root, "scripts/*.gd"))):
    b = os.path.basename(f)
    if b in SKIP: continue
    src = open(f).read()
    # yorum satırlarını at
    lines = []
    for ln in src.split("\n"):
        s = ln.strip()
        if s.startswith("#"): continue
        lines.append(ln)
    for m in lit.finditer("\n".join(lines)):
        t = unescape(m.group(1))
        if len(t) < 2: continue
        if t.startswith(("res://", "user://", "#")): continue
        if not re.search(r'[A-Za-zÇĞİÖŞÜçğıöşü]{2,}', t): continue
        if re.fullmatch(r'[a-z0-9_\-\.\/:%]+', t): continue          # tanımlayıcı
        if re.fullmatch(r'[0-9a-fA-F]{6,8}', t): continue
        if not (" " in t or t[0].isupper() or any(c in TR for c in t)): continue
        if t in NAMES_EN or t in PROV: continue
        if re.match(r'^[HRSC]:[^ ]*$', t) or t in ("XXX",) or t.startswith("H:") : continue
        if "|" in t and " " not in t.split("|")[0] or ("|" in t and b == "eras.gd"):
            t = t.split("|")[0]
            if len(t) < 2: continue
        items.setdefault(t, b)
keys = list(items.keys())
with open(os.path.join(root, "tools/i18n/items.tsv"), "w") as o:
    for i, k in enumerate(keys):
        o.write("%d\t%s\t%s\n" % (i, k.replace("\n", "\\n").replace("\t", "\\t"), items[k]))
import collections
c = collections.Counter(items.values())
print(len(keys), "metin;", sum(len(k) for k in keys), "karakter")
for f, n in c.most_common(): print("  ", f, n)
