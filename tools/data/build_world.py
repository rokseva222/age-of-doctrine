#!/usr/bin/env python3
"""Natural Earth (kamu malı) verisinden oyun dünyasını üretir.

Girdi  : a0.geojson (ülkeler), a1.geojson (eyaletler), pp.geojson (şehirler), lakes.geojson (göller)
Çıktı  : data/world.json   (oyunun okuduğu tek dosya)

Adımlar:
 1. Köşe noktalarını ızgaraya oturt, ortak sınırları "yay"lara böl, her yayı tek kez sadeleştir (komşu sınırlar kaymaz).
 2. Eyaletleri ülke başına hedef sayıya göre birleştir (küçükten büyüğe, en uzun ortak sınırlı komşuya).
 3. Komşuluk, kıyı, deniz bağlantıları, şehir/başkent atamaları, etiket noktaları.
 4. Miller izdüşümüyle düzlem koordinatlarına çevir, JSON yaz.
"""
import json, math, sys, os, heapq, collections
import numpy as np

SRC = os.environ.get("NE_SRC", "/tmp/data")
OUT = os.environ.get("NE_OUT", os.path.join(os.path.dirname(__file__), "..", "..", "data", "world.json"))
EPS = float(os.environ.get("NE_EPS", "0.02"))          # sadeleştirme toleransı (derece)
K_AREA = float(os.environ.get("NE_KAREA", "9.0"))
K_POP = float(os.environ.get("NE_KPOP", "1.5"))
MAX_PROV = int(os.environ.get("NE_MAXPROV", "110"))
BIG_CITY = float(os.environ.get("NE_BIGCITY", "1.0e6"))     # bu nüfusun üstündeki şehirler kendi eyaletini korur
SCALE = 5.0                                           # dünya birimi / derece


def log(*a):
    print(*a, file=sys.stderr, flush=True)


# ------------------------------------------------------------------ izdüşüm
def miller(lon, lat):
    phi = math.radians(max(-80.0, min(84.0, lat)))
    y = 1.25 * math.log(math.tan(math.pi / 4 + 0.4 * phi))
    return lon * SCALE, -math.degrees(y) * SCALE


# ------------------------------------------------------------------ yardımcılar
def ring_area(pts):
    s = 0.0
    n = len(pts)
    for i in range(n):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % n]
        s += x1 * y2 - x2 * y1
    return s / 2.0


def km2(area_deg2, lat):
    return abs(area_deg2) * math.cos(math.radians(lat)) * 111.32 * 111.32


def dp_simplify(xs, ys, eps):
    """Douglas-Peucker; indeks listesi döndürür (uçlar dahil)."""
    n = len(xs)
    if n <= 2:
        return list(range(n))
    keep = np.zeros(n, dtype=bool)
    keep[0] = keep[-1] = True
    stack = [(0, n - 1)]
    while stack:
        a, b = stack.pop()
        if b <= a + 1:
            continue
        ax, ay, bx, by = xs[a], ys[a], xs[b], ys[b]
        px = xs[a + 1:b]
        py = ys[a + 1:b]
        dx, dy = bx - ax, by - ay
        L = math.hypot(dx, dy)
        if L < 1e-12:
            d = np.hypot(px - ax, py - ay)
        else:
            d = np.abs(dx * (py - ay) - dy * (px - ax)) / L
        i = int(np.argmax(d))
        if d[i] > eps:
            m = a + 1 + i
            keep[m] = True
            stack.append((a, m))
            stack.append((m, b))
    return list(np.nonzero(keep)[0])


# ------------------------------------------------------------------ 1. veriyi oku
def load():
    a0 = json.load(open(os.path.join(SRC, "a0.geojson")))["features"]
    a1 = json.load(open(os.path.join(SRC, "a1.geojson")))["features"]
    pp = json.load(open(os.path.join(SRC, "pp.geojson")))["features"]
    lk = json.load(open(os.path.join(SRC, "lakes.geojson")))["features"]
    return a0, a1, pp, lk


def polys(geom):
    if geom["type"] == "Polygon":
        return [geom["coordinates"]]
    if geom["type"] == "MultiPolygon":
        return geom["coordinates"]
    return []


