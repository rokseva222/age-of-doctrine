extends RefCounted
## Deniz bölgeleri: haritanın denizini soyut bir bölge grafiğine böler (donanma filoları bunların üzerinde hareket eder).
## Her bölgenin dünya koordinatı (harita Miller projeksiyonu: x = boylam*5), kıyı eyaletleri ile eşleşmesi, komşuları ve
## boğaz/kanal geçitleri burada. Eyalet verisi ve Province.sea_links değişmez; eşleşme hesaplanıp önbelleğe alınır.

const Loc = preload("res://scripts/loc.gd")
const Chokepoints = preload("res://scripts/chokepoints.gd")

const SCALE := 286.4789          # radyan başına piksel (5 piksel/derece)
const MATCH_MAX := 1.6           # kıyı eyaleti ile bölge arasındaki en büyük normalize uzaklık
const SECOND_RATIO := 1.3        # ikinci bölge: birincinin 1.3 katına kadar yakınsa eşlenir

## [id, "Türkçe ad", "English name", [[lat, lon, rx, ry], ...]]  (ilk anchor merkez/etiket yeri)
const ZONES := [
	["nor_sea", "Norveç Denizi", "Norwegian Sea", [[68.0, 3.0, 12.0, 5.0], [71.0, 28.0, 10.0, 3.0]]],
	["north_sea", "Kuzey Denizi", "North Sea", [[56.5, 3.5, 5.0, 3.5], [54.0, 7.0, 3.0, 1.5], [58.0, 9.0, 3.0, 1.5], [52.5, 3.5, 2.0, 1.5]]],
	["channel", "Manş Denizi", "English Channel", [[49.9, -3.0, 4.0, 1.4]]],
	["baltic", "Baltık Denizi", "Baltic Sea", [[58.0, 19.5, 6.0, 3.5], [60.0, 24.0, 4.0, 1.5], [54.8, 15.0, 5.0, 1.5], [63.0, 21.0, 2.0, 3.0]]],
	["atl_e", "Doğu Atlantik", "Eastern Atlantic", [[40.0, -14.0, 5.0, 8.0], [45.5, -6.0, 4.0, 2.5], [33.5, -8.0, 3.0, 3.0]]],
	["atl_n", "Kuzey Atlantik", "North Atlantic", [[52.0, -30.0, 14.0, 8.0], [62.0, -18.0, 8.0, 4.0], [53.0, -12.0, 4.0, 3.0], [54.0, -5.0, 2.5, 2.5]]],
	["atl_w", "Batı Atlantik", "Western Atlantic", [[38.0, -62.0, 10.0, 10.0], [45.0, -55.0, 8.0, 6.0], [30.0, -76.0, 6.0, 4.0]]],
	["atl_c", "Orta Atlantik", "Central Atlantic", [[15.0, -35.0, 18.0, 10.0], [12.0, -20.0, 5.0, 6.0], [28.0, -18.0, 4.0, 4.0]]],
	["atl_s", "Güney Atlantik", "South Atlantic", [[-22.0, -28.0, 12.0, 10.0], [-35.0, -52.0, 6.0, 6.0], [-15.0, -33.0, 6.0, 6.0]]],
	["atl_se", "Güneydoğu Atlantik", "Southeast Atlantic", [[-8.0, 3.0, 10.0, 8.0], [2.0, 3.0, 8.0, 4.0], [-30.0, 12.0, 8.0, 6.0]]],
	["caribbean", "Karayip Denizi", "Caribbean Sea", [[15.5, -74.0, 10.0, 5.0], [21.0, -77.0, 4.0, 3.0]]],
	["gulf_mex", "Meksika Körfezi", "Gulf of Mexico", [[25.0, -90.0, 7.0, 4.0], [21.0, -86.0, 3.0, 3.0]]],
	["med_w", "Batı Akdeniz", "Western Mediterranean", [[39.5, 4.5, 6.0, 3.0], [37.0, -1.0, 4.0, 2.0], [36.5, 6.0, 5.0, 2.0], [43.0, 8.0, 3.0, 1.5]]],
	["med_c", "Orta Akdeniz", "Central Mediterranean", [[36.0, 17.0, 5.0, 2.5], [39.0, 12.5, 3.0, 2.0], [33.0, 20.0, 5.0, 2.0], [42.5, 16.5, 2.0, 3.0]]],
	["med_e", "Doğu Akdeniz", "Eastern Mediterranean", [[34.0, 29.0, 4.0, 2.5], [36.0, 34.0, 3.0, 1.5], [32.0, 34.0, 2.0, 2.0]]],
	["aegean", "Ege Denizi", "Aegean Sea", [[38.5, 25.0, 2.5, 3.0], [36.0, 27.0, 3.0, 1.5], [40.7, 28.5, 1.0, 0.7]]],
	["black", "Karadeniz", "Black Sea", [[43.3, 34.0, 7.0, 2.5], [42.5, 40.0, 2.0, 2.0], [41.8, 29.0, 2.5, 0.8]]],
	["red_sea", "Kızıldeniz", "Red Sea", [[20.0, 38.5, 2.5, 6.0], [28.0, 34.5, 1.5, 1.5]]],
	["arabian", "Arap Denizi", "Arabian Sea", [[15.0, 62.0, 10.0, 6.0], [24.0, 66.0, 5.0, 3.0], [14.0, 73.0, 3.0, 8.0], [12.0, 48.0, 6.0, 2.5], [24.5, 58.0, 3.0, 2.0]]],
	["persian", "Basra Körfezi", "Persian Gulf", [[27.0, 51.5, 4.0, 2.0]]],
	["bengal", "Bengal Körfezi", "Bay of Bengal", [[13.0, 88.0, 8.0, 6.0], [10.0, 81.0, 3.0, 3.0], [20.0, 88.0, 4.0, 3.0], [14.0, 96.0, 3.0, 6.0]]],
	["ind_w", "Batı Hint Okyanusu", "Western Indian Ocean", [[-15.0, 52.0, 10.0, 10.0], [-5.0, 42.0, 4.0, 8.0], [-26.0, 36.0, 6.0, 8.0], [-34.0, 26.0, 6.0, 3.0]]],
	["ind_e", "Doğu Hint Okyanusu", "Eastern Indian Ocean", [[-18.0, 100.0, 15.0, 10.0], [-2.0, 98.0, 3.0, 6.0], [-28.0, 113.0, 4.0, 8.0], [-35.0, 120.0, 8.0, 3.0]]],
	["indo", "Endonezya Denizleri", "Indonesian Seas", [[-4.0, 118.0, 8.0, 4.0], [-7.0, 110.0, 4.0, 2.0], [0.0, 122.0, 5.0, 4.0], [-10.0, 130.0, 6.0, 3.0]]],
	["scs", "Güney Çin Denizi", "South China Sea", [[12.0, 113.0, 7.0, 8.0], [20.0, 112.0, 4.0, 3.0], [9.0, 102.0, 3.0, 3.0], [3.0, 108.0, 4.0, 3.0], [15.0, 119.0, 2.0, 4.0]]],
	["ecs", "Doğu Çin ve Sarı Deniz", "East China and Yellow Sea", [[30.0, 123.0, 5.0, 5.0], [36.0, 123.0, 3.0, 3.0], [24.5, 119.5, 2.0, 1.5]]],
	["japan_sea", "Japon Denizi", "Sea of Japan", [[40.0, 134.0, 5.0, 5.0], [35.0, 129.0, 2.0, 2.0]]],
	["pac_nw", "Kuzeybatı Pasifik", "Northwest Pacific", [[32.0, 150.0, 14.0, 10.0], [48.0, 155.0, 6.0, 5.0], [18.0, 130.0, 6.0, 6.0], [8.0, 127.0, 4.0, 3.0], [14.0, 145.0, 4.0, 4.0]]],
	["pac_ne", "Kuzeydoğu Pasifik", "Northeast Pacific", [[45.0, -145.0, 15.0, 12.0], [57.0, -135.0, 6.0, 4.0], [36.0, -124.0, 4.0, 5.0], [53.0, -170.0, 10.0, 3.0], [20.0, -156.0, 4.0, 4.0]]],
	["pac_e", "Doğu Pasifik", "Eastern Pacific", [[8.0, -100.0, 12.0, 8.0], [20.0, -108.0, 5.0, 5.0], [-2.0, -82.0, 3.0, 4.0], [12.0, -88.0, 4.0, 3.0], [6.0, -80.0, 3.0, 3.0]]],
	["pac_se", "Güneydoğu Pasifik", "Southeast Pacific", [[-30.0, -90.0, 12.0, 10.0], [-12.0, -79.0, 3.0, 5.0], [-42.0, -76.0, 4.0, 6.0], [-20.0, -75.0, 4.0, 6.0]]],
	["pac_sw", "Güneybatı Pasifik", "Southwest Pacific", [[-20.0, 165.0, 12.0, 10.0], [-28.0, 154.0, 4.0, 6.0], [-6.0, 152.0, 6.0, 4.0], [-41.0, 174.0, 3.0, 4.0]]],
	["arctic", "Kuzey Buz Denizi", "Arctic Ocean", [[77.0, 70.0, 30.0, 3.5], [77.0, -100.0, 25.0, 4.0], [73.0, 160.0, 20.0, 2.5], [72.0, -150.0, 12.0, 2.5], [79.0, -10.0, 12.0, 2.5]]],
	["caspian", "Hazar Denizi", "Caspian Sea", [[43.5, 50.0, 2.6, 3.5], [39.5, 51.5, 2.4, 2.5]]],
]

