extends RefCounted
## Deniz filoları: haritada denizde görünen, hareket eden ve savaşan donanma birimleri (Seas bölgeleri üzerinde).
## Durum gs.fleets (id -> Model.Fleet). Filo gücü ülkenin envanterine bağlıdır:
##   denizaltı filoları toplamı  = naval_pow - 0.8*uçak gemisi  (c.inv denizaltı kalemleri)
##   uçak gemisi filoları toplamı = c.carriers
##   muharebe (yüzey) filosu      = envantersiz; türetilen hedefe doğru ekonomiden yavaş yenilenir
## sync() her tur bunları eşitler; muharebe kayıpları reflect() ile envantere/c.carriers'a yansır.
## Rastgelelik gs.rng'ye dokunmaz (seed + tur ile ayrı üretilir): mevcut oyun dizisi bozulmaz.

const Model = preload("res://scripts/model.gd")
const Seas = preload("res://scripts/seas.gd")
const Macro = preload("res://scripts/macro.gd")
const Arsenal = preload("res://scripts/arsenal.gd")
const Settings = preload("res://scripts/settings.gd")
const Chokepoints = preload("res://scripts/chokepoints.gd")

const KINDS := ["surface", "sub", "carrier", "transport"]
const KIND_TR := {"surface": "Muharebe filosu", "sub": "Denizaltı filosu", "carrier": "Uçak gemisi grubu", "transport": "Nakliye filosu"}
const KIND_EN := {"surface": "Battle fleet", "sub": "Submarine fleet", "carrier": "Carrier group", "transport": "Transport fleet"}
const KIND_CP := {"surface": 1.0, "sub": 1.0, "carrier": 8.0, "transport": 0.0}   # saldırı gücü çarpanı (boyut başına)
const SPEED := {"surface": 2, "sub": 1, "carrier": 2, "transport": 2}              # haftada bölge
const LETHAL := 0.2            # muharebe kayıp çarpanı (tur başına)
const MIN_SIZE := 0.3          # altına düşen filo kaldırılır
const MAX_FLEETS := 6          # ülke başına yumuşak sınır
const BOMBARD_CD := 3
const TORPEDO_CD := 2
const SURFACE_RATIO := 0.6     # türetilen muharebe filosu = 0.6*denizaltı gücü + 2*uçak gemisi
const SUB_REVEAL := 2          # denizaltı ateş ettikten sonra açıkta kalma süresi (tur)

# saldıran tür -> hedef tür çarpanı (denizaltı yüzeye +, yüzey denizaltıya zayıf; uçak gemisi tek başına zayıf)
const MATRIX := {
	"sub": {"surface": 1.35, "carrier": 1.2, "sub": 0.8, "transport": 1.6},
	"surface": {"surface": 1.0, "carrier": 1.1, "sub": 0.5, "transport": 1.6},
	"carrier": {"surface": 0.9, "carrier": 0.9, "sub": 0.6, "transport": 1.6},
	"transport": {"surface": 0.0, "carrier": 0.0, "sub": 0.0, "transport": 0.0},
}
const ASW_BONUS := 0.4         # yüzey filosunun aynı bölgede kendi uçak gemisi grubuyla denizaltıya karşı ek verimi
const CARRIER_ALONE := 0.6     # yanında yüzey/denizaltı filosu olmayan uçak gemisi grubu verimi

static var enabled := true     # ölçüm/test için kapatılabilir
static var _news_left := 0     # bu turda yazılabilecek (oyuncuyu ilgilendirmeyen) deniz haberi


# ------------------------------------------------------------------ yardımcılar

static func kind_name(kind: String) -> String:
	return String(KIND_TR.get(kind, kind))


static func kind_icon(kind: String) -> String:
	match kind:
		"sub":
			return "uc_sub"
		"carrier":
			return "uc_carrier"
		"transport":
			return "cargo_ship"
	return "uc_ship"


static func kind_icon_fallback(kind: String) -> String:
	match kind:
		"sub":
			return "sub"
	return "ship"


static func cp(f) -> float:
	return f.size * float(KIND_CP.get(f.kind, 1.0))


static func disp(f) -> int:
	return maxi(1, int(round(f.size)))


