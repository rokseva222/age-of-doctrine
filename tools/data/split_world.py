#!/usr/bin/env python3
"""Daha ince eyalet ağı: build_world.py'nin az birleştirilmiş çıktısını (W2) mevcut data/world.json'un (O) üstüne giydirir.
- Her eski eyalet, W2'de bir ya da daha çok parçaya bölünür (birleştirme sırası deterministik => tam rafine). Ana parça eski id'yi, ad/şehri ve yamaları korur;
  diğer parçalar yeni id alır ve 'par' = eski eyalet id'sini taşır (çağ/senaryo kodu parçaları ana eyaletle birlikte hareket ettirir).
- Slovenya (1714-1716) elle düzeltilmiş şekillerini korur.
Kullanım: NE_SRC=/tmp/data NE_MEMBERS=/tmp/mem_k9.json NE_OUT=/tmp/w_k9.json python3 tools/data/build_world.py       (W1: eski taban)
          NE_KAREA=26 NE_KPOP=3 NE_MAXPROV=250 NE_MEMBERS=/tmp/mem_m26.json NE_OUT=/tmp/w_m26.json ... build_world.py  (W2)
          python3 tools/data/split_world.py data/world.json /tmp/w_k9.json /tmp/mem_k9.json /tmp/w_m26.json /tmp/mem_m26.json data/world.json"""
import json, sys, math, collections
O_f, W1_f, M1_f, W2_f, M2_f, OUT = sys.argv[1:7]
O = json.load(open(O_f)); W1 = json.load(open(W1_f)); W2 = json.load(open(W2_f))
M1 = {int(k): v for k, v in json.load(open(M1_f)).items()}
M2 = {int(k): v for k, v in json.load(open(M2_f)).items()}
KEEP_NAMES = {"Łódź", "Lublin", "Bozen", "Brandenburg"}   # eras.gd SPLIT dizgeleri
LEGACY = {1714, 1715, 1716}          # Slovenya: elle düzeltilmiş şekiller
OP = O["provinces"]; W2P = W2["provinces"]
u2o = {}
for o, l in M1.items():
    for u in l:
        u2o[u] = o
parent = {}
for n, l in M2.items():
    s = {u2o[u] for u in l if u in u2o}
    assert len(s) == 1, (n, s)
    parent[n] = s.pop()
kids = collections.defaultdict(list)
for n, o in parent.items():
    kids[o].append(n)
for o in range(len(OP)):
    assert o in kids, o
    for n in kids[o]:
        assert W2P[n]["c"] == OP[o]["c"], (o, n)

def dist(a, b):
    return math.hypot(a["lab"][0] - b["lab"][0], a["lab"][1] - b["lab"][1])

# ---- yeni numaralandırma
newid = {}           # W2 id -> yeni id
primary = {}         # eski id -> W2 id
nxt = len(OP)
for o in range(len(OP)):
    if o in LEGACY:
        continue
    ks = kids[o]
    city = (OP[o].get("city") or "").lower()
    pk = [n for n in ks if city and (W2P[n].get("city") or "").lower() == city]
    p = max(pk or ks, key=lambda n: W2P[n]["area"])
    primary[o] = p
    newid[p] = o
for o in range(len(OP)):
    if o in LEGACY:
        continue
    for n in sorted(kids[o]):
        if n != primary[o]:
            newid[n] = nxt
            nxt += 1
N = nxt
provs = [None] * N
for o in LEGACY:
    provs[o] = dict(OP[o])
for n, i in newid.items():
    q = W2P[n]
    o = parent[n]
    nm, ct = q["name"], q.get("city", "")
    if i == o:           # ana parça: yama ile elle düzeltilmiş ad/şehir korunur; yamasızsa parçanın kendi adı
        if OP[o]["name"] != W1["provinces"][o]["name"] or OP[o]["name"] in KEEP_NAMES:
            nm = OP[o]["name"]
        if OP[o].get("city", "") != W1["provinces"][o].get("city", "") or not ct:
            ct = OP[o].get("city", "") or ct
    provs[i] = {"id": i, "c": q["c"], "name": nm, "city": ct,
                "rings": q["rings"], "lab": q["lab"], "bb": q["bb"], "area": q["area"], "cpop": q["cpop"], "lm": q["lm"],
                "nb": [], "sea": [], "par": o}
for o in LEGACY:
    provs[o]["par"] = o
# eski id'ye göre çocuk listesi (yeni id'lerle)
kids_new = {o: [newid[n] for n in kids[o]] for o in kids if o not in LEGACY}
for o in LEGACY:
    kids_new[o] = [o]