DROP_ADM0 = {"ATA", "BRI", "SPI", "BRT", "BJN", "SER", "SCR", "PGA", "CNM", "KAS", "ATF", "HMD", "SGS", "IOA", "CSI", "ATC", "CLP", "UMI", "PCN"}
OWN_GROUP = {"PSX": "PSX", "KOS": "KOS", "SAH": "SAH", "TWN": "TWN", "GRL": "GRL"}   # kendi başına ülke sayılanlar
NAME_OVERRIDE = {
    "USA": "ABD", "GBR": "Birleşik Krallık", "ARE": "BAE", "COD": "DK Kongo", "COG": "Kongo", "CAF": "Orta Afrika",
    "DOM": "Dominik Cum.", "BIH": "Bosna-Hersek", "MKD": "Kuzey Makedonya", "TLS": "Doğu Timor", "PRK": "Kuzey Kore",
    "KOR": "Güney Kore", "SAH": "Batı Sahra", "PSX": "Filistin", "KOS": "Kosova", "CZE": "Çekya", "SWZ": "Esvatini",
    "TTO": "Trinidad-Tobago", "STP": "São Tomé", "VCT": "St. Vincent", "KNA": "St. Kitts", "ATG": "Antigua",
    "RUS": "Rusya", "GRL": "Grönland", "CHN": "Çin", "DEU": "Almanya", "FRA": "Fransa", "ITA": "İtalya", "ESP": "İspanya",
}