static func _rng(gs, salt: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash([gs.seed_value, gs.turn, salt])
	return r


static func _cname(gs, cid: int) -> String:
	return gs.countries[cid].name


static func new_fleet(gs, owner: int, zone: String, kind: String, size: float):
	var f = Model.Fleet.new()
	f.id = gs.next_fleet_id
	gs.next_fleet_id += 1
	f.owner = owner
	f.zone = zone
	f.kind = kind
	f.size = size
	f.born = gs.turn
	gs.fleets[f.id] = f
	return f


static func fleets_of(gs, cid: int) -> Array:
	var out: Array = []
	for f in gs.fleets.values():
		if f.owner == cid:
			out.append(f)
	return out


static func at_zone(gs, zone: String) -> Array:
	var out: Array = []
	for f in gs.fleets.values():
		if f.zone == zone:
			out.append(f)
	return out


static func _index(gs) -> Dictionary:
	var by_zone: Dictionary = {}
	for f in gs.fleets.values():
		if not by_zone.has(f.zone):
			by_zone[f.zone] = []
		by_zone[f.zone].append(f)
	return by_zone


static func _by_owner(gs) -> Dictionary:
	var out: Dictionary = {}
	for f in gs.fleets.values():
		if not out.has(f.owner):
			out[f.owner] = []
		out[f.owner].append(f)
	return out


static func total_cp(gs, cid: int) -> float:
	var s := 0.0
	for f in gs.fleets.values():
		if f.owner == cid:
			s += cp(f)
	return s


## Ülke için filo kurulabilir mi? (deniz gücü ve limanı var)
static func qualifies(c) -> bool:
	return c.alive and not c.is_rebel and (c.naval_pow >= 1.0 or c.carriers >= 1)


static func sub_target(c) -> float:
	return maxf(0.0, c.naval_pow - 0.8 * float(maxi(c.carriers, 0)))


static func surface_target(c) -> float:
	if not qualifies(c):
		return 0.0
	return maxf(1.0, SURFACE_RATIO * sub_target(c) + 2.0 * float(maxi(c.carriers, 0)))


# ------------------------------------------------------------------ kurulum / eşitleme

## Filo sistemini (gerekirse) ilk kez kurar: ülkelerin naval_pow/denizaltı/uçak gemisi sayılarından filo türetir.
static func ensure(gs) -> void:
	if gs.fleets_ready:
		return
	gs.fleets = {}
	gs.next_fleet_id = 1
	gs.fleets_ready = true
	gs.refresh_stats()
	var by_owner: Dictionary = {}
	for c in gs.countries:
		if qualifies(c):
			sync_country(gs, c, by_owner, true)


static func reset(gs) -> void:
	gs.fleets = {}
	gs.next_fleet_id = 1
	gs.fleets_ready = false


## Alt filolar için tercih edilen ikinci liman bölgesi (ana limandan farklı, en çok limanı olan; yoksa ana)
static func _alt_zone(gs, cid: int, home: String) -> String:
	var ports: Dictionary = Seas.ports_of(gs, cid)
	var best := home
	var bn := 0
	for z in ports:
		if z == home or Seas.hops(home, z) > 4:
			continue
		var n: int = int(ports[z])
		if n > bn:
			bn = n
			best = z
	return best


static func _port_fleet(gs, owner_list: Array, kind: String, zone: String):
	for f in owner_list:
		if f.kind == kind and f.zone == zone and f.path.is_empty() and f.cargo == 0:
			return f
	return null


static func _sum_kind(lst: Array, kind: String) -> float:
	var s := 0.0
	for f in lst:
		if f.kind == kind:
			s += f.size
	return s


static func _scale_kind(gs, lst: Array, kind: String, factor: float) -> void:
	for f in lst.duplicate():
		if f.kind != kind:
			continue
		f.size *= factor
		if f.size < MIN_SIZE:
			_remove(gs, f)
			lst.erase(f)


static func _remove(gs, f) -> void:
	gs.fleets.erase(f.id)


## Ülkenin filolarını envanterle eşitler (ilk kurulumda fresh = true: alt filo bölgesi ayrı seçilir).
static func sync_country(gs, c, by_owner: Dictionary, fresh: bool = false) -> void:
	var lst: Array = by_owner.get(c.id, [])
	if not by_owner.has(c.id):
		lst = fleets_of(gs, c.id)
		by_owner[c.id] = lst
	var ok_c: bool = qualifies(c)
	var carriers: int = maxi(c.carriers, 0) if ok_c else 0
	var subp: float = sub_target(c) if ok_c else 0.0
	var surf: float = surface_target(c)
	var cur_c: float = _sum_kind(lst, "carrier")
	var cur_s: float = _sum_kind(lst, "sub")
	var cur_f: float = _sum_kind(lst, "surface")
	var add_c: bool = ok_c and float(carriers) - cur_c >= 0.99
	var add_s: bool = ok_c and subp >= 0.5 and subp > cur_s * 1.08 + 1.0
	var add_f: bool = ok_c and surf > 0.0 and (cur_f <= 0.0 or cur_f < surf * 0.9)
	var shr_c: bool = cur_c > float(carriers) + 0.6
	var shr_s: bool = cur_s > subp * 1.08 + 1.0
	var shr_f: bool = cur_f > surf * 1.25 + 1.0
	if not (add_c or add_s or add_f or shr_c or shr_s or shr_f):
		return
	var home := ""
	var sub_zone := ""
	if add_c or add_s or add_f:
		home = String(Seas.home_port(gs, c.id)[1])
		if home != "":
			sub_zone = _alt_zone(gs, c.id, home) if fresh else home
	# --- uçak gemisi grupları
	if add_c and home != "":
		var need: float = float(carriers) - cur_c
		var f1 = _port_fleet(gs, lst, "carrier", home)
		if f1 != null and (fresh or f1.size < 4.0):
			f1.size += need
		elif fresh and need > 5.0:
			var half: float = floor(need * 0.5)
			lst.append(new_fleet(gs, c.id, home, "carrier", need - half))
			lst.append(new_fleet(gs, c.id, home, "carrier", half))
		else:
			lst.append(new_fleet(gs, c.id, home, "carrier", need))
	elif shr_c:
		_scale_kind(gs, lst, "carrier", float(carriers) / cur_c if carriers > 0 else 0.0)
	# --- denizaltı filoları
	if add_s and home != "":
		var need2: float = subp - cur_s
		var f2 = _port_fleet(gs, lst, "sub", sub_zone)
		if f2 == null:
			f2 = _port_fleet(gs, lst, "sub", home)
		if f2 != null and not (fresh and need2 >= 80.0):
			f2.size += need2
		elif fresh and need2 >= 80.0 and _count_kind(lst, "carrier") < 2:
			lst.append(new_fleet(gs, c.id, sub_zone, "sub", need2 * 0.5))
			lst.append(new_fleet(gs, c.id, home, "sub", need2 * 0.5))
		else:
			lst.append(new_fleet(gs, c.id, sub_zone, "sub", need2))
	elif shr_s:
		_scale_kind(gs, lst, "sub", subp / cur_s if subp > 0.0 else 0.0)
	# --- muharebe (yüzey) filosu
	if add_f and home != "":
		if cur_f <= 0.0:
			lst.append(new_fleet(gs, c.id, home, "surface", surf))
		else:
			var add: float = minf(surf - cur_f, maxf(0.4, surf * 0.04))
			var f3 = _port_fleet(gs, lst, "surface", home)
			if f3 == null:
				var ports: Dictionary = Seas.ports_of(gs, c.id, true)
				for q in lst:
					if q.kind == "surface" and q.cargo == 0 and ports.has(q.zone):
						f3 = q
						break
			if f3 != null:
				f3.size += add
			elif lst.size() < MAX_FLEETS:
				lst.append(new_fleet(gs, c.id, home, "surface", add))
	elif shr_f:
		_scale_kind(gs, lst, "surface", surf / cur_f if surf > 0.0 else 0.0)


static func _count_kind(lst: Array, kind: String) -> int:
	var n := 0
	for f in lst:
		if f.kind == kind:
			n += 1
	return n


## Muharebe kayıplarını envantere yansıtır: denizaltı kalemleri ölçeklenir, uçak gemisi sayısı düşer (stokastik yuvarlama).
static func reflect(gs, cid: int) -> void:
	var c = gs.countries[cid]
	var lst: Array = fleets_of(gs, cid)
	var sub_now: float = _sum_kind(lst, "sub")
	var tgt: float = sub_target(c)
	if tgt > 0.0 and sub_now < tgt * 0.995:
		var fac: float = clampf(sub_now / tgt, 0.0, 1.0)
		var r := _rng(gs, cid * 131 + 7)
		for id in c.inv.keys():
			if not Arsenal.ITEMS.has(id) or Arsenal.cat_of(id) != "sub":
				continue
			var n: int = int(c.inv[id])
			var v: float = float(n) * fac
			var iv: int = int(floor(v))
			if r.randf() < v - float(iv):
				iv += 1
			c.inv[id] = mini(n, iv)
	var car_now: int = int(round(_sum_kind(lst, "carrier")))
	if c.carriers > car_now:
		c.carriers = maxi(0, car_now)
		c.carrier_extra = mini(c.carrier_extra, c.carriers)
	Macro.recalc(c)


# ------------------------------------------------------------------ görünürlük

## Oyuncunun deniz görüş bağlamı (HUD tek kez hesaplar)
static func vis_ctx(gs) -> Dictionary:
	var me: int = gs.player
	var ctx := {"me": me, "fog": Settings.fog, "any": {}, "asw": {}, "near": {}}
	if me < 0:
		return ctx
	for f in gs.fleets.values():
		if f.owner == me or gs.is_allied(me, f.owner):
			ctx.any[f.zone] = true
			if f.kind != "sub":
				ctx.asw[f.zone] = true
	var ports: Dictionary = Seas.ports_of(gs, me, true)
	for z in ports:
		ctx.any[z] = true
	if int(ctx.fog) == 1:
		for z2 in ctx.any.keys():
			for nb in Seas.neighbors(z2):
				ctx.near[nb] = true
	return ctx


static func visible(gs, ctx: Dictionary, f) -> bool:
	var me: int = int(ctx.me)
	if me < 0 or f.owner == me or gs.is_allied(me, f.owner) or gs.spy_active(f.owner):
		return true
	if f.kind == "sub":
		return ctx.asw.has(f.zone) or f.seen >= gs.turn
	var fog: int = int(ctx.fog)
	if fog == 0:
		return true
	if ctx.any.has(f.zone):
		return true
	return fog == 1 and ctx.near.has(f.zone)


# ------------------------------------------------------------------ tur

static func tick(gs) -> void:
	if not enabled:
		return
	ensure(gs)
	_news_left = 3
	# ölü / isyancı sahipli filolar
	for f in gs.fleets.values().duplicate():
		var c = gs.countries[f.owner] if f.owner >= 0 and f.owner < gs.countries.size() else null
		if c == null or not c.alive or c.is_rebel or not Seas.has(f.zone):
			gs.fleets.erase(f.id)
	var by_owner: Dictionary = _by_owner(gs)
	for c in gs.countries:
		if c.alive and not c.is_rebel and (qualifies(c) or by_owner.has(c.id)):
			sync_country(gs, c, by_owner)
	var idx: Dictionary = _index(gs)
	_ai_orders(gs, idx)
	_move(gs)
	idx = _index(gs)
	_combat(gs, idx)
	idx = _index(gs)
	_ai_actions(gs, idx)
	_merge_ai(gs, idx)
	_blockade(gs, idx)
	# boş nakliyeler dağıtılır
	for f in gs.fleets.values().duplicate():
		if f.kind == "transport" and f.cargo <= 0:
			gs.fleets.erase(f.id)


# ------------------------------------------------------------------ hareket

static func _hostile_in(gs, idx: Dictionary, f) -> bool:
	for g in idx.get(f.zone, []):
		if g.owner != f.owner and gs.at_war(f.owner, g.owner) and gs.fleets.has(g.id):
			return true
	return false


static func _move(gs) -> void:
	var idx: Dictionary = _index(gs)
	for f in gs.fleets.values():
		if f.path.is_empty():
			continue
		var steps: int = int(SPEED.get(f.kind, 2))
		while steps > 0 and not f.path.is_empty():
			var nxt: String = f.path[0]
			if not Seas.neighbors(f.zone).has(nxt) or not Seas.edge_ok(gs, f.owner, f.zone, nxt):
				f.path.clear()
				if f.owner == gs.player:
					var gate: String = Seas.gate_of(f.zone, nxt)
					gs.post_news("%s %s bölgesine geçemedi: yol kapandı (%s)." % [kind_name(f.kind), Seas.name_tr(nxt), Chokepoints.name_of(gate) if gate != "" else "geçit yok"], -1, "war_player", "ship")
				break
			# eski bölge indeksinden çıkar, yenisine ekle (temas denetimi için)
			if idx.has(f.zone):
				idx[f.zone].erase(f)
			f.path.pop_front()
			f.zone = nxt
			if not idx.has(nxt):
				idx[nxt] = []
			idx[nxt].append(f)
			steps -= 1
			if _hostile_in(gs, idx, f):
				f.path.clear()
				break


# ------------------------------------------------------------------ muharebe

static func _side_power(gs, side: Array, foe: Array) -> float:
	var mix: Dictionary = {}
	var tot := 0.0
	for g in foe:
		var w: float = cp(g) if g.kind != "transport" else 0.25 * g.size
		mix[g.kind] = float(mix.get(g.kind, 0.0)) + w
		tot += w
	if tot <= 0.0:
		return 0.0
	var has_escort := false
	var has_carrier := false
	for f in side:
		if f.kind == "surface" or f.kind == "sub":
			has_escort = true
		if f.kind == "carrier":
			has_carrier = true
	var p := 0.0
	for f in side:
		var base: float = cp(f)
		if base <= 0.0:
			continue
		var m := 0.0
		for k in mix:
			var mk: float = float(MATRIX[f.kind].get(k, 1.0))
			if f.kind == "surface" and k == "sub" and has_carrier:
				mk += ASW_BONUS
			m += float(mix[k]) / tot * mk
		if f.kind == "carrier" and not has_escort:
			m *= CARRIER_ALONE
		p += base * m
	return p


static func _weight_sum(side: Array) -> float:
	var s := 0.0
	for g in side:
		s += cp(g) if g.kind != "transport" else 0.25 * g.size
	return s


## Bir tarafa hasar uygular (kayıp oranı phi tüm filolarına); dönüş: {"lost": güç kaybı, "cargo": asker kaybı, "dead": [filo]}
static func _hit(gs, side: Array, phi: float) -> Dictionary:
	var lost := 0.0
	var cargo_lost := 0
	var dead: Array = []
	for g in side:
		var ph: float = phi
		if g.kind == "sub":
			ph *= 0.9
		ph = clampf(ph, 0.0, 1.0)
		var loss: float = g.size * ph
		lost += loss * maxf(float(KIND_CP.get(g.kind, 1.0)), 0.25)
		g.size -= loss
		if g.cargo > 0:
			var cl: int = int(g.cargo * minf(1.0, ph * 1.5))
			cargo_lost += cl
			g.cargo -= cl
		if g.size < MIN_SIZE:
			cargo_lost += g.cargo
			g.cargo = 0
			dead.append(g)
	return {"lost": lost, "cargo": cargo_lost, "dead": dead}


static func _combat(gs, idx: Dictionary) -> void:
	var zones: Array = idx.keys()
	zones.sort()
	var touched: Dictionary = {}
	for z in zones:
		var lst: Array = idx[z]
		if lst.size() < 2:
			continue
		var owners: Array = []
		for f in lst:
			if not owners.has(f.owner):
				owners.append(f.owner)
		if owners.size() < 2:
			continue
		owners.sort()
		var r := _rng(gs, z.hash())
		for i in owners.size():
			for j in range(i + 1, owners.size()):
				var a: int = owners[i]
				var b: int = owners[j]
				if not gs.at_war(a, b):
					continue
				var fa: Array = []
				var fb: Array = []
				for f in lst:
					if not gs.fleets.has(f.id):
						continue
					if f.owner == a:
						fa.append(f)
					elif f.owner == b:
						fb.append(f)
				if fa.is_empty() or fb.is_empty():
					continue
				var wa: float = _weight_sum(fa)
				var wb: float = _weight_sum(fb)
				if wa <= 0.0 and wb <= 0.0:
					continue
				var pa: float = _side_power(gs, fa, fb) * r.randf_range(0.85, 1.15)
				var pb: float = _side_power(gs, fb, fa) * r.randf_range(0.85, 1.15)
				if pa <= 0.0 and pb <= 0.0:
					continue
				var phi_b: float = minf(1.0, LETHAL * pa / maxf(wb, 0.25))     # b'nin kayıp oranı
				var phi_a: float = minf(1.0, LETHAL * pb / maxf(wa, 0.25))
				var ra: Dictionary = _hit(gs, fa, phi_a)
				var rb: Dictionary = _hit(gs, fb, phi_b)
				for g in fa + fb:
					g.seen = gs.turn + 1
				touched[a] = true
				touched[b] = true
				gs.stats["sea_battles"] = int(gs.stats.get("sea_battles", 0)) + 1
				_report(gs, z, a, b, ra, rb, wa, wb)
				for g in ra.dead + rb.dead:
					gs.fleets.erase(g.id)
					lst.erase(g)
				var w = gs.get_war(a, b)
				if w != null:
					var pts_a: int = 1 + int(float(rb.lost) / 12.0)
					var pts_b: int = 1 + int(float(ra.lost) / 12.0)
					w.add(a, pts_a)
					w.add(b, pts_b)
	for cid in touched:
		reflect(gs, cid)


static func _report(gs, z: String, a: int, b: int, ra: Dictionary, rb: Dictionary, wa: float, wb: float) -> void:
	var me: int = gs.player
	var mine: bool = a == me or b == me
	var big: bool = float(ra.lost) + float(rb.lost) >= 20.0
	if not mine:
		if not big or _news_left <= 0:
			return
		_news_left -= 1
	var zp: Array = Seas.provs_of(gs, z)
	var prov: int = int(zp[0]) if not zp.is_empty() else -1
	var kind := "war_player" if mine else "battle"
	gs.post_news("Deniz muharebesi: %s bölgesinde %s ile %s donanmaları çarpıştı. Kayıplar: %s %d, %s %d." % [Seas.name_tr(z), _cname(gs, a), _cname(gs, b), _cname(gs, a), int(round(float(ra.lost))), _cname(gs, b), int(round(float(rb.lost)))], prov, kind, "ship")
	for pair in [[a, ra], [b, rb]]:
		var cid: int = pair[0]
		var res: Dictionary = pair[1]
		for g in res.dead:
			if cid == me or mine or big:
				gs.post_news("%s donanmasına ait %s, %s bölgesinde yok edildi." % [_cname(gs, cid), kind_name(g.kind), Seas.name_tr(z)], prov, kind, "ship")
		if int(res.cargo) > 0 and (cid == me or mine):
			gs.post_news("%s: denizde %s asker kayboldu (nakliye vuruldu)." % [_cname(gs, cid), Macro.num(int(res.cargo))], prov, kind, "ship")
		if int(res.cargo) > 0:
			gs.stats["sea_troops_lost"] = int(gs.stats.get("sea_troops_lost", 0)) + int(res.cargo)


# ------------------------------------------------------------------ abluka

static func _enemy_power_in(gs, idx: Dictionary, z: String, cid: int) -> float:
	var s := 0.0
	for g in idx.get(z, []):
		if g.kind != "transport" and gs.at_war(cid, g.owner):
			s += cp(g) * (1.4 if g.mission == "blockade" else 1.0)
	return s


static func _friend_power_in(gs, idx: Dictionary, z: String, cid: int) -> float:
	var s := 0.0
	for g in idx.get(z, []):
		if g.kind != "transport" and (g.owner == cid or gs.is_allied(cid, g.owner)):
			s += cp(g)
	return s


## Savaştaki her ülke için kıyı bölgelerindeki düşman filo baskısını (c.fleet_block) hesaplar.
static func _blockade(gs, idx: Dictionary) -> void:
	for c in gs.countries:
		var old: float = c.fleet_block
		c.fleet_block = 0.0
		if not c.alive or c.is_rebel or c.enemies.is_empty():
			continue
		var ports: Dictionary = Seas.ports_of(gs, c.id)
		var total := 0
		for z in ports:
			total += int(ports[z])
		if total <= 0:
			continue
		var press := 0.0
		for z2 in ports:
			var e: float = _enemy_power_in(gs, idx, z2, c.id)
			if e <= 0.0:
				continue
			var o: float = _friend_power_in(gs, idx, z2, c.id)
			if e > o * 1.2:
				press += float(ports[z2]) / float(total) * clampf((e - o) / (e + o + 1.0), 0.0, 1.0) * minf(1.0, e / 6.0)
		c.fleet_block = clampf(press * 0.9, 0.0, 0.7)
		if c.id == gs.player and c.fleet_block >= 0.1 and old < 0.1:
			gs.post_news("Düşman donanması kıyılarımızı ablukaya aldı: deniz ticareti ve gelir düşüyor.", -1, "war_player", "ship")


# ------------------------------------------------------------------ yapay zekâ

static func _ai_controls(gs, f) -> bool:
	if f.owner != gs.player:
		return true
	return gs.player >= 0 and gs.countries[gs.player].auto_cmd and not f.hold


static func _live_enemies(gs, c) -> Array:
	var out: Array = []
	for e in c.enemies:
		var ec = gs.countries[e]
		if ec.alive and not ec.is_rebel:
			out.append(e)
	return out


static func _set_path(gs, f, dest: String) -> bool:
	var p: Array = Seas.path(gs, f.owner, f.zone, dest)
	if p.is_empty():
		return false
	f.path = p
	return true


static func _ai_orders(gs, idx: Dictionary) -> void:
	for f in gs.fleets.values():
		if f.kind == "transport" or not f.path.is_empty():
			continue
		if not _ai_controls(gs, f):
			continue
		if (gs.turn + f.id) % 3 != 0:
			continue
		_ai_one(gs, f, idx)


static func _ai_one(gs, f, idx: Dictionary) -> void:
	var c = gs.countries[f.owner]
	var enemies: Array = _live_enemies(gs, c)
	var my_ports: Dictionary = Seas.ports_of(gs, c.id, true)
	if enemies.is_empty():
		f.mission = ""
		if not my_ports.has(f.zone):
			var hp: Array = Seas.home_port(gs, c.id)
			if String(hp[1]) != "":
				_set_path(gs, f, String(hp[1]))
		return
	var own: float = 0.0
	for g in idx.get(f.zone, []):
		if g.owner == f.owner:
			own += cp(g)
	own = maxf(own, cp(f))
	var here_e: float = _enemy_power_in(gs, idx, f.zone, c.id)
	var cand: Dictionary = {}          # bölge -> puan
	# kıyılarını savun: düşman filosu kendi limanlarımızın bölgesinde
	for z in my_ports:
		var ez: float = _enemy_power_in(gs, idx, z, c.id)
		if ez > 0.0 and ez <= own * 1.4:
			cand[z] = 6.0 + float(my_ports[z]) * 0.3
	# düşman limanları / ticaret
	var foe_ports: Dictionary = {}
	for e in enemies:
		var ep: Dictionary = Seas.ports_of(gs, e)
		for z2 in ep:
			foe_ports[z2] = int(foe_ports.get(z2, 0)) + int(ep[z2])
	for z3 in foe_ports:
		var e3: float = _enemy_power_in(gs, idx, z3, c.id)
		var lim: float = own * (3.0 if f.kind == "sub" else 1.3)
		if e3 > lim:
			continue
		var sc: float = minf(float(foe_ports[z3]), 6.0) * 0.8 - e3 / (own + 1.0) * 2.0
		if f.kind == "sub" and e3 > 0.0:
			sc += 3.0
		cand[z3] = maxf(float(cand.get(z3, -99.0)), sc)
	# düşman nakliyeleri (yalnız yüzey/denizaltı)
	for z4 in idx:
		for g in idx[z4]:
			if g.kind == "transport" and gs.at_war(c.id, g.owner) and _enemy_power_in(gs, idx, z4, c.id) <= own:
				cand[z4] = maxf(float(cand.get(z4, -99.0)), 5.0)
	# tehlikedeyse geri çekil
	if here_e > own * 1.6 and not my_ports.has(f.zone):
		var hp2: Array = Seas.home_port(gs, c.id)
		if String(hp2[1]) != "" and _set_path(gs, f, String(hp2[1])):
			f.mission = ""
		return
	# mevcut bölge zaten iyi bir hedefse (düşman limanı) yerinde kal: abluka
	if cand.has(f.zone) and float(cand[f.zone]) >= 0.0:
		f.mission = "blockade" if foe_ports.has(f.zone) else ""
		return
	var best_z := ""
	var best_s := -1e9
	var ranked: Array = []
	for z5 in cand:
		var h: int = Seas.hops(f.zone, z5)
		if h > 7:
			continue
		ranked.append([float(cand[z5]) - float(h) * 0.5, z5])
	ranked.sort_custom(func(a, b): return a[0] > b[0])
	for i in mini(3, ranked.size()):
		if float(ranked[i][0]) < -2.0:
			break
		if _set_path(gs, f, String(ranked[i][1])):
			f.mission = "blockade" if foe_ports.has(String(ranked[i][1])) else ""
			best_z = String(ranked[i][1])
			best_s = float(ranked[i][0])
			break
	if best_z == "" and not my_ports.has(f.zone):
		var hp3: Array = Seas.home_port(gs, c.id)
		if String(hp3[1]) != "":
			_set_path(gs, f, String(hp3[1]))


## Yapay zekâ (ve otomatik komutlu oyuncu) kıyı bombardımanı ve denizaltı torpido saldırıları
static func _ai_actions(gs, idx: Dictionary) -> void:
	var rr := _rng(gs, 991)
	for f in gs.fleets.values().duplicate():
		if not gs.fleets.has(f.id) or f.cd > gs.turn or not _ai_controls(gs, f):
			continue
		var c = gs.countries[f.owner]
		if c.enemies.is_empty():
			continue
		if f.kind == "sub":
			var tgt = _best_torpedo_target(gs, f, idx)
			if tgt != null and rr.randf() < 0.7:
				_torpedo_apply(gs, f, tgt, idx)
		elif f.kind == "surface" or f.kind == "carrier":
			var pid: int = _best_bombard_target(gs, f)
			if pid >= 0:
				bombard_apply(gs, f, pid, true)


static func _merge_ai(gs, idx: Dictionary) -> void:
	for z in idx:
		var lst: Array = idx[z]
		if lst.size() < 2:
			continue
		var groups: Dictionary = {}
		for f in lst:
			if f.kind == "transport" or f.cargo > 0 or not f.path.is_empty() or f.hold or not gs.fleets.has(f.id):
				continue
			if f.owner == gs.player and not _ai_controls(gs, f):
				continue
			var k := "%d|%s" % [f.owner, f.kind]
			if not groups.has(k):
				groups[k] = []
			groups[k].append(f)
		for k2 in groups:
			var g: Array = groups[k2]
			if g.size() < 2:
				continue
			g.sort_custom(func(a, b): return a.size > b.size)
			var keep = g[0]
			for i in range(1, g.size()):
				keep.size += g[i].size
				gs.fleets.erase(g[i].id)


# ------------------------------------------------------------------ eylemler: bombardıman / torpido

static func _holder_hostile(gs, cid: int, pid: int) -> bool:
	var p = gs.provinces[pid]
	var h: int = p.controller if p.controller >= 0 else p.owner
	return h >= 0 and gs.at_war(cid, h)


## Bu filonun bombardıman edebileceği düşman kıyı eyaletleri (bölgeye bitişik, savaştaki ülkenin elinde)
static func bombard_targets(gs, f) -> Array:
	var out: Array = []
	if f.kind != "surface" and f.kind != "carrier":
		return out
	for pid in Seas.provs_of(gs, f.zone):
		if _holder_hostile(gs, f.owner, pid):
			out.append(pid)
	return out


static func _best_bombard_target(gs, f) -> int:
	var best := -1
	var bs := -1.0
	for pid in bombard_targets(gs, f):
		var a = gs.armies.get(pid)
		var sc := 0.0
		if a != null and a.owner != f.owner:
			sc = float(a.size) / 1000.0 + 1.0
		elif gs.provinces[pid].siege_by == f.owner:
			sc = 0.8
		if sc > bs:
			bs = sc
			best = pid
	return best if bs > 0.0 else -1


static func bombard_cost(gs, cid: int) -> float:
	return clampf(gs.countries[cid].income * 0.08, 3.0, 150.0)


## Bombardımanı uygular (oyuncu bedeli çağıran öder). Dönüş: öldürülen asker
static func bombard_apply(gs, f, pid: int, quiet: bool = false) -> int:
	var p = gs.provinces[pid]
	var eff: float = f.size if f.kind == "surface" else f.size * 5.0
	var k: float = clampf(0.04 + 0.0035 * eff, 0.04, 0.30)
	var killed := 0
	var a = gs.armies.get(pid)
	if a != null and a.owner != f.owner:
		var air: float = gs.countries[a.owner].air_pow
		k *= 1.0 - 0.3 * clampf(air / (air + 40.0), 0.0, 1.0)
		killed = int(a.size * k)
		a.size = maxi(1, a.size - killed)
	var def_hit := false
	if p.defense > 0 and eff >= 12.0 and _rng(gs, f.id * 17 + pid).randf() < 0.5:
		p.defense -= 1
		def_hit = true
	if p.siege_by == f.owner and p.siege > 0:
		p.siege += 1
	# kıyı bataryalarının karşılığı
	f.size = maxf(MIN_SIZE, f.size * (1.0 - 0.01 * float(1 + p.defense)))
	f.cd = gs.turn + BOMBARD_CD
	f.seen = gs.turn + 1
	var holder: int = p.controller if p.controller >= 0 else p.owner
	if f.owner == gs.player or holder == gs.player or (not quiet):
		var bk: String = "war_player" if (f.owner == gs.player or holder == gs.player) else "battle"
		if killed > 0 and def_hit:
			gs.post_news("%s donanması %s eyaletini bombaladı: %s asker kaybı, savunma zayıfladı." % [_cname(gs, f.owner), p.name, Macro.num(killed)], pid, bk, "ship")
		elif killed > 0:
			gs.post_news("%s donanması %s eyaletini bombaladı: %s asker kaybı." % [_cname(gs, f.owner), p.name, Macro.num(killed)], pid, bk, "ship")
		else:
			gs.post_news("%s donanması %s kıyılarını bombaladı." % [_cname(gs, f.owner), p.name], pid, "war_player" if (f.owner == gs.player or holder == gs.player) else "battle", "ship")
	gs.province_changed.emit(pid)
	gs.armies_changed.emit()
	return killed


static func _best_torpedo_target(gs, f, idx: Dictionary):
	var best = null
	var bs := -1.0
	for g in idx.get(f.zone, []):
		if g.owner == f.owner or not gs.at_war(f.owner, g.owner) or not gs.fleets.has(g.id):
			continue
		var sc: float = g.size * (1.0 if g.kind != "sub" else 0.3)
		if g.kind == "transport":
			sc = 50.0 + float(g.cargo) / 1000.0
		if g.kind == "sub":
			sc *= 0.5
		if sc > bs:
			bs = sc
			best = g
	return best


## Torpido: gizli saldırı. Dönüş {"hit": güç kaybı, "cargo": asker kaybı}
static func _torpedo_apply(gs, f, tgt, idx: Dictionary) -> Dictionary:
	var r := _rng(gs, f.id * 31 + tgt.id)
	var m: float = float(MATRIX["sub"].get(tgt.kind, 1.0))
	var dmg: float = f.size * 0.18 * r.randf_range(0.8, 1.2) * m
	var w: float = maxf(_weight_sum([tgt]), 0.25)
	var phi: float = clampf(dmg / w, 0.0, 0.7)
	var res: Dictionary = _hit(gs, [tgt], phi)
	var escorts := 0.0
	for g in idx.get(f.zone, []):
		if g.owner == tgt.owner and (g.kind == "surface" or g.kind == "carrier"):
			escorts += cp(g)
	if escorts > 0.0:
		f.size = maxf(MIN_SIZE, f.size * (1.0 - clampf(0.02 + escorts / (escorts + f.size * 10.0) * 0.06, 0.0, 0.08)))
	f.cd = gs.turn + TORPEDO_CD
	f.seen = gs.turn + SUB_REVEAL
	var owner: int = tgt.owner
	for g in res.dead:
		gs.fleets.erase(g.id)
	var mine: bool = f.owner == gs.player or owner == gs.player
	var zp: Array = Seas.provs_of(gs, f.zone)
	var prov: int = int(zp[0]) if not zp.is_empty() else -1
	if mine or _news_left > 0:
		if not mine:
			_news_left -= 1
		gs.post_news("%s denizaltıları %s bölgesinde %s filosuna torpido saldırısı yaptı: %d güç kaybı." % [_cname(gs, f.owner), Seas.name_tr(f.zone), _cname(gs, owner), int(round(float(res.lost)))], prov, "war_player" if mine else "battle", "sub")
		if int(res.cargo) > 0:
			gs.post_news("%s: nakliyedeki %s asker denizde kayboldu." % [_cname(gs, owner), Macro.num(int(res.cargo))], prov, "war_player" if mine else "battle", "ship")
	if int(res.cargo) > 0:
		gs.stats["sea_troops_lost"] = int(gs.stats.get("sea_troops_lost", 0)) + int(res.cargo)
	var w2 = gs.get_war(f.owner, owner)
	if w2 != null:
		w2.add(f.owner, 1 + int(float(res.lost) / 12.0))
	reflect(gs, owner)
	gs.armies_changed.emit()
	return {"hit": float(res.lost), "cargo": int(res.cargo)}


# ------------------------------------------------------------------ oyuncu eylemleri

static func _mine(gs, fid: int):
	var f = gs.fleets.get(fid)
	if f == null or f.owner != gs.player:
		return null
	return f


static func order_move(gs, fid: int, dest: String) -> String:
	var f = _mine(gs, fid)
	if f == null:
		return "Bu filo senin değil."
	if not Seas.has(dest):
		return "Geçersiz deniz bölgesi."
	if dest == f.zone:
		f.path.clear()
		f.mission = ""
		return ""
	var p: Array = Seas.path(gs, f.owner, f.zone, dest)
	if p.is_empty():
		return "Oraya ulaşılamıyor: yolda kapalı bir boğaz/kanal var ya da deniz bağlantısı yok."
	f.path = p
	f.hold = true
	f.mission = ""
	gs.player_acted = true
	gs.stats["orders"] = int(gs.stats.get("orders", 0)) + 1
	gs.armies_changed.emit()
	return ""


static func stop(gs, fid: int) -> String:
	var f = _mine(gs, fid)
	if f == null:
		return "Bu filo senin değil."
	f.path.clear()
	f.mission = ""
	gs.armies_changed.emit()
	return ""


## Aynı bölgedeki aynı türdeki kendi filolarını seçilene katar
static func merge(gs, fid: int) -> String:
	var f = _mine(gs, fid)
	if f == null:
		return "Bu filo senin değil."
	var n := 0
	for g in at_zone(gs, f.zone):
		if g == f or g.owner != f.owner or g.kind != f.kind:
			continue
		f.size += g.size
		f.cargo += g.cargo
		if g.cargo_lvl > f.cargo_lvl:
			f.cargo_lvl = g.cargo_lvl
			f.cargo_name = g.cargo_name
			f.cargo_wins = g.cargo_wins
		gs.fleets.erase(g.id)
		n += 1
	if n == 0:
		return "Bu bölgede birleştirilecek aynı türde başka filon yok."
	f.path.clear()
	gs.armies_changed.emit()
	return ""


static func blockade_candidates(gs, cid: int) -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	for e in _live_enemies(gs, gs.countries[cid]):
		for z in Seas.ports_of(gs, e):
			if not seen.has(z):
				seen[z] = true
				out.append(z)
	return out


## Abluka: en yakın savaştaki düşman limanı bölgesine gider ve orada abluka görevi alır
static func blockade(gs, fid: int) -> String:
	var f = _mine(gs, fid)
	if f == null:
		return "Bu filo senin değil."
	if f.kind == "transport":
		return "Nakliye filosu abluka yapamaz."
	var cands: Array = blockade_candidates(gs, f.owner)
	if cands.is_empty():
		return "Abluka için savaşta olduğun ve kıyısı olan bir düşman gerekir."
	var best := ""
	var bh := 99
	var bp: Array = []
	for z in cands:
		if z == f.zone:
			best = z
			bh = 0
			bp = []
			break
		var p: Array = Seas.path(gs, f.owner, f.zone, z)
		if not p.is_empty() and p.size() < bh:
			bh = p.size()
			best = z
			bp = p
	if best == "":
		return "Düşman kıyısına ulaşılamıyor: boğazlar kapalı."
	f.path = bp
	f.mission = "blockade"
	f.hold = true
	gs.player_acted = true
	gs.armies_changed.emit()
	return ""


## Oyuncu bombardımanı: {"err", "killed"}
static func player_bombard(gs, fid: int, pid: int) -> Dictionary:
	var res := {"err": "", "killed": 0}
	var f = _mine(gs, fid)
	if f == null:
		res.err = "Bu filo senin değil."
		return res
	if f.kind != "surface" and f.kind != "carrier":
		res.err = "Yalnız muharebe filosu ve uçak gemisi grubu kıyıyı bombalayabilir."
		return res
	if f.cd > gs.turn:
		res.err = "Filo hazırlanıyor (%d hafta)." % (f.cd - gs.turn)
		return res
	if not Seas.coast_zones(gs, pid).has(f.zone) or not _holder_hostile(gs, f.owner, pid):
		res.err = "Hedef, filonun bulunduğu denize bitişik düşman kıyı eyaleti olmalı."
		return res
	var cost: float = bombard_cost(gs, f.owner)
	var c = gs.countries[f.owner]
	if c.gold < cost:
		res.err = "Kasa yetersiz: %s gerekir." % Macro.money(cost)
		return res
	c.gold -= cost
	res.killed = bombard_apply(gs, f, pid)
	gs.state_changed.emit()
	return res


## Oyuncu torpidosu: {"err", "hit", "cargo"}
static func player_torpedo(gs, fid: int, target_id: int = -1) -> Dictionary:
	var res := {"err": "", "hit": 0.0, "cargo": 0}
	var f = _mine(gs, fid)
	if f == null:
		res.err = "Bu filo senin değil."
		return res
	if f.kind != "sub":
		res.err = "Torpido yalnız denizaltı filosuyla atılır."
		return res
	if f.cd > gs.turn:
		res.err = "Denizaltılar hazırlanıyor (%d hafta)." % (f.cd - gs.turn)
		return res
	var idx: Dictionary = _index(gs)
	var tgt = gs.fleets.get(target_id) if target_id >= 0 else _best_torpedo_target(gs, f, idx)
	if tgt == null or tgt.zone != f.zone or not gs.at_war(f.owner, tgt.owner):
		res.err = "Bu bölgede saldırılacak düşman filosu yok."
		return res
	var out: Dictionary = _torpedo_apply(gs, f, tgt, idx)
	res.hit = out.hit
	res.cargo = out.cargo
	gs.state_changed.emit()
	return res


# ------------------------------------------------------------------ ordu: gemiye bin / karaya çık

static func cargo_cap(gs, f) -> int:
	var cap: int
	match f.kind:
		"transport":
			cap = gs.landing_cap(f.owner)
		"carrier":
			cap = int(2000.0 + 2500.0 * f.size)
		_:
			cap = int(2500.0 + 1200.0 * f.size)
	return mini(cap, gs.landing_cap(f.owner)) if f.kind != "transport" else cap


## Ordu limandaki kendi ordusunu bir filoya (fid >= 0) ya da otomatik nakliye filosuna bindirir.
static func embark(gs, pid: int, count: int = 0, fid: int = -1) -> String:
	var me: int = gs.player
	var a = gs.armies.get(pid)
	if a == null or a.owner != me:
		return "Burada senin ordun yok."
	var p = gs.provinces[pid]
	if not p.coastal or p.controller != me:
		return "Gemiye binmek için kendi elindeki bir kıyı eyaletinde olmalısın."
	var zs: Array = Seas.coast_zones(gs, pid)
	if zs.is_empty():
		return "Bu eyaletin denize açılan limanı yok."
	if a.sp_size > 0:
		return "Önce bu ordunun bölme emrini iptal et."
	var n: int = a.size if count <= 0 else mini(count, a.size)
	n = mini(n, gs.landing_cap(me))
	if n < 1:
		return "Taşıma kapasiten yok."
	var f = null
	if fid >= 0:
		f = gs.fleets.get(fid)
		if f == null or f.owner != me or f.kind == "sub":
			return "Bu filoya asker bindirilemez."
		if not zs.has(f.zone):
			return "Filo bu limana bitişik denizde olmalı."
		var room: int = cargo_cap(gs, f) - f.cargo
		if room < 1:
			return "Filonun taşıma kapasitesi dolu."
		n = mini(n, room)
	else:
		f = new_fleet(gs, me, String(zs[0]), "transport", maxf(1.0, ceil(float(n) / 6000.0)))
	f.cargo += n
	if n >= a.size:
		if a.cmd_lvl > f.cargo_lvl:
			f.cargo_lvl = a.cmd_lvl
			f.cargo_name = a.cmd_name
			f.cargo_wins = a.cmd_wins
		gs.armies.erase(pid)
	else:
		a.size -= n
		a.path.clear()
		a.leaving = false
	if f.kind == "transport" and fid < 0:
		f.size = maxf(1.0, ceil(float(f.cargo) / 6000.0))
	gs.player_acted = true
	gs.refresh_stats()
	gs.armies_changed.emit()
	gs.state_changed.emit()
	return ""


## Karaya çıkış hedefi geçerli mi? "" = uygun, aksi halde neden
static func debark_check(gs, f, pid: int) -> String:
	if f == null or f.owner != gs.player or f.cargo <= 0:
		return "Filoda asker yok."
	var p = gs.provinces[pid]
	if not p.coastal or not Seas.coast_zones(gs, pid).has(f.zone):
		return "Hedef, filonun bulunduğu denize bitişik bir kıyı eyaleti olmalı."
	var me: int = gs.player
	var hostile: bool = _holder_hostile(gs, me, pid) or gs.at_war(me, p.owner)
	if not hostile and not gs.friendly_port(me, pid):
		return "Savaşta olmadığın bir ülkenin kıyısına çıkarma yapamazsın."
	var occ = gs.armies.get(pid)
	if occ != null and occ.owner != me and not gs.at_war(me, occ.owner):
		return "Hedef eyalette savaşmadığın bir ülkenin ordusu var."
	if hostile and gs.countries[me].gold < gs.op_cost("landing"):
		return "Kasa yetersiz: çıkarma bedeli %s." % Macro.money(gs.op_cost("landing"))
	return ""


static func debark_targets(gs, f) -> Array:
	var out: Array = []
	for pid in Seas.provs_of(gs, f.zone):
		if debark_check(gs, f, pid) == "":
			out.append(pid)
	out.sort_custom(func(a, b):
		var ha: int = 1 if _holder_hostile(gs, f.owner, a) else 0
		var hb: int = 1 if _holder_hostile(gs, f.owner, b) else 0
		if ha != hb:
			return ha > hb
		return a < b)
	return out


## Filodaki askeri hedef kıyı eyaletine çıkarır (mevcut çıkarma kuralları: savunma, landing_cap, harekât bedeli).
static func debark(gs, fid: int, pid: int) -> String:
	var f = gs.fleets.get(fid)
	var err: String = debark_check(gs, f, pid)
	if err != "":
		return err
	var me: int = gs.player
	var p = gs.provinces[pid]
	var hostile: bool = _holder_hostile(gs, me, pid) or gs.at_war(me, p.owner)
	var n: int = mini(f.cargo, maxi(gs.landing_cap(me), 1)) if hostile else f.cargo
	var a := Model.Army.new()
	a.id = gs.next_army_id
	gs.next_army_id += 1
	a.owner = me
	a.prov = -1
	a.size = n
	a.cmd_lvl = f.cargo_lvl
	a.cmd_name = f.cargo_name
	a.cmd_wins = f.cargo_wins
	a.hold = true
	if hostile:
		a.op = "landing"
		gs.countries[me].gold -= gs.op_cost("landing")
		gs.stats["landings"] = int(gs.stats.get("landings", 0)) + 1
		var holder: int = p.controller if p.controller >= 0 else p.owner
		gs.sea_campaign[holder] = true
	f.cargo -= n
	if f.cargo <= 0:
		f.cargo = 0
		f.cargo_lvl = 0
		f.cargo_name = ""
		f.cargo_wins = 0
	var ex = gs.armies.get(pid)
	var before: int = ex.size if ex != null and ex.owner == me else 0
	gs._enter(a, pid)
	gs.post_news("%s ordusu %s kıyısına denizden çıkarma yaptı." % [_cname(gs, me), p.name], pid, "war_player", "landing")
	if f.kind == "transport" and f.cargo <= 0:
		gs.fleets.erase(f.id)
	gs.player_acted = true
	gs.refresh_stats()
	gs.province_changed.emit(pid)
	gs.armies_changed.emit()
	gs.state_changed.emit()
	return ""


# ------------------------------------------------------------------ savaş etkileşimi

## Doğrudan çıkarma (ordu -> hedef) rotasındaki bölgeler: iki eyaletin ortak bölgesi ya da en kısa bölge yolu
static func route_zones(gs, from_pid: int, to_pid: int) -> Array:
	var za: Array = Seas.coast_zones(gs, from_pid)
	var zb: Array = Seas.coast_zones(gs, to_pid)
	if za.is_empty() or zb.is_empty():
		return []
	for z in za:
		if zb.has(z):
			return [z]
	var best: Array = []
	for a in za:
		for b in zb:
			var p: Array = _free_path(a, b)
			if not p.is_empty() and (best.is_empty() or p.size() + 1 < best.size()):
				best = [a] + p
	return best


static func _free_path(a: String, b: String) -> Array:
	if a == b:
		return []
	var prev: Dictionary = {a: ""}
	var q: Array = [a]
	var qi := 0
	while qi < q.size():
		var cur: String = q[qi]
		qi += 1
		if cur == b:
			break
		for nb in Seas.neighbors(cur):
			if not prev.has(nb):
				prev[nb] = cur
				q.append(nb)
	if not prev.has(b):
		return []
	var out: Array = []
	var c: String = b
	while c != a:
		out.push_front(c)
		c = prev[c]
	return out


## Çıkarma filosunu rotadaki düşman donanmaları vurur. -1: filo temelli hesap yapılmadı (eski kod çalışsın), >=0: kaybedilen asker
static func intercept_loss(gs, army, from_pid: int, to_pid: int) -> int:
	if not gs.fleets_ready or gs.fleets.is_empty():
		return -1
	var zones: Array = route_zones(gs, from_pid, to_pid)
	if zones.is_empty():
		return -1
	var idx: Dictionary = _index(gs)
	var foes := 0.0
	var mine := 0.0
	var subshare := 0.0
	for z in zones:
		for g in idx.get(z, []):
			if g.kind == "transport":
				continue
			if gs.at_war(army.owner, g.owner):
				foes += cp(g)
				if g.kind == "sub":
					subshare += cp(g)
			elif g.owner == army.owner or gs.is_allied(army.owner, g.owner):
				mine += cp(g)
	if foes <= 0.0:
		return -1
	var edge: float = (foes - mine) / (foes + mine + 1.0)
	if edge <= 0.0:
		return 0
	var frac: float = minf(0.25, 0.05 + 0.2 * edge * (0.6 + 0.4 * subshare / foes))
	var lost: int = int(army.size * frac)
	if lost < 1 or army.size - lost < 1:
		return 0
	army.size -= lost
	return lost


# ------------------------------------------------------------------ kayıt

static func to_array(gs) -> Array:
	var out: Array = []
	for f in gs.fleets.values():
		out.append([f.id, f.owner, f.zone, f.kind, f.size, f.path, f.hold, f.cargo, f.cargo_lvl, f.cargo_name, f.cargo_wins, f.cd, f.seen, f.mission, f.born])
	return out


static func from_array(gs, arr: Array) -> void:
	gs.fleets = {}
	var mx := 0
	for r in arr:
		if r.size() < 15:
			continue
		var f = Model.Fleet.new()
		f.id = int(r[0])
		f.owner = int(r[1])
		f.zone = String(r[2])
		f.kind = String(r[3])
		f.size = float(r[4])
		f.path = (r[5] as Array).duplicate()
		f.hold = bool(r[6])
		f.cargo = int(r[7])
		f.cargo_lvl = int(r[8])
		f.cargo_name = String(r[9])
		f.cargo_wins = int(r[10])
		f.cd = int(r[11])
		f.seen = int(r[12])
		f.mission = String(r[13])
		f.born = int(r[14])
		if not Seas.has(f.zone) or f.owner < 0 or f.owner >= gs.countries.size() or not KINDS.has(f.kind) or f.size <= 0.0:
			continue
		gs.fleets[f.id] = f
		mx = maxi(mx, f.id)
	gs.next_fleet_id = maxi(gs.next_fleet_id, mx + 1)
	gs.fleets_ready = true