## Komşuluk: [a, b, geçit ("" = açık)]
const EDGES := [
	["nor_sea", "north_sea", ""], ["nor_sea", "atl_n", ""],
	["north_sea", "atl_n", ""], ["north_sea", "channel", "channel"], ["north_sea", "baltic", "danish"],
	["channel", "atl_e", ""],
	["atl_e", "atl_n", ""], ["atl_e", "atl_c", ""], ["atl_e", "med_w", "gibraltar"],
	["atl_n", "atl_w", ""], ["atl_n", "atl_c", ""],
	["atl_w", "atl_c", ""], ["atl_w", "caribbean", ""], ["atl_w", "gulf_mex", ""],
	["atl_c", "atl_s", ""], ["atl_c", "atl_se", ""], ["atl_c", "caribbean", ""],
	["atl_s", "atl_se", ""], ["atl_s", "ind_w", ""], ["atl_s", "pac_se", ""], ["atl_se", "ind_w", ""],
	["caribbean", "gulf_mex", ""], ["caribbean", "pac_e", "panama"],
	["med_w", "med_c", ""], ["med_c", "med_e", ""], ["med_c", "aegean", ""], ["med_e", "aegean", ""],
	["med_e", "red_sea", "suez"], ["aegean", "black", "bosphorus"],
	["red_sea", "arabian", "babelmandeb"], ["arabian", "persian", "hormuz"], ["arabian", "ind_w", ""], ["arabian", "bengal", ""],
	["ind_w", "ind_e", ""], ["bengal", "ind_e", ""], ["bengal", "scs", "malacca"],
	["ind_e", "indo", ""], ["ind_e", "pac_sw", ""],
	["indo", "scs", ""], ["indo", "pac_sw", ""], ["indo", "pac_nw", ""],
	["scs", "ecs", ""], ["scs", "pac_nw", ""],
	["ecs", "japan_sea", ""], ["ecs", "pac_nw", ""], ["japan_sea", "pac_nw", ""],
	["pac_nw", "pac_ne", ""], ["pac_nw", "pac_sw", ""],
	["pac_ne", "pac_e", ""], ["pac_e", "pac_se", ""], ["pac_se", "pac_sw", ""],
	["arctic", "nor_sea", ""], ["arctic", "atl_n", ""], ["arctic", "pac_ne", ""], ["arctic", "pac_nw", ""],
]
## Kapalı göl bölgeleri: grafikte kenarı yok; yalnız kıyı devletlerinin yerel filoları (Hazar filosu)
const LAKES := ["caspian"]

