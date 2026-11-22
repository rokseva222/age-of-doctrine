#!/usr/bin/env python3
"""Harita delik/boşluk onarımı (data/world.json).
Eyaletleri bir id rasterine (5 px/birim) çizer ve iki tür kusuru kapatır:
  (1) kara içinde kapalı kalan küçük boşluklar (delik; HOLE_MAX birim^2'ye kadar, gerçek göller ve SKIP ülkeleri hariç)
  (2) kara komşusu iki eyalet arasındaki ince aralıklar (sliver; GAP_R piksel yarıçaplı kapama)
Her parça, en yakın eyaletin EK HALKASI olarak eklenir (çakışma zararsız). İkinci çalıştırma ~hiçbir şey eklemez.
  python3 tools/fix_map_gaps.py report [out.png]   -> listele
  python3 tools/fix_map_gaps.py apply              -> data/world.json'u yamala"""
import json, sys, os
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
from contourpy import contour_generator
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
WP = os.path.join(ROOT, "data/world.json")
S = 5
X0, X1, Y0, Y1 = -900, 900, -570, 312
W, H = (X1 - X0) * S, (Y1 - Y0) * S
HOLE_MAX = float(os.environ.get("HOLE_MAX", 9.0))
GAP_OCEAN = float(os.environ.get("GAP_OCEAN", 2.0))
WIDE_MIN = float(os.environ.get("WIDE_MIN", 4))
GAP_R = int(os.environ.get("GAP_R", 3))
OCEAN_MIN = float(os.environ.get("OCEAN_MIN", 1.0))
# kıyıya yakın görünse de gerçek kapalı delik olan bölgeler (x0,y0,x1,y1 birim): Baltık ülkeleri
FORCE_BOX = [(100, -335, 145, -300)]
# gerçek koy/göl/boğaz/fiyort bol olan ülkeler: dokunma (delik: SKIP, aralık: SKIP+SKIP_GAP)
SKIP = set(os.environ.get("SKIP", "Canada,Greenland,Chile,Antarctica,Norway,Denmark,United Kingdom,Ireland,Australia,United States of America,Russia,Japan,Philippines,Indonesia,Papua New Guinea,Solomon Is.,Trinidad and Tobago,Cuba,Netherlands,Greece,New Zealand,Ukraine,Turkey").split(","))
w = json.load(open(WP))
P = w["provinces"]; C = {c["id"]: c for c in w["countries"]}
adj = {}
for b in w["borders"]:
    if b["b"] >= 0 and b["a"] >= 0:
        adj.setdefault(b["a"], set()).add(b["b"]); adj.setdefault(b["b"], set()).add(b["a"])

def raster(rings, ids=None):
    im = Image.new("I", (W, H), 0); d = ImageDraw.Draw(im)
    for r, v in rings:
        d.polygon([((r[i] - X0) * S, (r[i + 1] - Y0) * S) for i in range(0, len(r), 2)], fill=v)
    return np.array(im, dtype=np.int32)

def disk(r):
    y, x = np.ogrid[-r:r + 1, -r:r + 1]
    return (x * x + y * y) <= r * r

def dp(pts, eps):
    if len(pts) < 3: return pts
    a, b = pts[0], pts[-1]
    dx, dy = b[0] - a[0], b[1] - a[1]
    n = (dx * dx + dy * dy) ** 0.5 or 1e-9
    md, mi = 0, 0
    for i in range(1, len(pts) - 1):
        dd = abs(dy * (pts[i][0] - a[0]) - dx * (pts[i][1] - a[1])) / n
        if dd > md: md, mi = dd, i
    if md > eps:
        return dp(pts[:mi + 1], eps)[:-1] + dp(pts[mi:], eps)
    return [a, b]

