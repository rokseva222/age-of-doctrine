#!/usr/bin/env python3
"""Tüm dünyanın ilçeleri: dr5hn/countries-states-cities-database (ADM2 'counties' + 'cities', koordinatlı) -> data/districts.json
Her oyun eyaleti için merkez şehre en yakın <=12 ilçe/yer (ad, x, y, ağırlık). Projeksiyon: Miller, ölçek 5 (world.json ile aynı).
Kullanım: python3 tools/build_districts.py <dr5hn_klasörü>"""
import json, math, sys, os, collections
import numpy as np
from matplotlib.path import Path
src = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/dr5hn/countries-states-cities-database"
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
w = json.load(open(os.path.join(root, "data/world.json")))
ctry = {int(c["id"]): c for c in w["countries"]}

def miller(lat):
    return 1.25 * math.degrees(math.log(math.tan(math.pi / 4 + 0.4 * math.radians(max(-80.0, min(80.0, lat))))))
def proj(lat, lon):
    return (5.0 * lon, -5.0 * miller(lat))

# yerler: iso2 -> [(ad, x, y, tür)]
places = collections.defaultdict(list)
for c in json.load(open(os.path.join(src, "json/counties.json"))):
    try:
        x, y = proj(float(c["latitude"]), float(c["longitude"]))
    except Exception:
        continue
    places[c["country_code"]].append((c["name"], x, y, 2))
for cn in json.load(open(os.path.join(src, "json/countries+states+cities.json"))):
    for st in cn["states"]:
        for ci in st.get("cities", []):
            try:
                x, y = proj(float(ci["latitude"]), float(ci["longitude"]))
            except Exception:
                continue
            places[cn["iso2"]].append((ci["name"], x, y, 1))
print("yer sayısı:", sum(len(v) for v in places.values()))

# elle ağırlıklar (nüfus ağırlıkları, gerçek ilçe nüfuslarına kabaca orantılı)
MAN = {
 "İstanbul": {"Esenyurt": 10, "Başakşehir": 7, "Fatih": 8, "Beşiktaş": 6, "Üsküdar": 7, "Kadıköy": 8, "Ümraniye": 9, "Pendik": 10, "Bağcılar": 9, "Bahçelievler": 6, "Kartal": 6, "Maltepe": 6, "Sarıyer": 4, "Silivri": 3, "Şile": 2, "Çatalca": 2},
 "Ankara": {"Çankaya": 17, "Yenimahalle": 14, "Keçiören": 15, "Mamak": 10, "Altındağ": 8, "Etimesgut": 11, "Sincan": 9, "Pursaklar": 3, "Gölbaşı": 4, "Polatlı": 4, "Beypazarı": 2},
 "İzmir": {"Konak": 10, "Karşıyaka": 13, "Bornova": 12, "Buca": 15, "Bayraklı": 10, "Çiğli": 9, "Gaziemir": 4, "Menemen": 5, "Torbalı": 5, "Urla": 3, "Çeşme": 3, "Ödemiş": 4},
}
import re
def clean(nm):
    nm = nm.strip()
    nm = re.sub(r"^(Amphoe|Khet|Huyện|Quận|Thành phố|Municipio de|Municipality of)\s+", "", nm)
    nm = re.sub(r"\s+(County|City|District|Municipality|Prefecture|Autonomous.*|Banner|Qu|Shi|Xian)$", "", nm)
    return nm.strip()
for iso, lst in places.items():
    places[iso] = [(clean(a[0]), a[1], a[2], a[3]) for a in lst if 2 <= len(clean(a[0])) <= 26]
out = {}
miss = 0
byc = collections.defaultdict(list)
for p in w["provinces"]:
    byc[int(p["c"])].append(p)
for cid, provs in byc.items():
    iso = str(ctry[cid].get("iso", "")).upper()
    pl = places.get(iso, [])
    if not pl:
        continue
    pts = np.array([[a[1], a[2]] for a in pl])
    owner = np.full(len(pl), -1, dtype=np.int64)
    for p in provs:
        bb = p["bb"]
        m = (pts[:, 0] >= bb[0]) & (pts[:, 0] <= bb[2]) & (pts[:, 1] >= bb[1]) & (pts[:, 1] <= bb[3]) & (owner < 0)
        idx = np.nonzero(m)[0]
        if len(idx) == 0:
            continue
        inside = np.zeros(len(idx), dtype=bool)
        for r in p["rings"]:
            ring = np.array(r).reshape(-1, 2)
            if len(ring) < 3:
                continue
            inside |= Path(ring).contains_points(pts[idx])
        owner[idx[inside]] = p["id"]
    for p in provs:
        mine = [pl[i] for i in np.nonzero(owner == p["id"])[0]]
        if len(mine) < 4:
            miss += 1
            continue
        lx, ly, lr = p["lab"]
        # merkez: eyalet şehrinin adıyla eşleşen yer (en yakını), yoksa etiket konumu
        cx, cy = lx, ly
        best = 1e9
        for nm in (p["city"], p["name"]):
            for a in mine:
                if a[0] == nm:
                    d = math.hypot(a[1] - lx, a[2] - ly)
                    if d < best:
                        best = d; cx, cy = a[1], a[2]
        cpop = float(p.get("cpop", 0)) / 1e6
        k = max(5, min(12, 5 + int(round(math.sqrt(max(cpop, 0.0)) * 1.3))))
        man = MAN.get(p["name"]) if iso == "TR" else None
        # ADM2 tercih: aynı uzaklıkta ilçe şehirden önce gelir
        mine.sort(key=lambda a: math.hypot(a[1] - cx, a[2] - cy) * (0.8 if a[3] == 2 else 1.0))
        seen = set(); sel = []
        if man:
            byname = {a[0]: a for a in mine}
            for nm, wt in man.items():
                if nm in byname and nm not in seen:
                    seen.add(nm); sel.append((byname[nm], float(wt)))
        for a in mine:
            if len(sel) >= k:
                break
            if a[0] in seen or a[0].strip() == "":
                continue
            seen.add(a[0]); sel.append((a, None))
        if len(sel) < 4:
            miss += 1
            continue
        dmed = sorted(math.hypot(a[1] - cx, a[2] - cy) for a, _ in sel)[len(sel) // 2] or 1.0
        lst = []
        for a, wt in sel:
            d = math.hypot(a[1] - cx, a[2] - cy)
            wv = wt if wt is not None else (1.0 / (0.25 + d / dmed)) * 2.0
            nm = a[0]
            if nm == "Merkez":
                nm = "%s Merkez" % (p["city"] or p["name"])
            lst.append([nm, round(a[1], 2), round(a[2], 2), round(wv, 2)])
        out[str(p["id"])] = lst
json.dump(out, open(os.path.join(root, "data/districts.json"), "w"), ensure_ascii=False, separators=(",", ":"))
print("eyalet:", len(out), "/", len(w["provinces"]), " eksik:", miss, " boyut:", os.path.getsize(os.path.join(root, "data/districts.json")) // 1024, "KB")
