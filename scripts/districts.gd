extends RefCounted
## İLÇE KATMANI (Bağımsızlık Yolu): isyan önce yerel başlar. Hareketin merkez üssü olan şehirlerin ilçeleri
## haritada görünür; her ilçe merkezde ya da hareketin elindedir. Bir şehrin ilçelerinin nüfus ağırlıklı
## payı "yerel kontrol"dür. Nüfusu yoğun şehirde güvenlik güçleri yoğundur, ilçe almak zorlaşır.
## Durum gs.indep.dist içinde saklanır (kayda girer); hücre çokgenleri kayıtta yok, açılışta yeniden üretilir.
## İlçe verisi: gs.indep.dist[str(pid)] = [{id, w, x, y, st (0 merkez / 1 hareket), g (tutunma), sec (güvenlik), cd}]

const Loc = preload("res://scripts/loc.gd")

const FLIP_UP := 0.6        # bu pay hareketin eline geçince şehir resmen hareketin olur
const FLIP_DOWN := 0.05     # bu payın altında 4 hafta kalırsa şehir merkeze geri döner
const DIRS := ["Doğu", "Güneydoğu", "Güney", "Güneybatı", "Batı", "Kuzeybatı", "Kuzey", "Kuzeydoğu"]
const ROMAN := ["", " II", " III", " IV", " V"]

static var _data: Dictionary = {}
static var _data_loaded := false


## data/districts.json: eyalet id -> [[ad, x, y, ağırlık]] (tools/build_districts.py ile gerçek ilçe/yer verisinden üretilir)
static func _real(pid: int) -> Array:
	if not _data_loaded:
		_data_loaded = true
		var txt := FileAccess.get_file_as_string("res://data/districts.json")
		var parsed = JSON.parse_string(txt)
		if typeof(parsed) == TYPE_DICTIONARY:
			_data = parsed
	return _data.get(str(pid), [])


static func _tr() -> bool:
	return Loc.lang == "tr"


static func _cache(gs) -> Dictionary:
	if not gs.has_meta("dcells"):
		gs.set_meta("dcells", {})
	return gs.get_meta("dcells")


static func active(gs) -> bool:
	return gs.indep is Dictionary and gs.indep.get("dist") is Dictionary and not (gs.indep.dist as Dictionary).is_empty()


static func pids(gs) -> Array:
	var out: Array = []
	if not active(gs):
		return out
	for k in gs.indep.dist.keys():
		out.append(int(k))
	out.sort()
	return out


# ------------------------------------------------------------------ geometri

static func main_ring(p) -> PackedVector2Array:
	var best := PackedVector2Array()
	var ba := -1.0
	for r in p.rings:
		var pts: PackedVector2Array = r
		if pts.size() < 3:
			continue
		var bb := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			bb = bb.expand(q)
		var a: float = bb.size.x * bb.size.y
		if a > ba:
			ba = a
			best = pts
	return best


static func _inside(ring: PackedVector2Array, pt: Vector2, center: Vector2) -> Vector2:
	var q := pt
	for _i in 10:
		if Geometry2D.is_point_in_polygon(q, ring):
			return q
		q = center.lerp(q, 0.7)
	return center


static func _half(a: Vector2, b: Vector2) -> PackedVector2Array:
	var m: Vector2 = (a + b) * 0.5
	var d: Vector2 = (b - a).normalized()
	var pp := Vector2(-d.y, d.x)
	var L := 4000.0
	return PackedVector2Array([m + pp * L, m - pp * L, m - pp * L - d * L, m + pp * L - d * L])


## Her ilçenin hücresi (Voronoi ∩ eyalet çokgeni): ilçe başına çokgen listesi (dünya koordinatı).
static func cells(gs, pid: int) -> Array:
	var cache: Dictionary = _cache(gs)
	if cache.has(pid):
		return cache[pid]
	var out: Array = []
	var key := str(pid)
	if not active(gs) or not (gs.indep.dist as Dictionary).has(key):
		return out
	var d: Array = gs.indep.dist[key]
	var ring: PackedVector2Array = main_ring(gs.provinces[pid])
	var sites: Array = []
	for e in d:
		sites.append(Vector2(float(e.x), float(e.y)))
	for i in sites.size():
		var polys: Array = [ring]
		for j in sites.size():
			if j == i:
				continue
			var hp := _half(sites[i], sites[j])
			var nxt: Array = []
			for pl in polys:
				for r in Geometry2D.intersect_polygons(pl, hp):
					nxt.append(r)
			polys = nxt
			if polys.is_empty():
				break
		# hücreyi sitenin çevresindeki bir daireyle sınırla: kent kümesi derli toplu görünür, kırsal alan eyalet renginde kalır
		var nn := 1e9
		for j2 in sites.size():
			if j2 != i:
				nn = minf(nn, (sites[i] as Vector2).distance_to(sites[j2]))
		var rad: float = clampf(nn * 1.9, 0.25, 40.0)
		var circ := PackedVector2Array()
		for k in 20:
			circ.append(sites[i] + Vector2(cos(TAU * float(k) / 20.0), sin(TAU * float(k) / 20.0)) * rad)
		var clipped: Array = []
		for pl2 in polys:
			for r2 in Geometry2D.intersect_polygons(pl2, circ):
				clipped.append(r2)
		out.append(clipped)
	cache[pid] = out
	return out


