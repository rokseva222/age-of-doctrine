extends RefCounted
## TARİHÎ ANLAR: tarihî kiplerde gerçek olaylar tarihinde kart olarak gelir.
## Oyuncu olayın tarafıysa (roles içinde ülkesi varsa) seçenekli kart; değilse izleyici kartı (major) ya da haber,
## ve olayın tarihî etkisi (default_fx) uygulanır. Veri: data/moments/<era>.json (alt_* çağlar base'ini kullanır).
## fx: ["war",A,B] ["peace",A,B] ["ally",A,B] ["stab",A,d] ["gold",A,hafta] ["troops",A,yüzde] ["buff",A,key,çarpan,hafta]
##     ["rel",A,B,d] ["cede",A,B,n] (A'nın B'ye en yakın n eyaleti B'ye) ["flag",ad] ["unflag",ad] ["xstab",A,d]
## Oyuncunun kendi seçeneği oyuncuya da uygulanır; default_fx oyuncuya savaş ilanı dışında dokunmaz.

const EraExt = preload("res://scripts/era_ext.gd")
const DataUtil = preload("res://scripts/data_util.gd")
const Loc = preload("res://scripts/loc.gd")
const Macro = preload("res://scripts/macro.gd")

static var _cache: Dictionary = {}


static func _load(era: String) -> Array:
	if _cache.has(era):
		return _cache[era]
	var out: Array = []
	var d = DataUtil.read_json("res://data/moments/%s.json" % era)
	if d is Dictionary and d.has("moments"):
		out = d["moments"]
	elif d is Array:
		out = d
	_cache[era] = out
	return out


## Çağın an havuzu: çağın kendisi + (alt çağ ise) base çağı, ayrışma tarihine kadar
static func pool(era: String) -> Array:
	var out: Array = _load(era).duplicate()
	if EraExt.has_era(era):
		var b: String = EraExt.base_of(era)
		if b != "" and b != era:
			var until: Array = EraExt.raw(era).get("inherit_until", [])
			var ukey: int = (int(until[0]) * 12 + int(until[1]) - 1) if until.size() >= 2 else 999999
			for m in _load(b):
				if int(m["y"]) * 12 + int(m["m"]) - 1 < ukey:
					out.append(m)
	return out


static func _id(gs, name_en: String) -> int:
	return int(gs.macro_idx.get(name_en, -1))


static func _ok(gs, m: Dictionary) -> bool:
	var fl: Dictionary = gs.moment_flags
	for f in m.get("requires", []):
		if not fl.has(String(f)):
			return false
	for f in m.get("forbid", []):
		if fl.has(String(f)):
			return false
	var fired: Dictionary = fl.get("_fired", {})
	return not fired.has(String(m["id"]))


## Ay değiştiğinde: o aya düşen anlar
static func tick(gs, era: String, prev_ym: Array, ym: Array) -> void:
	if era == "":
		return
	var key: int = int(ym[0]) * 12 + int(ym[1]) - 1
	if prev_ym.size() == 2 and int(prev_ym[0]) * 12 + int(prev_ym[1]) - 1 == key:
		return
	for m in pool(era):
		if int(m["y"]) * 12 + int(m["m"]) - 1 != key or not _ok(gs, m):
			continue
		fire(gs, m)


## Çağ başlarken: başlangıç ayına düşen anlar hemen gelir (ör. Ekim 1962 Küba Füze Krizi)
static func start(gs, era: String, ym: Array) -> void:
	if era == "" or ym.size() < 2:
		return
	var key: int = int(ym[0]) * 12 + int(ym[1]) - 1
	for m in pool(era):
		if int(m["y"]) * 12 + int(m["m"]) - 1 == key and _ok(gs, m):
			fire(gs, m)
			if not gs.moment_pending.is_empty():
				return


static func fire(gs, m: Dictionary) -> void:
	var fired: Dictionary = gs.moment_flags.get("_fired", {})
	fired[String(m["id"])] = gs.turn
	gs.moment_flags["_fired"] = fired
	var me_en: String = gs.countries[gs.player].name_en if gs.player >= 0 else ""
	var roles: Dictionary = m.get("roles", {})
	if roles.has(me_en) and gs.countries[gs.player].alive:
		gs.moment_pending = {"id": m["id"], "role": me_en, "m": m}
		gs.moment_card.emit()
		return
	# izleyici: tarihî etki
	for f in m.get("default_fx", []):
		apply(gs, f)
	if bool(m.get("major", false)):
		gs.moment_pending = {"id": m["id"], "role": "", "m": m}
		gs.moment_card.emit()
	else:
		gs.post_news(String(m.get("text", m.get("title", ""))), -1, "event")


