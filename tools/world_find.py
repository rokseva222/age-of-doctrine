#!/usr/bin/env python3
"""Ülke ve eyalet arama yardımcısı (veri yazarları için).
  python3 tools/world_find.py Turkey          -> name_en / Türkçe adı eşleşen ülkeler (id, name_en, eyalet sayısı)
  python3 tools/world_find.py -p Izmir       -> adı eşleşen eyaletler (id, ad, şehir, bugünkü ülke)
  python3 tools/world_find.py -c Turkey      -> o ülkenin tüm eyaletleri (id, ad)
  python3 tools/world_find.py -n Turkey      -> o ülkenin komşuları (kara sınırı)"""
import json, os, sys, unicodedata

def norm(t):
    t = (t or "").replace("ı", "i").replace("İ", "i").lower()
    return "".join(ch for ch in unicodedata.normalize("NFKD", t) if not unicodedata.combining(ch))
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
w = json.load(open(os.path.join(root, "data/world.json"), encoding="utf8"))
C = {c["id"]: c for c in w["countries"]}
args = sys.argv[1:]
mode = "c"
if args and args[0] in ("-p", "-c", "-n"):
    mode = args[0][1]; args = args[1:]
q = norm(" ".join(args))
if mode == "c" and "-" not in sys.argv[1:2]:
    for c in w["countries"]:
        if q in norm(c["name_en"]) or q in norm(c["name"]):
            print(c["id"], "|", c["name_en"], "|", c["name"], "| eyalet:", len(c["provs"]), "| kıta:", c["cont"])
elif mode == "p":
    for p in w["provinces"]:
        if q in norm(p["name"]) or q in norm(p.get("city") or ""):
            print(p["id"], "|", p["name"], "|", p.get("city"), "|", C[p["c"]]["name_en"])
elif mode == "c":
    pass
if sys.argv[1:2] == ["-c"]:
    for c in w["countries"]:
        if norm(c["name_en"]) == q:
            for pid in c["provs"]:
                print(pid, "|", w["provinces"][pid]["name"])
if sys.argv[1:2] == ["-n"]:
    ids = {c["id"] for c in w["countries"] if norm(c["name_en"]) == q}
    own = {p["id"]: p["c"] for p in w["provinces"]}
    nb = set()
    for b in w["borders"]:
        ca, cb = own.get(b["a"]), own.get(b["b"])
        if ca is None or cb is None: continue
        if ca in ids and cb not in ids: nb.add(cb)
        if cb in ids and ca not in ids: nb.add(ca)
    print(", ".join(sorted(C[i]["name_en"] for i in nb)))