static var _built := false
static var _zone: Dictionary = {}       # id -> {id, tr, en, pos, anchors, adj: Array, gate: {komşu: geçit}}
static var _ids: Array = []
static var _key := ""
static var _last_gs := 0
static var _last_n := 0
static var _coast: Dictionary = {}      # pid -> [bölge id] (en yakın 1-2)
static var _zone_provs: Dictionary = {} # bölge id -> [pid]
static var _dist_cache: Dictionary = {} # "a|b" -> serbest yol uzunluğu (geçit yok sayılır)


# ------------------------------------------------------------------ koordinat

## Enlem/boylam -> harita dünya koordinatı (Miller)
static func ll(lat: float, lon: float) -> Vector2:
	var phi := deg_to_rad(lat)
	var y := 1.25 * log(tan(PI * 0.25 + 0.4 * phi))
	return Vector2(lon * 5.0, -y * SCALE)


static func _build() -> void:
	if _built:
		return
	_built = true
	_zone = {}
	_ids = []
	for z in ZONES:
		var id: String = z[0]
		var anchors: Array = []
		for a in z[3]:
			var ctr: Vector2 = ll(float(a[0]), float(a[1]))
			var ry: float = absf(ll(float(a[0]) + float(a[3]), float(a[1])).y - ctr.y)     # enlem yarıçapı Miller gerilmesine göre
			anchors.append({"c": ctr, "rx": float(a[2]) * 5.0, "ry": ry})
		_zone[id] = {"id": id, "tr": z[1], "en": z[2], "pos": anchors[0].c, "anchors": anchors, "adj": [], "gate": {}}
		_ids.append(id)
	for e in EDGES:
		_zone[e[0]].adj.append(e[1])
		_zone[e[1]].adj.append(e[0])
		if e[2] != "":
			_zone[e[0]].gate[e[1]] = e[2]
			_zone[e[1]].gate[e[0]] = e[2]