def main():
    a0, a1, pp, lk = load()
    log("okundu", len(a0), len(a1), len(pp), len(lk))

    # ---- ülke grupları (SOV_A3 ya da özel)
    adm0_group = {}
    adm0_info = {}
    for f in a0:
        p = f["properties"]
        a3 = p["ADM0_A3"]
        if a3 in DROP_ADM0:
            continue
        key = OWN_GROUP.get(a3, p["SOV_A3"])
        adm0_group[a3] = key
        adm0_info[a3] = p
    groups = collections.defaultdict(list)
    for a3, k in adm0_group.items():
        groups[k].append(a3)
    # grubun ana ADM0'ı = nüfusu en büyük
    group_main = {}
    for k, lst in groups.items():
        lst.sort(key=lambda a: -(adm0_info[a]["POP_EST"] or 0))
        group_main[k] = lst[0]
    # Sovereign tipli olanı öne al
    for k, lst in groups.items():
        for a in lst:
            if adm0_info[a]["TYPE"] in ("Sovereign country", "Country", "Sovereignty") and a == k[:3] or a == k:
                group_main[k] = a
                break

    # ---- birimler: eyalet (a1) varsa onlar, yoksa ülke poligonu
    units = []   # dict: rings(list of list of (lon,lat)), group, name, a3
    a1_by = collections.defaultdict(list)
    for f in a1:
        a1_by[f["properties"]["adm0_a3"]].append(f)
    for f in a0:
        p = f["properties"]
        a3 = p["ADM0_A3"]
        if a3 not in adm0_group:
            continue
        g = adm0_group[a3]
        if a3 in a1_by:
            for ff in a1_by[a3]:
                q = ff["properties"]
                nm = q.get("name") or q.get("name_en") or "?"
                if any(ord(ch) > 0x24F for ch in nm):
                    nm = q.get("name_en") or q.get("name_alt") or nm
                units.append({"geom": ff["geometry"], "group": g, "name": nm, "a3": a3})
        else:
            nm = p.get("NAME_TR") or p["NAME"]
            units.append({"geom": f["geometry"], "group": g, "name": nm, "a3": a3})
    log("birim sayısı", len(units))

    # ---- köşe ızgarası / id
    vid = {}
    vx, vy = [], []

    def V(lon, lat):
        k = (round(lon * 1e4), round(lat * 1e4))
        i = vid.get(k)
        if i is None:
            i = len(vx)
            vid[k] = i
            vx.append(k[0] / 1e4)
            vy.append(k[1] / 1e4)
        return i

    raw_rings = []   # (unit_idx, [vid...], is_outer)
    for ui, u in enumerate(units):
        for poly in polys(u["geom"]):
            for ri, ring in enumerate(poly):
                ids = []
                for c in ring:
                    i = V(c[0], c[1])
                    if not ids or ids[-1] != i:
                        ids.append(i)
                if len(ids) > 1 and ids[0] == ids[-1]:
                    ids.pop()
                if len(ids) < 3:
                    continue
                pts = [(vx[i], vy[i]) for i in ids]
                ar = ring_area(pts)
                if abs(ar) < 1e-9:
                    continue
                outer = ri == 0
                # dış halka CCW, delik CW olsun
                if (outer and ar < 0) or ((not outer) and ar > 0):
                    ids.reverse()
                raw_rings.append((ui, ids, outer))
    log("köşe", len(vx), "halka", len(raw_rings))

    # ---- kavşaklar
    neigh = collections.defaultdict(set)
    for ui, ids, outer in raw_rings:
        n = len(ids)
        for k in range(n):
            v = ids[k]
            neigh[v].add(ids[k - 1])
            neigh[v].add(ids[(k + 1) % n])
    junction = {v for v, s in neigh.items() if len(s) > 2}
    log("kavşak", len(junction))

    VX = np.array(vx)
    VY = np.array(vy)
    arc_cache = {}

    def simp_arc(arc):
        """arc: köşe id listesi (kapalı değilse uçları sabit). Kanonik yönde sadeleştirir."""
        t = tuple(arc)
        r = tuple(reversed(arc))
        if r < t:
            canon, rev = r, True
        else:
            canon, rev = t, False
        out = arc_cache.get(canon)
        if out is None:
            ca = np.array(canon)
            idx = dp_simplify(VX[ca], VY[ca], EPS)
            out = tuple(canon[i] for i in idx)
            arc_cache[canon] = out
        return list(reversed(out)) if rev else list(out)

    unit_rings = collections.defaultdict(list)    # ui -> [(ids, outer)]
    for ui, ids, outer in raw_rings:
        n = len(ids)
        js = [k for k in range(n) if ids[k] in junction]
        if not js:
            # kapalı halka: en küçük (x,y) köşede sabitle
            k0 = min(range(n), key=lambda k: (vx[ids[k]], vy[ids[k]], ids[k]))
            arc = ids[k0:] + ids[:k0] + [ids[k0]]
            s = simp_arc(arc)
            s = s[:-1]
            if len(s) >= 3:
                unit_rings[ui].append((s, outer))
            continue
        k0 = js[0]
        rot = ids[k0:] + ids[:k0]
        rot.append(rot[0])
        res = []
        cur = [rot[0]]
        for v in rot[1:]:
            cur.append(v)
            if v in junction:
                s = simp_arc(cur)
                res.extend(s[:-1])
                cur = [v]
        # son yay zaten döndü
        if len(res) >= 3:
            unit_rings[ui].append((res, outer))
    tot = sum(len(r[0]) for rs in unit_rings.values() for r in rs)
    log("sadeleştirme sonrası köşe", tot, "yay", len(arc_cache))

    # ---- birim alanı / merkezi
    def unit_stats(ui):
        area = 0.0
        cx = cy = 0.0
        wsum = 0.0
        biggest = 0.0
        for ids, outer in unit_rings[ui]:
            if not outer:
                continue
            pts = [(vx[i], vy[i]) for i in ids]
            a = abs(ring_area(pts))
            lat = sum(p[1] for p in pts) / len(pts)
            ak = km2(a, lat)
            area += ak
            biggest = max(biggest, ak)
            mx = sum(p[0] for p in pts) / len(pts)
            cx += mx * ak
            cy += lat * ak
            wsum += ak
        if wsum > 0:
            cx /= wsum
            cy /= wsum
        return area, (cx, cy), biggest

    ustat = {ui: unit_stats(ui) for ui in range(len(units))}

    # ---- birim komşuluğu (ortak kenarlar)
    edge_owner = {}
    for ui, rs in unit_rings.items():
        for ids, outer in rs:
            n = len(ids)
            for k in range(n):
                edge_owner[(ids[k], ids[(k + 1) % n])] = ui
    shared = collections.defaultdict(float)     # (ua,ub) -> uzunluk
    for (u, v), ua in edge_owner.items():
        ub = edge_owner.get((v, u))
        if ub is not None and ub != ua:
            shared[(ua, ub)] += math.hypot(vx[u] - vx[v], vy[u] - vy[v])
    unit_nb = collections.defaultdict(dict)
    for (ua, ub), L in shared.items():
        if units[ua]["group"] == units[ub]["group"]:
            unit_nb[ua][ub] = L

    # ---- grup başına hedef sayı ve birleştirme
    gpop = collections.defaultdict(float)
    ggdp = collections.defaultdict(float)
    for a3, g in adm0_group.items():
        gpop[g] += adm0_info[a3]["POP_EST"] or 0
        ggdp[g] += adm0_info[a3]["GDP_MD"] or 0
    # PSX/ISR gibi: nüfus/GSYH zaten ADM0 başına

    unit_to_prov_root = {}       # birleştirme için union-find
    parent = list(range(len(units)))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    members = {}                 # kök -> [birimler]
    area_of = {}
    cent_of = {}
    for ui in range(len(units)):
        members[ui] = [ui]
        area_of[ui] = ustat[ui][0]
        cent_of[ui] = ustat[ui][1]
    unit_by_group = collections.defaultdict(list)
    for ui, u in enumerate(units):
        if ustat[ui][0] > 0:
            unit_by_group[u["group"]].append(ui)

    # ---- büyük şehirler / başkentler: bulundukları birim birleştirilirken yok olmasın (Moskova, İstanbul...)
    def _pip(px, py, pts):
        inside = False
        j = len(pts) - 1
        for i in range(len(pts)):
            xi, yi = pts[i]
            xj, yj = pts[j]
            if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi + 1e-18) + xi:
                inside = not inside
            j = i
        return inside

    ubox = {}
    ugrid = collections.defaultdict(list)
    for ui in range(len(units)):
        polys_u = [[(vx[i], vy[i]) for i in ids] for ids, outer in unit_rings[ui] if outer]
        if not polys_u:
            continue
        xs_ = [q[0] for pl in polys_u for q in pl]
        ys_ = [q[1] for pl in polys_u for q in pl]
        ubox[ui] = (min(xs_), min(ys_), max(xs_), max(ys_), polys_u)
        for gx in range(int(min(xs_) // 5), int(max(xs_) // 5) + 1):
            for gy in range(int(min(ys_) // 5), int(max(ys_) // 5) + 1):
                ugrid[(gx, gy)].append(ui)
    protected = set()
    for f in pp:
        pr_ = f["properties"]
        popm = pr_["POP_MAX"] or 0
        a3_ = pr_["ADM0_A3"]
        if a3_ not in adm0_group or not (popm >= BIG_CITY or pr_.get("ADM0CAP") == 1):
            continue
        cx_, cy_ = f["geometry"]["coordinates"][0], f["geometry"]["coordinates"][1]
        for ui in ugrid.get((int(cx_ // 5), int(cy_ // 5)), ()):
            if units[ui]["group"] != adm0_group[a3_]:
                continue
            b = ubox[ui]
            if b[0] <= cx_ <= b[2] and b[1] <= cy_ <= b[3] and any(_pip(cx_, cy_, pl) for pl in b[4]):
                protected.add(ui)
                break
    log("korunan birim (büyük şehir/başkent)", len(protected))

    dropped = set()
    for g, ul in unit_by_group.items():
        tot_area = sum(area_of[u] for u in ul)
        # çok küçük uzak adacıkları at (grubun tek parçası değilse)
        big = max(ul, key=lambda u: area_of[u])
        if len(ul) > 1:
            for u in ul:
                if u == big:
                    continue
                if area_of[u] < 1500:
                    # en yakın diğer birime uzaklık
                    d = min(math.hypot(cent_of[u][0] - cent_of[o][0], cent_of[u][1] - cent_of[o][1]) for o in ul if o != u)
                    if d > 6.0 or area_of[u] < 150:
                        dropped.add(u)
        ul[:] = [u for u in ul if u not in dropped]
        pop_m = gpop[g] / 1e6
        target = int(round(K_AREA * math.sqrt(tot_area / 1e6) + K_POP * math.sqrt(max(pop_m, 0.0))))
        nprot = sum(1 for u in ul if u in protected)
        target = max(1, min(MAX_PROV, target))
        target = max(target, min(MAX_PROV + 12, nprot + max(2, target // 4)))
        alive = set(ul)
        heap = [(area_of[u], u) for u in alive]
        heapq.heapify(heap)
        # aktif komşuluk (kök bazlı)
        adj = {u: dict(unit_nb.get(u, {})) for u in alive}
        for u in alive:
            adj[u] = {v: L for v, L in adj[u].items() if v in alive}
        while len(alive) > target and heap:
            a, u = heapq.heappop(heap)
            if u not in alive or abs(a - area_of[u]) > 1e-6:
                continue
            if u in protected:
                continue            # büyük şehir birimi kaynak olarak birleşmez; çevresini kendine alabilir
            nbs = adj.get(u, {})
            tgt = None
            if nbs:
                mx = max(nbs.values())
                cands = [v for v, L in nbs.items() if L >= 0.25 * mx]
                tgt = min(cands, key=lambda v: area_of[v])
            else:
                # kara komşusu yok: yakın bir birime katıl
                best = None
                for o in alive:
                    if o == u:
                        continue
                    d = math.hypot(cent_of[u][0] - cent_of[o][0], cent_of[u][1] - cent_of[o][1])
                    if best is None or d < best[0]:
                        best = (d, o)
                if best and best[0] < 9.0:
                    tgt = best[1]
            if tgt is None:
                continue            # birleştirilemez, olduğu gibi kalsın
            # u'yu tgt'ye kat
            members[tgt].extend(members.pop(u))
            na = area_of[u] + area_of[tgt]
            cent_of[tgt] = ((cent_of[u][0] * area_of[u] + cent_of[tgt][0] * area_of[tgt]) / na,
                            (cent_of[u][1] * area_of[u] + cent_of[tgt][1] * area_of[tgt]) / na)
            area_of[tgt] = na
            for v, L in adj.pop(u, {}).items():
                if v == tgt:
                    continue
                adj[v].pop(u, None)
                adj[v][tgt] = adj[v].get(tgt, 0) + L
                adj[tgt][v] = adj[tgt].get(v, 0) + L
            adj[tgt].pop(u, None)
            alive.discard(u)
            heapq.heappush(heap, (area_of[tgt], tgt))
        unit_by_group[g] = sorted(alive)
    for u in dropped:
        members.pop(u, None)

    log("atılan birim", len(dropped))

    # ---- ülkeleri sırala/numarala (nüfusa göre)
    order = sorted(unit_by_group.keys(), key=lambda g: -gpop[g])
    country_idx = {g: i for i, g in enumerate(order)}
    provs = []   # dict
    unit_to_prov = {}
    for g in order:
        for root in unit_by_group[g]:
            pid = len(provs)
            mem = members[root]
            main_u = max(mem, key=lambda u: ustat[u][0])
            for u in mem:
                unit_to_prov[u] = pid
            provs.append({
                "id": pid, "c": country_idx[g], "members": mem, "name": units[main_u]["name"],
                "area": sum(ustat[u][0] for u in mem), "a3": units[main_u]["a3"],
            })
    log("eyalet sayısı", len(provs), "ülke", len(order))

    # ---- halkalar: kalacak halkalar
    prov_rings = collections.defaultdict(list)   # pid -> [(ids, outer)]
    for pr in provs:
        outer_list = []
        for u in pr["members"]:
            for ids, outer in unit_rings[u]:
                if outer:
                    pts = [(vx[i], vy[i]) for i in ids]
                    lat = sum(p[1] for p in pts) / len(pts)
                    outer_list.append((km2(ring_area(pts), lat), ids))
        outer_list.sort(key=lambda t: -t[0])
        small_group = gpop[order[pr["c"]]] < 5e6 and sum(p["area"] for p in provs if p["c"] == pr["c"]) < 40000
        keep_min = 120 if small_group else 400
        if small_group:
            keep_min = 15
        keep_ids = set()
        for k, (ak, ids) in enumerate(outer_list):
            if k == 0 or ak >= keep_min:
                keep_ids.add(id(ids))
        for u in pr["members"]:
            for ids, outer in unit_rings[u]:
                if outer and id(ids) not in keep_ids:
                    continue
                if not outer:
                    # delik: sadece borders için; kalan dış halkaların içindeyse tut
                    pass
                prov_rings[pr["id"]].append((ids, outer))

    # ---- kenarlar -> sınır çizgileri
    E = {}
    for pid, rs in prov_rings.items():
        for ids, outer in rs:
            n = len(ids)
            for k in range(n):
                E[(ids[k], ids[(k + 1) % n])] = pid

    # uzamsal ızgara: kenar orta noktaları
    CELL = 0.3
    grid = collections.defaultdict(list)
    for (u, v), pid in E.items():
        # kenarı örnekle (0.1 dereceden uzunsa böl)
        L = math.hypot(vx[u] - vx[v], vy[u] - vy[v])
        n = max(1, int(L / 0.1))
        for t in range(n):
            f = (t + 0.5) / n
            x = vx[u] + (vx[v] - vx[u]) * f
            y = vy[u] + (vy[v] - vy[u]) * f
            grid[(int(x // CELL), int(y // CELL))].append((x, y, pid))

    def nearest_other(x, y, pid, rad=0.18):
        cx, cy = int(x // CELL), int(y // CELL)
        best = None
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for (px, py, q) in grid.get((cx + dx, cy + dy), ()):
                    if q == pid:
                        continue
                    d = math.hypot(px - x, py - y)
                    if d < rad and (best is None or d < best[0]):
                        best = (d, q)
        return best[1] if best else -1

    seg_groups = collections.defaultdict(list)    # (a,b,kind) -> [(u,v)]
    nb_count = collections.Counter()
    for (u, v), pid in E.items():
        other = E.get((v, u))
        if other is not None:
            if other == pid:
                continue                           # iç kenar
            if pid < other:
                seg_groups[(pid, other)].append((u, v))
            nb_count[(min(pid, other), max(pid, other))] += 3
            continue
        mx = (vx[u] + vx[v]) / 2
        my = (vy[u] + vy[v]) / 2
        q = nearest_other(mx, my, pid)
        if q >= 0:
            seg_groups[(pid, q)].append((u, v))
            nb_count[(min(pid, q), max(pid, q))] += 1
        else:
            seg_groups[(pid, -1)].append((u, v))

    def chain(edges):
        nxt = collections.defaultdict(list)
        for (u, v) in edges:
            nxt[u].append(v)
        used = set()
        lines = []
        starts = set(u for u, _ in edges)
        ends = collections.Counter(v for _, v in edges)
        # zincirin başlangıcı: gelen kenarı olmayan köşeler, yoksa herhangi
        order_u = [u for u in starts if ends[u] == 0] + [u for u in starts]
        for s in order_u:
            for v0 in list(nxt[s]):
                if (s, v0) in used:
                    continue
                line = [s]
                u, v = s, v0
                while True:
                    used.add((u, v))
                    line.append(v)
                    cand = [w for w in nxt[v] if (v, w) not in used]
                    if not cand:
                        break
                    u, v = v, cand[0]
                lines.append(line)
        return lines

    borders = []
    for (a, b), edges in seg_groups.items():
        for line in chain(edges):
            borders.append((a, b, line))
    log("sınır çizgisi", len(borders))

    # komşuluk
    nbrs = collections.defaultdict(set)
    for (a, b), c in nb_count.items():
        if c >= 3:
            nbrs[a].add(b)
            nbrs[b].add(a)

    # ---- karasal bileşenler
    lm = [-1] * len(provs)
    ncomp = 0
    for i in range(len(provs)):
        if lm[i] >= 0:
            continue
        st = [i]
        lm[i] = ncomp
        while st:
            x = st.pop()
            for y in nbrs[x]:
                if lm[y] < 0:
                    lm[y] = ncomp
                    st.append(y)
        ncomp += 1
    log("kara bileşeni", ncomp)

    # ---- kıyı noktaları -> deniz bağlantıları
    coast_pts = collections.defaultdict(list)    # pid -> [(x,y)]
    for (a, b), edges in seg_groups.items():
        if b != -1:
            continue
        for (u, v) in edges:
            L = math.hypot(vx[u] - vx[v], vy[u] - vy[v])
            n = max(1, int(L / 0.6))
            for t in range(n):
                f = (t + 0.5) / n
                coast_pts[a].append((vx[u] + (vx[v] - vx[u]) * f, vy[u] + (vy[v] - vy[u]) * f))
    for pid in coast_pts:
        pts = coast_pts[pid]
        if len(pts) > 40:
            step = len(pts) / 40.0
            coast_pts[pid] = [pts[int(i * step)] for i in range(40)]
    log("kıyı eyalet", len(coast_pts))

    def link_search(rad):
        cellk = max(rad, 1.0)
        g2 = collections.defaultdict(list)
        for pid, pts in coast_pts.items():
            for (x, y) in pts:
                g2[(int(x // cellk), int(y // cellk))].append((x, y, pid))
        best = {}
        for pid, pts in coast_pts.items():
            for (x, y) in pts:
                cx, cy = int(x // cellk), int(y // cellk)
                coslat = math.cos(math.radians(y))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        for (px, py, q) in g2.get((cx + dx, cy + dy), ()):
                            if lm[q] == lm[pid]:
                                continue
                            d = math.hypot((px - x) * coslat, py - y)
                            if d > rad:
                                continue
                            k = (min(pid, q), max(pid, q))
                            if k not in best or d < best[k]:
                                best[k] = d
        return best

    sea = link_search(3.0)
    seaset = collections.defaultdict(set)
    # her eyalet için en yakın 3 bağlantıyı tut
    per = collections.defaultdict(list)
    for (a, b), d in sea.items():
        per[a].append((d, b))
        per[b].append((d, a))
    for a, lst in per.items():
        lst.sort()
        for d, b in lst[:3]:
            seaset[a].add(b)
            seaset[b].add(a)
    # bileşen bağlantısı
    comp_par = list(range(ncomp))

    def cf(x):
        while comp_par[x] != x:
            comp_par[x] = comp_par[comp_par[x]]
            x = comp_par[x]
        return x

    for a in seaset:
        for b in seaset[a]:
            comp_par[cf(lm[a])] = cf(lm[b])
    rad = 6.0
    while True:
        roots = {cf(c) for c in range(ncomp) if any(lm[p] == c for p in coast_pts)}
        # en büyük bileşenle bağlanmamışları bağla
        if len(roots) <= 1 or rad > 80:
            break
        best = link_search(rad)
        cand = sorted((d, a, b) for (a, b), d in best.items())
        added = 0
        for d, a, b in cand:
            if cf(lm[a]) != cf(lm[b]):
                seaset[a].add(b)
                seaset[b].add(a)
                comp_par[cf(lm[a])] = cf(lm[b])
                added += 1
        rad *= 1.8
    log("deniz bağlantısı", sum(len(v) for v in seaset.values()) // 2)

    # ---- şehirler / başkentler
    def pip(px, py, pts):
        inside = False
        n = len(pts)
        j = n - 1
        for i in range(n):
            xi, yi = pts[i]
            xj, yj = pts[j]
            if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi + 1e-18) + xi:
                inside = not inside
            j = i
        return inside

    prov_poly = {}
    prov_bbox = {}
    for pid, rs in prov_rings.items():
        lst = []
        for ids, outer in rs:
            if outer:
                pts = [(vx[i], vy[i]) for i in ids]
                lst.append(pts)
        prov_poly[pid] = lst
        xs = [p[0] for pts in lst for p in pts]
        ys = [p[1] for pts in lst for p in pts]
        prov_bbox[pid] = (min(xs), min(ys), max(xs), max(ys))
    bb_grid = collections.defaultdict(list)
    for pid, (x0, y0, x1, y1) in prov_bbox.items():
        for gx in range(int(x0 // 5), int(x1 // 5) + 1):
            for gy in range(int(y0 // 5), int(y1 // 5) + 1):
                bb_grid[(gx, gy)].append(pid)

    def find_prov(x, y):
        for pid in bb_grid.get((int(x // 5), int(y // 5)), ()):
            x0, y0, x1, y1 = prov_bbox[pid]
            if x0 <= x <= x1 and y0 <= y <= y1:
                for pts in prov_poly[pid]:
                    if pip(x, y, pts):
                        return pid
        # kıyıda kalan noktalar: en yakın kenar örneği
        cx, cy = int(x // CELL), int(y // CELL)
        best = None
        for dx in (-2, -1, 0, 1, 2):
            for dy in (-2, -1, 0, 1, 2):
                for (px, py, q) in grid.get((cx + dx, cy + dy), ()):
                    d = math.hypot(px - x, py - y)
                    if d < 0.5 and (best is None or d < best[0]):
                        best = (d, q)
        return best[1] if best else -1

    def find_prov_near(x, y, c):
        best = None
        for pr in provs:
            if pr["c"] != c:
                continue
            cx, cy = pr["ctr"] if "ctr" in pr else (0, 0)
        return best

    city_pop = collections.defaultdict(float)
    prov_city = {}
    cap_cand = {}
    for f in pp:
        p = f["properties"]
        x, y = f["geometry"]["coordinates"][0], f["geometry"]["coordinates"][1]
        pid = find_prov(x, y)
        a3 = p["ADM0_A3"]
        popm = (p["POP_MAX"] or 0)
        nm = p.get("NAMEASCII") or p["NAME"]
        if pid >= 0:
            city_pop[pid] += popm
            if pid not in prov_city or popm > prov_city[pid][0]:
                prov_city[pid] = (popm, p.get("NAME_TR") or nm)
        if p.get("ADM0CAP") == 1 and a3 in adm0_group and pid >= 0:
            g = adm0_group[a3]
            if g in country_idx and group_main.get(g) == a3 or (g in country_idx and a3 == g):
                cur = cap_cand.get(g)
                if cur is None or popm > cur[0]:
                    cap_cand[g] = (popm, pid)
    log("başkent", len(cap_cand), "ülke", len(order))

    # ---- etiket noktası (en geniş iç nokta)
    def label_point(pts_list):
        pts = max(pts_list, key=lambda p: abs(ring_area(p)))
        xs = np.array([p[0] for p in pts])
        ys = np.array([p[1] for p in pts])
        x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
        best = (-1, (xs.mean(), ys.mean()))
        N = 14
        ax, ay = xs, ys
        bx, by = np.roll(xs, -1), np.roll(ys, -1)
        dx, dy = bx - ax, by - ay
        L2 = dx * dx + dy * dy + 1e-18
        for i in range(N):
            for j in range(N):
                px = x0 + (x1 - x0) * (i + 0.5) / N
                py = y0 + (y1 - y0) * (j + 0.5) / N
                if not pip(px, py, pts):
                    continue
                t = np.clip(((px - ax) * dx + (py - ay) * dy) / L2, 0, 1)
                d = np.min(np.hypot(px - (ax + t * dx), py - (ay + t * dy)))
                if d > best[0]:
                    best = (d, (px, py))
        return best[1], max(best[0], 0.0)

    # ---- çıktı: izdüşüm
    def proj_ring(ids):
        out = []
        for i in ids:
            x, y = miller(vx[i], vy[i])
            out.extend([round(x, 2), round(y, 2)])
        return out

    out_provs = []
    for pr in provs:
        pid = pr["id"]
        if pid not in prov_poly:
            continue
        rings = [proj_ring(ids) for ids, outer in prov_rings[pid] if outer]
        (lx, ly), rad_in = label_point(prov_poly[pid])
        lxp, lyp = miller(lx, ly)
        x0, y0, x1, y1 = prov_bbox[pid]
        bx0, by1 = miller(x0, y0)
        bx1, by0 = miller(x1, y1)
        mem_area = pr["area"]
        out_provs.append({
            "id": pid, "c": pr["c"],
            "name": (prov_city[pid][1] if pid in prov_city and prov_city[pid][0] >= BIG_CITY else pr["name"]),
            "city": prov_city.get(pid, (0, ""))[1],
            "rings": rings, "lab": [round(lxp, 2), round(lyp, 2), round(rad_in * SCALE, 2)],
            "bb": [round(bx0, 1), round(by0, 1), round(bx1, 1), round(by1, 1)],
            "area": int(mem_area), "cpop": int(city_pop.get(pid, 0)),
            "lm": lm[pid], "nb": sorted(nbrs[pid]), "sea": sorted(seaset[pid]),
        })
    # aynı ülkede aynı adı taşıyan eyaletler: ikincisi yönetim biriminin adını alır
    GEN = {"Eastern": "Doğu", "Western": "Batı", "Central": "Merkez", "Northern": "Kuzey", "Southern": "Güney",
           "Nord": "Kuzey", "Sud": "Güney", "Est": "Doğu", "Ouest": "Batı", "Centre": "Merkez",
           "Nord-Ouest": "Kuzeybatı", "Nord-Est": "Kuzeydoğu", "Sud-Ouest": "Güneybatı", "Sud-Est": "Güneydoğu"}
    seen_names = set()
    for p in out_provs:
        p["name"] = GEN.get(p["name"], p["name"])
    for p in out_provs:
        key = (p["c"], p["name"])
        if key in seen_names:
            alt = next((pr["name"] for pr in provs if pr["id"] == p["id"]), p["name"])
            p["name"] = alt if (p["c"], alt) not in seen_names else p["name"] + " Böl."
        seen_names.add((p["c"], p["name"]))
    # id'leri sıkıştır (düşenler olabilir)
    remap = {p["id"]: i for i, p in enumerate(out_provs)}
    for p in out_provs:
        p["id"] = remap[p["id"]]
        p["nb"] = [remap[x] for x in p["nb"] if x in remap]
        p["sea"] = [remap[x] for x in p["sea"] if x in remap]

    countries = []
    for g in order:
        ci = country_idx[g]
        m = adm0_info[group_main[g]]
        iso = m.get("ISO_A2_EH") or m.get("ISO_A2") or ""
        if iso in ("-99", "", None):
            iso = (m.get("ISO_A2") or "").lower()
        name = NAME_OVERRIDE.get(g) or NAME_OVERRIDE.get(group_main[g]) or m.get("NAME_TR") or m["NAME"]
        pids = [p["id"] for p in out_provs if p["c"] == ci]
        if not pids:
            continue
        cap = cap_cand.get(g)
        cap_pid = remap.get(cap[1], -1) if cap else -1
        if cap_pid < 0 or out_provs[cap_pid]["c"] != ci:
            cap_pid = max(pids, key=lambda i: (out_provs[i]["cpop"], out_provs[i]["area"]))
        countries.append({
            "id": ci, "a3": g, "iso": (iso or "").lower(), "name": name, "name_en": m["NAME"],
            "pop": round(gpop[g] / 1e6, 3), "gdp": int(ggdp[g]), "cont": m.get("CONTINENT", ""),
            "capital": cap_pid, "provs": pids,
        })
    cmap = {c["id"]: i for i, c in enumerate(countries)}
    for c in countries:
        c["id"] = cmap[c["id"]]
    for p in out_provs:
        p["c"] = cmap[p["c"]]

    out_borders = []
    for a, b, line in borders:
        if a not in remap:
            continue
        bb = remap.get(b, -1) if b >= 0 else -1
        pts = []
        for i in line:
            x, y = miller(vx[i], vy[i])
            pts.extend([round(x, 2), round(y, 2)])
        out_borders.append({"a": remap[a], "b": bb, "p": pts})

    # ---- göller
    out_lakes = []
    for f in lk:
        p = f["properties"]
        if (p.get("scalerank") or 99) > 2:
            continue
        for poly in polys(f["geometry"]):
            ring = poly[0]
            pts = [(c[0], c[1]) for c in ring]
            if len(pts) < 4:
                continue
            ar = abs(ring_area(pts))
            if ar < 0.05:
                continue
            xs = np.array([c[0] for c in pts])
            ys = np.array([c[1] for c in pts])
            idx = dp_simplify(xs, ys, 0.03)
            flat = []
            for i in idx:
                x, y = miller(xs[i], ys[i])
                flat.extend([round(x, 2), round(y, 2)])
            if len(flat) >= 8:
                out_lakes.append(flat)
    log("göl", len(out_lakes))

    world = {
        "scale": SCALE,
        "countries": countries,
        "provinces": out_provs,
        "borders": out_borders,
        "lakes": out_lakes,
    }
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w") as fh:
        json.dump(world, fh, separators=(",", ":"), ensure_ascii=False)
    sz = os.path.getsize(OUT)
    log("yazıldı", OUT, round(sz / 1e6, 2), "MB; ülke", len(countries), "eyalet", len(out_provs), "sınır", len(out_borders))
    tops = sorted(countries, key=lambda c: -len(c["provs"]))[:12]
    log("en çok eyalet:", [(c["name"], len(c["provs"])) for c in tops])
    ones = sum(1 for c in countries if len(c["provs"]) == 1)
    log("tek eyaletli ülke:", ones)


if __name__ == "__main__":
    main()