def lm_of(i):
    return provs[i]["lm"]

# ---- komşuluk: W2'den
for n, i in newid.items():
    s = set()
    for m in W2P[n]["nb"]:
        if m in newid:
            s.add(newid[m])
    provs[i]["nb"] = s
def vkey(r):
    return {(round(r[k], 1), round(r[k + 1], 1)) for k in range(0, len(r) - 1, 2)}
def verts(i):
    s = set()
    for r in provs[i]["rings"]:
        s |= vkey(r)
    return s
# Slovenya komşulukları: eski nb -> o eski eyaletin çocukları arasında köşe paylaşanlar, yoksa en yakın
for o in LEGACY:
    s = set()
    lv = verts(o)
    for q in OP[o]["nb"]:
        if q in LEGACY:
            s.add(q); continue
        cand = [k for k in kids_new[q] if lv & verts(k)]
        if not cand:
            cand = [min(kids_new[q], key=lambda k: dist(provs[k], provs[o]))]
        s.update(cand)
    # çevre çocuklarının Slovenya ile köşe paylaşması
    provs[o]["nb"] = s
    for k in s:
        if k not in LEGACY:
            provs[k]["nb"].add(o)
    # W2'de Slovenya çocuklarına komşu olan dış eyaletler de (yukarıda bulunmayanlar)
for o in LEGACY:
    for n in kids[o]:
        for m in W2P[n]["nb"]:
            if m in newid and newid[m] not in LEGACY:
                k = newid[m]
                if lm_of(k) == provs[o]["lm"] and provs[o]["nb"] and (verts(o) & verts(k)):
                    provs[o]["nb"].add(k); provs[k]["nb"].add(o)
# simetri
for i in range(N):
    for j in list(provs[i]["nb"]):
        provs[j]["nb"].add(i)
        assert j != i
# ---- deniz bağlantıları: W2'den
for n, i in newid.items():
    for m in W2P[n]["sea"]:
        if m in newid:
            provs[i]["sea"].append(newid[m])
# eski yamalar (elle eklenen deniz bağları): en yakın kıyı çocukları
added = []
for a in OP:
    for b in a["sea"]:
        if b not in W1["provinces"][a["id"]]["sea"]:
            added.append((a["id"], b))
for a, b in added:
    best = min(((dist(provs[x], provs[y]), x, y) for x in kids_new[a] for y in kids_new[b]))
    _, x, y = best
    if y not in provs[x]["sea"]:
        provs[x]["sea"].append(y)
    if x not in provs[y]["sea"]:
        provs[y]["sea"].append(x)
# Slovenya deniz bağı: yok (iç ülke); eski 'sea' listesi boş
for i in range(N):
    provs[i]["sea"] = sorted(set(provs[i]["sea"]))
    provs[i]["nb"] = sorted(provs[i]["nb"])
# ---- sınırlar
borders = []
seen = set()
for b in W2["borders"]:
    if b["a"] in newid and (b["b"] in newid or b["b"] < 0):
        borders.append({"a": newid[b["a"]], "b": newid[b["b"]] if b["b"] >= 0 else b["b"], "p": b["p"]})
    elif b["a"] < 0 and b["b"] in newid:
        borders.append({"a": b["a"], "b": newid[b["b"]], "p": b["p"]})
for b in O["borders"]:
    a, c = b["a"], b["b"]
    if a in LEGACY or c in LEGACY:
        def pick(x):
            if x < 0 or x in LEGACY:
                return x
            mid = (b["p"][len(b["p"]) // 4 * 2], b["p"][len(b["p"]) // 4 * 2 + 1])
            return min(kids_new[x], key=lambda k: math.hypot(provs[k]["lab"][0] - mid[0], provs[k]["lab"][1] - mid[1]))
        borders.append({"a": pick(a), "b": pick(c), "p": b["p"]})
# ---- ülkeler
countries = O["countries"]
byc = collections.defaultdict(list)
for p in provs:
    byc[p["c"]].append(p["id"])
for c in countries:
    c["provs"] = byc[c["id"]]
    assert c["capital"] < len(OP)
out = {"scale": O["scale"], "countries": countries, "provinces": provs, "borders": borders, "lakes": O["lakes"]}
# sorted/ints
json.dump(out, open(OUT, "w"), ensure_ascii=False, separators=(",", ":"))
print("eyalet", len(OP), "->", N, " sınır", len(O["borders"]), "->", len(borders), " eklenen deniz bağı", len(added))