static func ids() -> Array:
	_build()
	return _ids


static func is_lake(id: String) -> bool:
	return LAKES.has(id)


static func has(id: String) -> bool:
	_build()
	return _zone.has(id)


static func count() -> int:
	_build()
	return _ids.size()


static func pos(id: String) -> Vector2:
	_build()
	return _zone[id].pos if _zone.has(id) else Vector2.ZERO


## Bölge adı (Türkçe kaynak metin; arayüzde çeviri kancası çevirir)
static func name_tr(id: String) -> String:
	_build()
	return String(_zone[id].tr) if _zone.has(id) else id


static func name_en(id: String) -> String:
	_build()
	return String(_zone[id].en) if _zone.has(id) else id


## Çizim için: seçili dile göre ad
static func name_of(id: String) -> String:
	_build()
	if not _zone.has(id):
		return id
	return Loc.t(String(_zone[id].tr)) if Loc.lang != "tr" else String(_zone[id].tr)


static func neighbors(id: String) -> Array:
	_build()
	return _zone[id].adj if _zone.has(id) else []


## Kenar üzerindeki geçit kimliği ("" = açık deniz)
static func gate_of(a: String, b: String) -> String:
	_build()
	if not _zone.has(a):
		return ""
	return String(_zone[a].gate.get(b, ""))


## Bir ülke bu geçitten geçebilir mi? (kontrolcü kendisi/müttefik: evet; savaştaki kontrolcü: hayır; kapalı modlar)
static func gate_ok(gs, cid: int, gate: String) -> bool:
	if gate == "":
		return true
	Chokepoints.ensure(gs)
	var ctrl: int = Chokepoints.controller(gs, gate)
	if ctrl < 0 or ctrl == cid or gs.is_allied(ctrl, cid):
		return true
	if gs.at_war(ctrl, cid):
		return false
	var mode: String = Chokepoints.mode_of(gs, gate)
	if mode == "all":
		return false
	if mode == "enemy":
		return not (gs.countries[ctrl].embargo.has(cid) or gs.countries[cid].embargo.has(ctrl))
	return true