def polys(mask, ox, oy, sc=S, wx=X0, wy=Y0):
    """crop maskesi (bool) -> halkalar (dünya koordinatı); 1 px şişirilir ki komşularla örtüşsün."""
    m = ndi.binary_dilation(mask, iterations=1)
    pad = np.pad(m.astype(np.float32), 1)
    out = []
    for line in contour_generator(z=pad).lines(0.5):
        pts = [(float(x) - 1 + ox, float(y) - 1 + oy) for x, y in line]
        if len(pts) > 3 and pts[0] == pts[-1]: pts = pts[:-1]
        if len(pts) > 6:
            k = max(range(len(pts)), key=lambda i: (pts[i][0] - pts[0][0]) ** 2 + (pts[i][1] - pts[0][1]) ** 2)
            pts = dp(pts[:k + 1], 0.7)[:-1] + dp(pts[k:] + [pts[0]], 0.7)[:-1]
        if len(pts) >= 3:
            out.append([round(v, 2) for q in pts for v in ((q[0]) / sc + wx, (q[1]) / sc + wy)])
    return out

S2 = 20
MIN_HAIR = int(os.environ.get('MIN_HAIR', 8))   # px (20px/birim): daha küçük saç telleri görünmez
HS = []
def hairline(adds):
    """Kırık (çok halkalı) eyaleti olan ülkelerde 5 px/birim ızgaranın göremediği saç teli aralıklarını 20 px/birim ile kapat."""
    cn = {}
    for p in P:
        if len(p["rings"]) >= 3 and C[p["c"]]["name_en"] not in SKIP:
            cn.setdefault(p["c"], []).append(p["id"])
    added = 0
    for c, pl in sorted(cn.items()):
        own = [p for p in P if p["c"] == c]
        bx0 = min(p["bb"][0] for p in own) - 1; by0 = min(p["bb"][1] for p in own) - 1
        bx1 = max(p["bb"][2] for p in own) + 1; by1 = max(p["bb"][3] for p in own) + 1
        tw, th = int((bx1 - bx0) * S2), int((by1 - by0) * S2)
        if tw * th > 70_000_000: continue
        near = [p for p in P if not (p["bb"][2] < bx0 or p["bb"][0] > bx1 or p["bb"][3] < by0 or p["bb"][1] > by1)]
        im = Image.new("I", (tw, th), 0); d = ImageDraw.Draw(im)
        for p in near:
            for r in list(p["rings"]) + adds.get(p["id"], []):
                d.polygon([((r[i] - bx0) * S2, (r[i + 1] - by0) * S2) for i in range(0, len(r), 2)], fill=p["id"] + 1)
        ids = np.array(im, dtype=np.int32); del im
        land = ids > 0
        closed = ndi.binary_erosion(ndi.binary_dilation(land, structure=disk(2)), structure=disk(2))
        gap = closed & ~land
        lab, n = ndi.label(gap)
        for i, sl in enumerate(ndi.find_objects(lab), 1):
            m = lab[sl] == i
            HS.append(int(m.sum()))
            if m.sum() > 1.5 * S2 * S2 or m.sum() < MIN_HAIR: continue
            y0, y1 = max(sl[0].start - 6, 0), min(sl[0].stop + 6, th); x0, x1 = max(sl[1].start - 6, 0), min(sl[1].stop + 6, tw)
            cid = ids[y0:y1, x0:x1]
            full = np.zeros(cid.shape, bool)
            full[sl[0].start - y0:sl[0].stop - y0, sl[1].start - x0:sl[1].stop - x0] = m
            _, (iy, ix) = ndi.distance_transform_edt(cid <= 0, return_indices=True)
            nr = cid[iy, ix] - 1
            present = set(np.unique(nr[full]).tolist())
            if -1 in present: present.discard(-1)
            if not present: continue
            cs = {P[a]["c"] for a in present}
            if len(cs) > 1 and not any(b in adj.get(a, ()) for a in present for b in present if b != a): continue
            for a in present:
                pm = full & (nr == a)
                if not pm.any(): continue
                for ring in polys(pm, x0, y0, S2, bx0, by0):
                    adds.setdefault(a, []).append(ring); added += 1
    print("saç teli aralığı: eklenen halka", added)
    if HS:
        a_ = np.array(HS); print("saç teli bileşen boyut dağılımı (px) >=1,4,8,16,40,100:", [int((a_>=t).sum()) for t in (1,4,8,16,40,100)])