## Oyuncunun seçimi (pending.role != "")
static func choose(gs, idx: int) -> void:
	var p: Dictionary = gs.moment_pending
	gs.moment_pending = {}
	if p.is_empty():
		return
	var m: Dictionary = p.m
	if String(p.role) == "":
		return
	var opts: Array = (m.roles[p.role] as Dictionary).get("options", [])
	if idx < 0 or idx >= opts.size():
		return
	var o: Dictionary = opts[idx]
	for f in o.get("fx", []):
		apply(gs, f, true)
	# oyuncunun seçmediği tarafların tarihî etkileri (oyuncuyu ilgilendirmeyenler) yine de olur
	if bool(o.get("keep_default", false)):
		for f in m.get("default_fx", []):
			apply(gs, f)
	var r: String = String(o.get("r", ""))
	if r != "":
		gs.post_news(r, -1, "event")


static func apply(gs, f: Array, by_player: bool = false) -> void:
	var kind: String = String(f[0])
	if kind == "flag":
		gs.moment_flags[String(f[1])] = gs.turn
		return
	if kind == "unflag":
		gs.moment_flags.erase(String(f[1]))
		return
	var a: int = _id(gs, String(f[1]))
	if a < 0 or not gs.countries[a].alive:
		return
	var ca = gs.countries[a]
	var protect: bool = (a == gs.player) and not by_player       # izleyici etkileri oyuncuya dokunmaz
	match kind:
		"war":
			var b: int = _id(gs, String(f[2]))
			if b >= 0 and gs.countries[b].alive and not gs.at_war(a, b) and (by_player or a != gs.player):
				ca.truce.erase(b)
				gs.countries[b].truce.erase(a)
				gs.declare_war(a, b)
		"peace":
			var b2: int = _id(gs, String(f[2]))
			if b2 >= 0 and not protect and b2 != gs.player or by_player:
				var w = gs.get_war(a, b2)
				if w != null:
					gs.finish_peace(w, -1, [])
		"ally":
			var b3: int = _id(gs, String(f[2]))
			if b3 >= 0 and gs.countries[b3].alive and not gs.is_allied(a, b3) and not gs.at_war(a, b3) and (by_player or (a != gs.player and b3 != gs.player)):
				gs.make_alliance(a, b3)
		"stab":
			if not protect:
				ca.stability = clampf(ca.stability + float(f[2]), 5.0, 100.0)
		"xstab":
			ca.stability = clampf(ca.stability + float(f[2]), 5.0, 100.0)
		"gold":
			ca.gold = maxf(0.0, ca.gold + maxf(ca.income, 1.0) * float(f[2]))
		"troops":
			var pct: float = float(f[2])
			if pct > 0.0:
				gs.place_recruits(ca, int(maxf(ca.troops, 5000.0) * pct / 100.0))
			else:
				for ar in gs.armies_of(a):
					ar.size = maxi(100, int(ar.size * (1.0 + pct / 100.0)))
			gs.refresh_stats()
		"buff":
			ca.buffs[String(f[2])] = [float(f[3]), gs.turn + int(f[4])]
		"rel":
			var b4: int = _id(gs, String(f[2]))
			if b4 >= 0:
				gs.relation_add(a, b4, float(f[3]))
		"cede":
			var b5: int = _id(gs, String(f[2]))
			if b5 < 0 or protect:
				return
			var n: int = int(f[3])
			var cp: Vector2 = gs.provinces[gs.countries[b5].capital].label_pos if gs.countries[b5].capital >= 0 else Vector2.ZERO
			var cand: Array = []
			for pid in ca.owned_ids:
				if pid != ca.capital:
					cand.append(pid)
			cand.sort_custom(func(x, y): return gs.provinces[x].label_pos.distance_to(cp) < gs.provinces[y].label_pos.distance_to(cp))
			for i in mini(n, cand.size()):
				var p = gs.provinces[cand[i]]
				p.owner = b5
				p.controller = b5
				p.core = b5
				p.siege = 0
				p.unrest = 0
				p.acquired = gs.turn
				gs.province_changed.emit(p.id)
			gs._fix_capital(a)
			gs.refresh_stats()
			Macro.build_idx(gs)
		"mob":
			Macro._now = gs.turn
			ca.mob_until = gs.turn + int(f[2])


static func resume(gs) -> void:
	if not gs.moment_pending.is_empty():
		gs.moment_card.emit()


## Kart metni: oyuncu rolündeyse rol metni ve seçenekler; izleyiciyse genel metin
static func card(gs) -> Dictionary:
	var p: Dictionary = gs.moment_pending
	if p.is_empty():
		return {}
	var m: Dictionary = p.m
	var out := {"title": String(m.get("title", "")), "scene": String(m.get("scene", "")), "icon": String(m.get("icon", "")), "body": String(m.get("text", "")), "options": []}
	if String(p.role) != "":
		var r: Dictionary = m.roles[p.role]
		out.body = String(r.get("text", out.body))
		for o in r.get("options", []):
			out.options.append({"t": String(o.get("t", "?")), "d": String(o.get("d", "")), "kind": String(o.get("kind", ""))})
	return out