static func edge_ok(gs, cid: int, a: String, b: String) -> bool:
	return gate_ok(gs, cid, gate_of(a, b))


## En kısa izinli yol (başlangıç hariç, hedef dahil); yol yoksa [] (aynı bölge: [])
static func path(gs, cid: int, from: String, to: String) -> Array:
	_build()
	if from == to or not _zone.has(from) or not _zone.has(to):
		return []
	var prev: Dictionary = {from: ""}
	var q: Array = [from]
	var qi := 0
	while qi < q.size():
		var cur: String = q[qi]
		qi += 1
		if cur == to:
			break
		for nb in _zone[cur].adj:
			if prev.has(nb):
				continue
			if not edge_ok(gs, cid, cur, nb):
				continue
			prev[nb] = cur
			q.append(nb)
	if not prev.has(to):
		return []
	var out: Array = []
	var c: String = to
	while c != from:
		out.push_front(c)
		c = prev[c]
	return out


## Geçitler yok sayılarak sıçrama uzaklığı (yapay zekâ ve değerlendirme için; önbellekli)
static func hops(a: String, b: String) -> int:
	_build()
	if a == b:
		return 0
	var k := a + "|" + b
	if _dist_cache.has(k):
		return _dist_cache[k]
	var dist: Dictionary = {a: 0}
	var q: Array = [a]
	var qi := 0
	while qi < q.size():
		var cur: String = q[qi]
		qi += 1
		for nb in _zone[cur].adj:
			if not dist.has(nb):
				dist[nb] = dist[cur] + 1
				q.append(nb)
	for z in dist:
		_dist_cache[a + "|" + z] = dist[z]
	return int(dist.get(b, 99))


# ------------------------------------------------------------------ kıyı eşleşmesi

static func _ellipse_d(p: Vector2, a: Dictionary) -> float:
	var dx: float = (p.x - a.c.x) / a.rx
	var dy: float = (p.y - a.c.y) / a.ry
	return sqrt(dx * dx + dy * dy)


## Eyalet kıyı eşleşmesini (gerekirse) kurar; anahtar: eyalet sayısı + kıyı eyaleti sayısı
static func ensure_coast(gs) -> void:
	_build()
	var n: int = gs.provinces.size()
	if gs.get_instance_id() == _last_gs and n == _last_n and not _coast.is_empty():
		return
	_last_gs = gs.get_instance_id()
	_last_n = n
	var coastal := 0
	var sig := 0.0
	for p in gs.provinces:
		if p.coastal:
			coastal += 1
			sig += p.label_pos.x * 0.37 + p.label_pos.y * 0.11
	var key := "%d:%d:%d" % [n, coastal, int(sig)]
	if key == _key and not _coast.is_empty():
		return
	_key = key
	_coast = {}
	_zone_provs = {}
	for id in _ids:
		_zone_provs[id] = []
	# anchor elips sınır kutuları (budama): MATCH_MAX ile genişletilmiş
	var boxes: Array = []     # [[id, anchor, Rect2]]
	for id in _ids:
		for a in _zone[id].anchors:
			var ex: float = a.rx * MATCH_MAX
			var ey: float = a.ry * MATCH_MAX
			boxes.append([id, a, Rect2(a.c - Vector2(ex, ey), Vector2(ex, ey) * 2.0)])
	for p in gs.provinces:
		if not p.coastal:
			continue
		var best: Dictionary = {}       # bölge id -> en küçük normalize uzaklık
		var pts := PackedVector2Array([p.label_pos])
		for ring in p.rings:
			var stp: int = maxi(1, ring.size() / 48)
			var i := 0
			while i < ring.size():
				pts.append(ring[i])
				i += stp
		for bx in boxes:
			if not p.bbox.grow(2.0).intersects(bx[2]):
				continue
			var a: Dictionary = bx[1]
			var bd: float = float(best.get(bx[0], 1e9))
			for v in pts:
				var d: float = _ellipse_d(v, a)
				if d < bd:
					bd = d
			best[bx[0]] = bd
		var cand: Array = []
		for id in best:
			if float(best[id]) <= MATCH_MAX:
				cand.append([best[id], id])
		if cand.is_empty():
			continue
		cand.sort_custom(func(x, y): return x[0] < y[0])
		var zs: Array = [cand[0][1]]
		if cand.size() > 1 and cand[1][0] <= cand[0][0] * SECOND_RATIO + 0.1:
			zs.append(cand[1][1])
		_coast[p.id] = zs
		for z in zs:
			_zone_provs[z].append(p.id)