def fix_borders(ids0, T):
    """Dolgu sonrası kara içinde kalan kıyı çizgilerini (b=-1) at; iki farklı eyaletin arasında kalanları o ikilinin sınırına çevir."""
    ids2 = raster([(r, p["id"] + 1) for p in P for r in p["rings"]])
    din = ndi.distance_transform_edt(ids2 > 0)
    dold = ndi.distance_transform_edt(ids0 > 0)
    def px(x, y): return (int(round((x - X0) * S)), int(round((y - Y0) * S)))
    def inside(x, y):
        ix, iy = px(x, y)
        return 0 <= ix < W and 0 <= iy < H and (din[iy, ix] > 2.5 or din[iy, ix] - dold[iy, ix] >= 1.0)
    def other_side(a, pts):
        votes = {}
        for k in range(len(pts) - 1):
            (x1, y1), (x2, y2) = pts[k], pts[k + 1]
            dx, dy = x2 - x1, y2 - y1
            L = (dx * dx + dy * dy) ** 0.5 or 1e-9
            nx, ny = -dy / L, dx / L
            mx, my = (x1 + x2) / 2, (y1 + y2) / 2
            for sgn in (1, -1):
                hit = 0
                for st in range(1, 16):
                    ix, iy = px(mx + sgn * nx * st / S, my + sgn * ny * st / S)
                    if not (0 <= ix < W and 0 <= iy < H): break
                    v = ids0[iy, ix] - 1
                    if v >= 0 and st <= 2: break          # bu yan kara tarafı
                    if v >= 0:
                        hit = v; break
                if hit or (hit == 0 and False):
                    pass
                if st > 2 and v >= 0 and ids0[iy, ix] - 1 >= 0:
                    votes[int(v)] = votes.get(int(v), 0) + 1
        return max(votes, key=votes.get) if votes else -1
    def stale_segs(pts):
        """Her parça için: iki yanındaki (3 px) eyalet aynıysa eski/ölü sınırdır."""
        res = []
        for k in range(len(pts) - 1):
            (x1, y1), (x2, y2) = pts[k], pts[k + 1]
            dx, dy = x2 - x1, y2 - y1
            L = (dx * dx + dy * dy) ** 0.5 or 1e-9
            nx, ny = -dy / L, dx / L
            mx, my = (x1 + x2) / 2, (y1 + y2) / 2
            i1 = px(mx + nx * 3 / S, my + ny * 3 / S); i2 = px(mx - nx * 3 / S, my - ny * 3 / S)
            if not (0 <= i1[0] < W and 0 <= i1[1] < H and 0 <= i2[0] < W and 0 <= i2[1] < H):
                res.append(False); continue
            v1 = ids2[i1[1], i1[0]]; v2 = ids2[i2[1], i2[0]]
            res.append(bool(v1 > 0 and v1 == v2))
        return res
    out = []; dropped = conv = sdrop = 0
    for b in w["borders"]:
        if b["b"] >= 0:
            if b["a"] in T or b["b"] in T: sdrop += 1; continue    # dokunulan eyaletlerin iç sınırları aşağıda rastterden yeniden üretilir
            out.append(b); continue
        flat = b["p"]; pts = [(flat[i], flat[i + 1]) for i in range(0, len(flat), 2)]
        if len(pts) > 3 and abs(pts[0][0] - pts[-1][0]) < 0.011 and abs(pts[0][1] - pts[-1][1]) < 0.011:
            # kapalı halka: içi eskiden su, şimdi kara ise doldurulmuş delik/koydur
            xs_ = [q[0] for q in pts]; ys_ = [q[1] for q in pts]
            gx0 = max(int((min(xs_) - X0) * S) - 1, 0); gy0 = max(int((min(ys_) - Y0) * S) - 1, 0)
            gx1 = min(int((max(xs_) - X0) * S) + 2, W); gy1 = min(int((max(ys_) - Y0) * S) + 2, H)
            if gx1 - gx0 > 1 and gy1 - gy0 > 1 and (gx1 - gx0) * (gy1 - gy0) < 4_000_000:
                im = Image.new("L", (gx1 - gx0, gy1 - gy0), 0)
                ImageDraw.Draw(im).polygon([((q[0] - X0) * S - gx0, (q[1] - Y0) * S - gy0) for q in pts], fill=255)
                mk = np.array(im) > 0
                if mk.sum() > 0:
                    new_f = (ids2[gy0:gy1, gx0:gx1][mk] > 0).mean(); old_f = (ids0[gy0:gy1, gx0:gx1][mk] > 0).mean()
                    if new_f > 0.7 and old_f < 0.3:
                        dropped += 1; continue
        flags = [inside(x, y) for x, y in pts]
        if not any(flags):
            out.append(b); continue
        # ardışık içeride/dışarıda koşullara böl
        runs = []; cur = [pts[0]]; cf = flags[0]
        for i in range(1, len(pts)):
            if flags[i] == cf: cur.append(pts[i])
            else:
                cur.append(pts[i]); runs.append((cf, cur)); cur = [pts[i]]; cf = flags[i]
        runs.append((cf, cur))
        for f, run in runs:
            if len(run) < 2: continue
            if not f:
                out.append({"a": b["a"], "b": -1, "p": [round(v, 2) for q in run for v in q]}); continue
            o = other_side(b["a"], run)
            if o >= 0 and o != b["a"]:
                a2, b2 = min(b["a"], o), max(b["a"], o)
                out.append({"a": a2, "b": b2, "p": [round(v, 2) for q in run for v in q]}); conv += 1
            else:
                dropped += 1
    # dokunulan eyaletlerin iç sınırlarını id rasterinden yeniden çiz
    newb = 0
    for u in sorted(T):
        bb = P[u]["bb"]
        x0 = max(int((bb[0] - X0) * S) - 4, 0); x1 = min(int((bb[2] - X0) * S) + 5, W)
        y0 = max(int((bb[1] - Y0) * S) - 4, 0); y1 = min(int((bb[3] - Y0) * S) + 5, H)
        crop = ids2[y0:y1, x0:x1]
        m = (crop == u + 1)
        if not m.any(): continue
        for line in contour_generator(z=np.pad(m.astype(np.float32), 1)).lines(0.5):
            pts = [(float(x) - 1, float(y) - 1) for x, y in line]
            if len(pts) < 3: continue
            vs = []
            for k in range(len(pts)):
                p0 = pts[k - 1]; p1 = pts[(k + 1) % len(pts)]
                dx, dy = p1[0] - p0[0], p1[1] - p0[1]
                L = (dx * dx + dy * dy) ** 0.5 or 1e-9
                nx, ny = -dy / L, dx / L
                v = -2
                for sg in (1, -1):
                    ix = int(round(pts[k][0] + sg * nx * 1.5)); iy = int(round(pts[k][1] + sg * ny * 1.5))
                    if 0 <= ix < crop.shape[1] and 0 <= iy < crop.shape[0] and crop[iy, ix] != u + 1:
                        v = int(crop[iy, ix]) - 1; break
                vs.append(v)
            # ardışık aynı komşu koşulları
            k0 = 0
            while k0 < len(pts) and vs[k0] == vs[k0 - 1] and k0 < len(pts) - 1: k0 += 1
            runs = []; cur = [pts[k0 % len(pts)]]; cv = vs[k0 % len(pts)]
            for t in range(1, len(pts) + 1):
                i = (k0 + t) % len(pts)
                if vs[i] == cv:
                    cur.append(pts[i])
                else:
                    cur.append(pts[i]); runs.append((cv, cur)); cur = [pts[i]]; cv = vs[i]
            runs.append((cv, cur))
            for v, run in runs:
                if v < 0 or len(run) < 3: continue          # kıyı (zaten var) ya da çok kısa
                if v in T and v < u: continue              # ikilinin çizgisi küçük id tarafından üretilir
                run = dp(run, 0.5) if len(run) > 2 else run
                if len(run) < 2: continue
                out.append({"a": min(u, v), "b": max(u, v), "p": [round(q, 2) for t in run for q in ((t[0] + x0) / S + X0, (t[1] + y0) / S + Y0)]})
                newb += 1
    w["borders"] = out
    print("yeniden üretilen iç sınır çizgisi:", newb)
    print("sınır çizgisi: atılan kıyı %d, çevrilen %d, ölü iç sınır parçası %d" % (dropped, conv, sdrop))