# ------------------------------------------------------------------ kurulum

static func _count(pop_m: float) -> int:
	return clampi(3 + int(round(sqrt(maxf(pop_m, 0.1)) * 1.6)), 4, 9)


## Seçilen şehirler için ilçe katmanı kurar. host_cap: sahibinin başkenti (güvenlik daha yoğun)
static func build(gs, city_pids: Array, rng: RandomNumberGenerator) -> void:
	var dist := {}
	for pid in city_pids:
		var p = gs.provinces[int(pid)]
		var ring: PackedVector2Array = main_ring(p)
		if ring.size() < 3:
			continue
		var bb := Rect2(ring[0], Vector2.ZERO)
		for q in ring:
			bb = bb.expand(q)
		var C: Vector2 = _inside(ring, p.label_pos, bb.get_center())
		var H: Vector2 = bb.size * 0.5
		var list: Array = []
		var real: Array = []
		for e in _real(int(pid)):
			var pt0 := Vector2(float(e[1]), float(e[2]))
			if Geometry2D.is_point_in_polygon(pt0, ring):
				real.append([String(e[0]), pt0, float(e[3])])
		if real.size() >= 4:
			# şematik yayılım: kent çekirdeğindeki ilçeler gerçekte birbirine çok yakındır; merkezden uzaklık kök-benzeri bir
			# eğriyle açılır (yön korunur), böylece hücreler dokunmatik ekranda okunur olur
			var R: float = maxf(H.x, H.y) * 0.8
			var cc := Vector2.ZERO
			var cw := 0.0
			for e in real:
				cc += (e[1] as Vector2) * float(e[2])
				cw += float(e[2])
			cc /= maxf(cw, 0.001)
			for e in real:
				var off: Vector2 = (e[1] as Vector2) - cc
				var dd: float = off.length()
				var pt3: Vector2 = cc + (off / dd) * R * pow(dd / R, 0.4) if dd > 0.0001 else cc
				pt3 = _inside(ring, pt3, cc)
				list.append({"id": "r:%s" % String(e[0]), "w": float(e[2]), "x": pt3.x, "y": pt3.y})
		else:
			var k: int = _count(p.pop)
			var a0: float = rng.randf() * TAU
			for i in k:
				var r: float = 0.0 if i == 0 else 0.3 + 0.55 * sqrt(float(i) / float(k))
				var ang: float = a0 + float(i) * 2.39996
				var pt: Vector2 = C + Vector2(cos(ang) * H.x * r, sin(ang) * H.y * r)
				pt = _inside(ring, pt, C)
				var dir_i: int = posmod(int(round(rad_to_deg(atan2(pt.y - C.y, pt.x - C.x)) / 45.0)), 8)
				var w: float = 3.2 if i == 0 else maxf(0.4, 1.5 - r + rng.randf() * 0.4)
				list.append({"id": "g:c" if i == 0 else "g:%d" % dir_i, "w": w, "x": pt.x, "y": pt.y})
		# aynı yön adları: İkinci, Üçüncü ...
		var seen := {}
		for e in list:
			var id: String = String(e.id)
			if id.begins_with("g:") and id != "g:c":
				var n: int = int(seen.get(id, 0))
				seen[id] = n + 1
				if n > 0:
					e.id = "%s:%d" % [id, n]
		var tot := 0.0
		var wmax := 0.0
		for e in list:
			tot += float(e.w)
			wmax = maxf(wmax, float(e.w))
		for e in list:
			e.w = float(e.w) / tot
			var sec: float = 24.0 + 56.0 * (float(e.w) * tot / wmax) + (6.0 if p.is_capital else 0.0) + minf(p.pop, 20.0) * 0.4
			e["sec"] = int(clampf(sec, 20.0, 96.0))
			e["st"] = 0
			e["g"] = 0
			e["cd"] = 0
		# başlangıç payı: nüfus yoğunsa daha az; en zayıf korunan ilçelerden başlar
		var share: float = clampf(0.5 - 0.02 * p.pop, 0.25, 0.45)
		var order: Array = range(list.size())
		order.sort_custom(func(a, b): return int(list[a].sec) < int(list[b].sec))
		var acc := 0.0
		for i in order:
			if acc >= share:
				break
			list[i].st = 1
			list[i].g = 40
			acc += float(list[i].w)
		dist[str(int(pid))] = list
	gs.indep["dist"] = dist
	gs.indep["dz"] = {}
	gs.set_meta("dcells", {})