## Kıyı eyaletinin komşu deniz bölgeleri ([] = limanı yok / iç deniz)
static func coast_zones(gs, pid: int) -> Array:
	ensure_coast(gs)
	return _coast.get(pid, [])


## Bir bölgeye bitişik kıyı eyaletleri
static func provs_of(gs, zid: String) -> Array:
	ensure_coast(gs)
	return _zone_provs.get(zid, [])


## Ülkenin elindeki (kontrol ettiği) kıyı eyaletlerinin bölgeleri: {bölge id: eyalet sayısı}
static func ports_of(gs, cid: int, allied: bool = false) -> Dictionary:
	ensure_coast(gs)
	var out: Dictionary = {}
	for pid in gs.countries[cid].held_ids:
		var zs = _coast.get(pid)
		if zs == null:
			continue
		for z in zs:
			out[z] = int(out.get(z, 0)) + 1
	if allied:
		for al in gs.countries[cid].allies:
			if al >= 0 and al < gs.countries.size() and gs.countries[al].alive:
				for pid2 in gs.countries[al].held_ids:
					var zs2 = _coast.get(pid2)
					if zs2 != null:
						for z2 in zs2:
							out[z2] = int(out.get(z2, 0)) + 1
	return out


## Ana liman: başkente en yakın, bölgesi olan kıyı eyaleti -> [pid, bölge id]; yoksa [-1, ""]
static func home_port(gs, cid: int) -> Array:
	ensure_coast(gs)
	var c = gs.countries[cid]
	var ref := Vector2.ZERO
	if c.capital >= 0:
		ref = gs.provinces[c.capital].label_pos
	elif not c.owned_ids.is_empty():
		ref = gs.provinces[c.owned_ids[0]].label_pos
	var best := -1
	var bd := 1e18
	for pid in c.owned_ids:
		var p = gs.provinces[pid]
		if p.controller != cid or not _coast.has(pid) or is_lake(String(_coast[pid][0])):
			continue
		var d: float = p.label_pos.distance_squared_to(ref)
		if d < bd:
			bd = d
			best = pid
	if best < 0:
		return [-1, ""]
	return [best, String(_coast[best][0])]


## Bölgenin merkezi karada mı? (doğrulama için): bir eyalet poligonunun içindeyse true
static func center_on_land(gs, wd, id: String) -> bool:
	return wd.province_at(gs, pos(id), 0.0) >= 0


## En yakın bölge (dokunma): max_d dünya birimi içinde; yoksa ""
static func nearest(wp: Vector2, max_d: float = 80.0) -> String:
	_build()
	var best := ""
	var bd := max_d
	for id in _ids:
		for a in _zone[id].anchors:
			var d: float = (wp - a.c).length() / maxf(minf(a.rx, a.ry), 1.0)
			# normalize elips içinde değilse mutlak uzaklık da sınır
			var dd: float = minf(d * 50.0, (wp - a.c).length())
			if dd < bd:
				bd = dd
				best = id
	return best


## Dokunulan nokta hangi bölgenin elipsinde (ya da yakınında)? Anchor elipsine göre normalize uzaklığı en küçük olan.
static func zone_at(wp: Vector2, max_norm: float = 1.0) -> String:
	_build()
	var best := ""
	var bd := max_norm
	for id in _ids:
		for a in _zone[id].anchors:
			var d: float = _ellipse_d(wp, a)
			if d < bd:
				bd = d
				best = id
	return best