def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "report"
    ids = raster([(r, p["id"] + 1) for p in P for r in p["rings"]])
    land = ids > 0
    lake = raster([(r, 1) for r in w["lakes"]]) > 0
    bg = ~land
    lab, n = ndi.label(bg)
    sizes = np.asarray(ndi.sum(bg, lab, range(1, n + 1)))
    ocean = int(np.argmax(sizes)) + 1
    objs = ndi.find_objects(lab)
    dock = ndi.distance_transform_edt(lab != ocean) / S   # okyanusa uzaklık (birim)
    jobs = []   # (mask slice, bool crop mask, kind)
    for i in range(1, n + 1):
        if i == ocean: continue
        a = sizes[i - 1] / (S * S)
        if a > HOLE_MAX: continue
        sl = objs[i - 1]
        m = lab[sl] == i
        if (lake[sl] & m).sum() > 0.3 * m.sum(): continue
        if os.environ.get('DBG') and abs((sl[1].start+sl[1].stop)/2/S+X0-126.9)<2 and abs((sl[0].start+sl[0].stop)/2/S+Y0+318)<2: print('DBGH',a,dock[sl][m].min())
        dm = dock[sl][m].min()
        if os.environ.get('LISTNEAR') and dm < OCEAN_MIN and a >= 0.5:
            print('NEAR %.2f dock=%.2f (%.1f,%.1f) %s' % (a, dm, (sl[1].start+sl[1].stop)/2/S+X0, (sl[0].start+sl[0].stop)/2/S+Y0, sorted({C[P[q]['c']]['name_en'] for q in set((ids[max(sl[0].start-3,0):sl[0].stop+3, max(sl[1].start-3,0):sl[1].stop+3].ravel()-1).tolist()) if q>=0})))
        cxx = (sl[1].start + sl[1].stop) / 2 / S + X0; cyy = (sl[0].start + sl[0].stop) / 2 / S + Y0
        forced = any(b[0] <= cxx <= b[2] and b[1] <= cyy <= b[3] for b in FORCE_BOX)
        if dm < OCEAN_MIN and not forced: continue    # kıyıya yakın kapalı koy/haliç: gerçek su, dokunma
        jobs.append((sl, m, "delik"))
    nh = len(jobs)
    closed = ndi.binary_erosion(ndi.binary_dilation(land, structure=disk(GAP_R)), structure=disk(GAP_R))
    wide = ndi.binary_opening(bg, structure=disk(5))          # geniş su (>=2 birim)
    dw = ndi.distance_transform_edt(~wide)
    gap = closed & bg & (dw >= WIDE_MIN)                       # kıyı/boğaz ağızlarına dokunma
    # delik olarak işlenenleri çıkar
    for sl, m, _ in jobs:
        gap[sl] &= ~m
    # zorla bölgeler (Baltık): kıyıya yakın olsa da tek ülkenin kendi eyaletleri arasındaki ince ağızlar doldurulur
    gall = closed & bg
    for hole_sl, hole_m, _k in jobs: gall[hole_sl] &= ~hole_m
    fb = np.zeros_like(gap)
    for (bx0, by0, bx1, by1) in FORCE_BOX:
        fb[max(int((by0 - Y0) * S), 0):int((by1 - Y0) * S), max(int((bx0 - X0) * S), 0):int((bx1 - X0) * S)] = True
    gapB = gall & fb & ~gap
    blab, bn = ndi.label(gapB)
    bobjs = ndi.find_objects(blab)
    for i in range(1, bn + 1):
        jobs.append((bobjs[i - 1], blab[bobjs[i - 1]] == i, "aralık-tek"))
    glab, gn = ndi.label(gap)
    gobjs = ndi.find_objects(glab)
    for i in range(1, gn + 1):
        sl = gobjs[i - 1]
        gm = glab[sl] == i
        if dock[sl][gm].mean() < GAP_OCEAN: continue          # kıyıdaki koy/boğaz ağzı: dokunma
        jobs.append((sl, gm, "aralık"))
    adds = {}   # prov id -> [rings]
    log = []
    for sl, m, kind in jobs:
        y0, y1 = max(sl[0].start - 8, 0), min(sl[0].stop + 8, H)
        x0, x1 = max(sl[1].start - 8, 0), min(sl[1].stop + 8, W)
        cid = ids[y0:y1, x0:x1]
        full = np.zeros(cid.shape, bool)
        full[sl[0].start - y0:sl[0].stop - y0, sl[1].start - x0:sl[1].stop - x0] = m
        _, (iy, ix) = ndi.distance_transform_edt(cid <= 0, return_indices=True)
        near = cid[iy, ix] - 1
        present = set(np.unique(near[full]).tolist())
        if os.environ.get('DBG3') and abs((sl[1].start+sl[1].stop)/2/S+X0-108.4)<1.2 and abs((sl[0].start+sl[0].stop)/2/S+Y0+320.7)<1.2: print('DBG3',kind,m.sum(),sorted(present),{P[a]['c'] for a in present})
        if kind == "aralık-tek":
            cs = {P[a]["c"] for a in present}
            if len(cs) != 1: continue
            keep = present
        elif kind == "aralık":
            keep = {a for a in present if any(b in adj.get(a, ()) for b in present if b != a)}
            if not keep: continue
        else:
            keep = present
        area = full.sum() / (S * S)
        cx = (x0 + (sl[1].start + sl[1].stop) / 2 - x0) / S + X0
        cy = (sl[0].start + sl[0].stop) / 2 / S + Y0
        names = sorted({C[P[a]["c"]]["name_en"] for a in present})
        if any(nm in SKIP for nm in names) and not any(b[0] <= cx <= b[2] and b[1] <= cy <= b[3] for b in FORCE_BOX): continue
        if os.environ.get('DBG2') and len(log)<3: print('DBG2',kind,present,keep,full.sum())
        for a in keep:
            pm = full & (near == a)
            if pm.sum() == 0: continue
            for ring in polys(pm, x0, y0):
                adds.setdefault(a, []).append(ring)
        log.append((kind, round(area, 2), round(cx, 1), round(cy, 1), names))
    if os.environ.get("DBG"):
        for x in log:
            if abs(x[2]-127)<6 and abs(x[3]+320)<8: print("DBG",x)
    hairline(adds)
    print("delik: %d aday, toplam parça: %d, halka eklenecek: %d, eyalet: %d" % (nh, len(log), sum(len(v) for v in adds.values()), len(adds)))
    for k in ("delik", "aralık", "aralık-tek"):
        l = [x for x in log if x[0] == k]
        print(k, len(l), "alan toplamı %.1f" % sum(x[1] for x in l))
    for x in sorted(log, key=lambda t: -t[1])[:int(os.environ.get('TOP', 25))]: print("  ", x)
    if mode == "apply":
        for a, rings in adds.items():
            p = P[a]
            p["rings"].extend(rings)
            xs = [v for r in p["rings"] for v in r[0::2]]; ys = [v for r in p["rings"] for v in r[1::2]]
            p["bb"] = [round(min(xs), 2), round(min(ys), 2), round(max(xs), 2), round(max(ys), 2)]
        co = {b["a"] for b in w["borders"] if b["b"] < 0}
        fix_borders(ids, set(adds))
        cn = {b["a"] for b in w["borders"] if b["b"] < 0}
        lost = sorted(co - cn); cut = 0
        for i in lost:   # artık kıyıda olmayan (eski delik yüzünden 'kıyı' sayılan) eyaletlerin deniz bağlantılarını kes
            for q in P[i]["sea"]:
                if i in P[q]["sea"]: P[q]["sea"].remove(i)
            cut += len(P[i]["sea"]); P[i]["sea"] = []
        print("kıyısını yitiren eyalet: %d, kesilen deniz bağlantısı: %d" % (len(lost), cut))
        tmp = WP + ".tmp"
        json.dump(w, open(tmp, "w"), ensure_ascii=False, separators=(",", ":"))
        os.replace(tmp, WP)
        print("yazıldı", WP)

if __name__ == "__main__":
    main()