# ------------------------------------------------------------------ sorgular

static func name_of(gs, pid: int, i: int) -> String:
	var e: Dictionary = gs.indep.dist[str(pid)][i]
	var id: String = String(e.id)
	if id.begins_with("r:"):
		return id.substr(2)
	var city: String = gs.provinces[pid].city if gs.provinces[pid].city != "" else gs.provinces[pid].name
	if id == "g:c":
		return "%s %s" % [city, Loc.t("Merkez")]
	var parts: PackedStringArray = id.split(":")
	var nm: String = Loc.t(DIRS[int(parts[1])])
	if parts.size() > 2:
		nm += ROMAN[mini(int(parts[2]), ROMAN.size() - 1)]
	return "%s %s" % [city, nm]


static func control(gs, pid: int) -> float:
	var key := str(pid)
	if not active(gs) or not (gs.indep.dist as Dictionary).has(key):
		return 0.0
	var c := 0.0
	for e in gs.indep.dist[key]:
		if int(e.st) == 1:
			c += float(e.w)
	return c


## Tüm şehirlerin nüfusla ağırlıklı yerel kontrolü
static func total_control(gs) -> float:
	var num := 0.0
	var den := 0.0
	for pid in pids(gs):
		var w: float = maxf(gs.provinces[pid].pop, 0.1)
		num += control(gs, pid) * w
		den += w
	return num / den if den > 0.0 else 0.0


static func best_control(gs) -> float:
	var b := 0.0
	for pid in pids(gs):
		b = maxf(b, control(gs, pid))
	return b


## Evre 2'ye geçiş için: en az bir şehir FLIP_UP payını geçmeli (ilçe katmanı yoksa serbest)
static func local_ok(gs) -> bool:
	return not active(gs) or best_control(gs) >= FLIP_UP


static func sec_label(sec: int) -> String:
	if sec >= 75:
		return Loc.t("Çok yoğun")
	if sec >= 55:
		return Loc.t("Yoğun")
	if sec >= 35:
		return Loc.t("Orta")
	return Loc.t("Zayıf")


static func _inc(gs) -> float:
	return maxf(gs.countries[gs.player].income, 1.0)


static func _presence(gs, pid: int) -> bool:
	var a = gs.armies.get(pid)
	return a != null and a.owner == gs.player and int(a.size) >= 1500


static func _support(gs) -> float:
	return float(gs.indep.get("support", 40.0))


static func chance(gs, pid: int, i: int) -> float:
	var e: Dictionary = gs.indep.dist[str(pid)][i]
	var p: float = 0.38 + 0.45 * _support(gs) / 100.0 + (0.25 if _presence(gs, pid) else 0.0) - 0.50 * float(e.sec) / 100.0
	return clampf(p, 0.06, 0.88)


static func cost(gs, pid: int, i: int) -> float:
	var e: Dictionary = gs.indep.dist[str(pid)][i]
	var wk: float = (0.4 + 2.0 * float(e.w)) if int(e.st) == 0 else (0.25 + 1.0 * float(e.w))
	return wk * _inc(gs)


## Arayüz satırı için ilçe bilgisi
static func info(gs, pid: int, i: int) -> Dictionary:
	var e: Dictionary = gs.indep.dist[str(pid)][i]
	var why := ""
	var cd: int = int(e.cd) - gs.turn
	if cd > 0:
		why = Loc.t("Bekleme: %d hafta" % cd)
	elif cost(gs, pid, i) > gs.countries[gs.player].gold:
		why = Loc.t("Kasa yetersiz")
	elif int(e.st) == 1 and int(e.g) >= 100:
		why = Loc.t("Tam korunuyor")
	return {"name": name_of(gs, pid, i), "w": float(e.w), "pop_m": float(e.w) * gs.provinces[pid].pop, "st": int(e.st), "g": int(e.g), "sec": int(e.sec),
		"cost": cost(gs, pid, i), "chance": chance(gs, pid, i) if int(e.st) == 0 else -1.0, "why": why}


# ------------------------------------------------------------------ eylem

static func act(gs, pid: int, i: int) -> String:
	var inf: Dictionary = info(gs, pid, i)
	if String(inf.why) != "":
		return String(inf.why)
	var e: Dictionary = gs.indep.dist[str(pid)][i]
	var f = gs.countries[gs.player]
	f.gold -= float(inf.cost)
	e.cd = gs.turn + 2
	var nm: String = String(inf.name)
	var s: Dictionary = gs.indep
	if int(e.st) == 1:
		e.g = mini(100, int(e.g) + 30)
		return Loc.t("%s ilçesinde savunma güçlendirildi." % nm)
	if gs.rng.randf() < float(inf.chance):
		e.st = 1
		e.g = 35
		e.sec = maxi(15, int(e.sec) - 10)
		s.support = clampf(float(s.support) + 2.0, 0.0, 100.0)
		_check_flip(gs, pid)
		gs.state_changed.emit()
		return Loc.t("%s ilçesi hareketin eline geçti." % nm)
	e.sec = mini(100, int(e.sec) + 6)
	s.support = clampf(float(s.support) - 2.0, 0.0, 100.0)
	if int(s.phase) == 0:
		s.secrecy = clampf(float(s.secrecy) - 6.0, 0.0, 100.0)
	return Loc.t("%s ilçesinde girişim başarısız oldu." % nm)


# ------------------------------------------------------------------ haftalık akış

static func tick(gs) -> void:
	if not active(gs):
		return
	var s: Dictionary = gs.indep
	var sup: float = _support(gs)
	var ph: int = int(s.phase)
	for pid in pids(gs):
		var list: Array = s.dist[str(pid)]
		var pres: bool = _presence(gs, pid)
		for i in list.size():
			var e: Dictionary = list[i]
			if int(e.st) == 1:
				e.g = maxi(0, int(e.g) - 1)
				var p: float = 0.035 * (1.0 + float(e.sec) / 100.0) * (1.0 - sup / 160.0) * (1.0 - float(e.g) / 110.0)
				if pres:
					p *= 0.5
				if ph == 0 and String(s.get("method", "uprising")) != "uprising":
					p *= 0.5
				if gs.rng.randf() < p:
					e.st = 0
					e.g = 0
					e.sec = mini(100, int(e.sec) + 8)
					gs.post_news(Loc.t("%s ilçesi merkez güçlerinin eline geçti." % name_of(gs, pid, i)), pid, "war_player")
			elif sup >= 55.0 and int(e.sec) < 50 and gs.rng.randf() < 0.025 * (sup - 50.0) / 50.0:
				e.st = 1
				e.g = 25
				gs.post_news(Loc.t("%s ilçesinde halk ayaklandı." % name_of(gs, pid, i)), pid, "war_player")
		_check_flip(gs, pid)


## Şehir payı eşiği geçerse sahiplik değişir (host başkenti dahil)
static func _check_flip(gs, pid: int) -> void:
	var s: Dictionary = gs.indep
	var p = gs.provinces[pid]
	var me: int = gs.player
	var host: int = int(s.get("host", -1))
	var ctl: float = control(gs, pid)
	var dz: Dictionary = s.get("dz", {})
	var key := str(pid)
	if p.owner != me and p.owner == host and ctl >= FLIP_UP:
		_flip(gs, pid, me)
		gs.post_news(Loc.t("%s hareketin denetimine girdi." % p.title()), pid, "war_player")
		dz[key] = 0
	elif p.owner == me and p.controller != me and ctl >= FLIP_UP:
		# işgal altındaki şehirde halk yeniden hakim: şehir kurtarılır
		p.controller = me
		p.siege = 0
		p.siege_by = -1
		var occ = gs.armies.get(pid)
		if occ != null and occ.owner != me:
			gs.armies.erase(pid)
		gs.province_changed.emit(pid)
		gs.refresh_stats()
		gs.post_news(Loc.t("%s halkın direnişiyle kurtarıldı." % p.title()), pid, "war_player")
		dz[key] = 0
	elif p.owner == me and ctl <= FLIP_DOWN:
		dz[key] = int(dz.get(key, 0)) + 1
		if int(dz[key]) >= 4:
			_flip(gs, pid, host)
			gs.post_news(Loc.t("%s yeniden merkezin eline geçti." % p.title()), pid, "war_player")
			dz[key] = 0
	else:
		dz[key] = 0
	s["dz"] = dz


static func _flip(gs, pid: int, to: int) -> void:
	var p = gs.provinces[pid]
	var old: int = p.owner
	p.owner = to
	p.controller = to
	p.siege = 0
	p.siege_by = -1
	p.acquired = gs.turn
	if p.is_capital and old >= 0 and to != old:
		p.is_capital = false
	var a = gs.armies.get(pid)
	if a != null and a.owner != to:
		gs.armies.erase(pid)
	gs.province_changed.emit(pid)
	gs.refresh_stats()
	if old >= 0:
		gs._fix_capital(old)
	gs._fix_capital(to)
	gs._check_elimination()


## Yeraltı direnişi: şehir işgal edilse de ilçelerde örgüt varken hareket yok sayılmaz
static func holdout(gs, fid: int) -> bool:
	if not active(gs) or fid != gs.player or int(gs.indep.phase) > 2:
		return false
	return best_control(gs) > FLIP_DOWN
