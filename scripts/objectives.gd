extends RefCounted
## Senaryo/çağ hedefleri, zamanlanmış olaylar ve süre sınırı. Durum gs.scn içinde saklanır (kayda girer):
## {id, start, done:{hedef_id: tur}, fired:{olay_no: true}, streak:{...}, cap:{ülke: eyalet}, src:<senaryo sözlüğü>, over:false}
## Zorunlu hedeflerin hepsi tamamlanınca zafer, süre sınırı dolunca yenilgi (game_over sinyali).

const Loc = preload("res://scripts/loc.gd")
const DataUtil = preload("res://scripts/data_util.gd")
const EraEvents = preload("res://scripts/era_events.gd")
const EraMoments = preload("res://scripts/era_moments.gd")
const Chokepoints = preload("res://scripts/chokepoints.gd")

const STREAK_STAB := 4
const STREAK_PEACE := 4
const HOLD_WEEKS := 52          # oyun başında zaten sağlanan 'elde tut' hedefleri bu kadar hafta sürdürülünce tamamlanır
const HOLD_TYPES := ["own_capital", "own_province", "hold_choke", "stability", "cease_war"]


## Oyun başında çağrılır (oyuncu seçildikten sonra). def: senaryo ya da çağ sözlüğü.
static func begin(gs, def: Dictionary, with_src: bool = true) -> void:
	gs.scn = {"id": String(def.get("id", "")), "start": gs.turn, "done": {}, "fired": {}, "streak": {}, "cap": {}, "over": false}
	if with_src and (def.has("objectives") or def.has("events") or def.has("moments") or def.has("deadline") or def.has("custom") or def.has("cab_events")):
		gs.scn["src"] = def.duplicate(true)
	for o in list(gs):
		if String(o.get("type", "")) == "own_capital":
			var ci: int = int(gs.macro_idx.get(String(o.get("country", "")), -1))
			if ci >= 0:
				gs.scn.cap[String(o.country)] = gs.countries[ci].capital
	_prepare_pre(gs)


## Oyun başında zaten sağlanan hedefler anında zafer vermesin:
## büyüme hedefleri (eyalet/müttefik/GSYH payı) başlangıç değerinin biraz üstüne çıkarılır, 'elde tut' hedefleri 52 hafta sürdürülmelidir.
static func _prepare_pre(gs) -> void:
	gs.scn["pre"] = {}
	if gs.player < 0:
		return
	var pc = gs.countries[gs.player]
	for o in list(gs):
		if not (o is Dictionary) or not is_required(o):
			continue
		var oid: String = String(o.get("id", ""))
		var t: String = String(o.get("type", ""))
		if t == "own_provinces" and pc.prov_owned >= int(o.n):
			var nn: int = pc.prov_owned + maxi(3, int(ceil(pc.prov_owned * 0.2)))
			_bump_text(gs, o, str(int(o.n)), str(nn))
			o["n"] = nn
		elif t == "alliances" and pc.allies.size() >= int(o.n):
			var na: int = pc.allies.size() + 2
			_bump_text(gs, o, str(int(o.n)), str(na))
			o["n"] = na
		elif t == "gdp_share" and _gdp_share(gs) * 100.0 >= float(o.pct):
			var np: int = int(ceil(_gdp_share(gs) * 100.0 * 1.25)) + 1
			_bump_text(gs, o, str(int(o.pct)), str(np))
			o["pct"] = np
		elif t == "cease_war":
			var cj: int = _cid(gs, String(o.get("with", "")))
			if cj >= 0 and not gs.at_war(gs.player, cj):
				gs.scn.pre[oid] = true       # savaş başlamadan 'barışı koru' hedefi: 52 hafta sürdürülür
		elif t == "stability" and pc.stability >= float(o.n):
			gs.scn.pre[oid] = true
		elif HOLD_TYPES.has(t) and _met(gs, o):
			gs.scn.pre[oid] = true
	# _met akış sayaçlarını (cease_war/stability) etkilemiş olabilir: sıfırla
	gs.scn.streak = {}


static func _bump_text(gs, o: Dictionary, old: String, nw: String) -> void:
	o["text"] = String(o.get("text", "")).replace(old, nw)
	var s: Dictionary = src(gs)
	if s.has("en") and (s["en"] as Dictionary).has("objectives"):
		var m: Dictionary = s["en"]["objectives"]
		var id: String = String(o.get("id", ""))
		if m.has(id):
			m[id] = String(m[id]).replace(old, nw)


static func src(gs) -> Dictionary:
	return gs.scn.get("src", {}) if not gs.scn.is_empty() else {}


static func active(gs) -> bool:
	return not gs.scn.is_empty() and not src(gs).is_empty()


## Oyuncunun ülkesine göre hedef listesi
static func list(gs) -> Array:
	var s: Dictionary = src(gs)
	var all = s.get("objectives", {})
	if not (all is Dictionary) or gs.player < 0:
		return []
	var nm: String = gs.countries[gs.player].name_en
	var arr = all.get(nm, all.get("*", []))
	return arr if arr is Array else []


static func text_of(gs, o: Dictionary) -> String:
	var s: Dictionary = src(gs)
	var tr_t: String = String(o.get("text", o.get("id", "")))
	if Loc.lang != "tr" and s.has("en") and (s["en"] as Dictionary).has("objectives"):
		var m: Dictionary = s["en"]["objectives"]
		if m.has(String(o.get("id", ""))):
			return DataUtil.loc_text(tr_t, String(m[String(o.id)]))
	return tr_t


static func is_done(gs, o: Dictionary) -> bool:
	return gs.scn.get("done", {}).has(String(o.get("id", "")))


static func is_required(o: Dictionary) -> bool:
	return bool(o.get("required", true))


static func _prov(gs, key):
	if typeof(key) == TYPE_INT or typeof(key) == TYPE_FLOAT:
		var i: int = int(key)
		return gs.provinces[i] if i >= 0 and i < gs.provinces.size() else null
	for p in gs.provinces:
		if p.name == String(key):
			return p
	return null


static func _cid(gs, name: String) -> int:
	return int(gs.macro_idx.get(name, -1))


## İlerleme metni (ör. "12/30"); belirsizse boş
static func progress(gs, o: Dictionary) -> String:
	if gs.player < 0:
		return ""
	var pc = gs.countries[gs.player]
	if gs.scn.get("pre", {}).has(String(o.get("id", ""))):
		return "%d/%d" % [mini(int(gs.scn.streak.get("hold_" + String(o.get("id", "")), 0)), HOLD_WEEKS), HOLD_WEEKS]
	match String(o.get("type", "")):
		"own_provinces":
			return "%d/%d" % [pc.prov_owned, int(o.n)]
		"alliances":
			return "%d/%d" % [pc.allies.size(), int(o.n)]
		"survive":
			return "%d/%d" % [mini(gs.turn - int(gs.scn.start), int(o.turns)), int(o.turns)]
		"no_war":
			return "%d/%d" % [mini(int(gs.scn.streak.get(String(o.id), 0)), int(o.turns)), int(o.turns)]
		"stability":
			return "%d/%d" % [int(pc.stability), int(o.n)]
		"gdp_share":
			return "%s/%s" % [Loc.pct(int(_gdp_share(gs) * 100.0)), Loc.pct(int(o.pct))]
		"bloc_members":
			return "%d/%d" % [_bloc_size(gs), int(o.n)]
	return ""


static func _gdp_share(gs) -> float:
	var tot := 0.0
	for c in gs.countries:
		if c.alive and not c.is_rebel:
			tot += c.gdp
	return gs.countries[gs.player].gdp / maxf(tot, 1.0)


static func _bloc_size(gs) -> int:
	var b: Dictionary = gs.bloc_get(gs.countries[gs.player].alliance)
	return 0 if b.is_empty() else b.members.size()


static func _met(gs, o: Dictionary) -> bool:
	var pc = gs.countries[gs.player]
	var id: String = String(o.get("id", ""))
	var streak: Dictionary = gs.scn.streak
	match String(o.get("type", "")):
		"own_provinces":
			return pc.prov_owned >= int(o.n)
		"own_province":
			var p = _prov(gs, o.province)
			return p != null and p.owner == gs.player
		"own_capital":
			var pid: int = int(gs.scn.cap.get(String(o.country), -1))
			return pid >= 0 and gs.provinces[pid].owner == gs.player
		"eliminate":
			var ci: int = _cid(gs, String(o.country))
			return ci >= 0 and not gs.countries[ci].alive
		"survive":
			return gs.turn - int(gs.scn.start) >= int(o.turns)
		"cease_war":
			var cj: int = _cid(gs, String(o.get("with", "")))
			var ok: bool = cj >= 0 and not gs.at_war(gs.player, cj)
			streak[id] = (int(streak.get(id, 0)) + 1) if ok else 0
			return int(streak[id]) >= STREAK_PEACE
		"no_war":
			var ok2: bool = pc.enemies.is_empty()
			streak[id] = (int(streak.get(id, 0)) + 1) if ok2 else 0
			return int(streak[id]) >= int(o.turns)
		"alliances":
			return pc.allies.size() >= int(o.n)
		"stability":
			var ok3: bool = pc.stability >= float(o.n)
			streak[id] = (int(streak.get(id, 0)) + 1) if ok3 else 0
			return int(streak[id]) >= STREAK_STAB
		"gdp_share":
			return _gdp_share(gs) * 100.0 >= float(o.pct)
		"bloc_members":
			return _bloc_size(gs) >= int(o.n)
		"hold_choke":
			return Chokepoints.holds(gs, String(o.get("choke", "")), gs.player)
	return false


## Her tur (game_state.weekly) çağrılır.
static func tick(gs) -> void:
	if gs.scn.is_empty() or gs.player < 0 or gs.scn.get("over", false):
		return
	var s: Dictionary = src(gs)
	if s.is_empty():
		return
	# zamanlanmış olaylar
	var evs: Array = s.get("events", [])
	for i in evs.size():
		var e: Dictionary = evs[i]
		if gs.scn.fired.has(i) or gs.turn - int(gs.scn.start) < int(e.get("turn", 0)):
			continue
		gs.scn.fired[i] = true
		for f in e.get("fx", []):
			EraEvents.apply_fx(gs, f)
		var txt: String = String(e.get("t", ""))
		if Loc.lang != "tr" and s.has("en") and (s["en"] as Dictionary).has("events") and (s["en"]["events"] as Dictionary).has(str(i)):
			txt = DataUtil.loc_text(txt, String(s["en"]["events"][str(i)]))
		if txt != "":
			gs.post_news(txt, -1, "event")
	if s.has("moments"):
		EraMoments.scn_tick(gs, s)
	var cu: Array = s.get("custom", [])
	for k in cu.size():
		var ck := "c%d" % k
		var wk: int = int(cu[k].get("week", 0))
		if wk > 0 and not gs.scn.fired.has(ck) and gs.turn - int(gs.scn.start) >= wk:
			gs.scn.fired[ck] = true
			load("res://scripts/scenarios.gd").make_custom(gs, cu[k], k)
	if not gs.countries[gs.player].alive:
		return
	# hedefler
	var objs: Array = list(gs)
	var req_total := 0
	var req_done := 0
	for o in objs:
		var oid: String = String(o.get("id", ""))
		var met_now: bool = false
		if not gs.scn.done.has(oid):
			met_now = _met(gs, o)
			if gs.scn.get("pre", {}).has(oid):
				var hk := "hold_" + oid
				gs.scn.streak[hk] = (int(gs.scn.streak.get(hk, 0)) + 1) if met_now else 0
				met_now = int(gs.scn.streak[hk]) >= HOLD_WEEKS
		if not gs.scn.done.has(oid) and met_now:
			gs.scn.done[oid] = gs.turn
			gs.post_news(Loc.t("Hedef tamamlandı: %s") % text_of(gs, o), -1, "event")
			gs.objective_done.emit(oid)
		if is_required(o):
			req_total += 1
			if gs.scn.done.has(oid):
				req_done += 1
	if req_total > 0 and req_done == req_total and not gs.victory_declared:
		gs.victory_declared = true
		gs.scn.over = true
		gs.game_over.emit(true, Loc.t("Tüm hedefler tamamlandı! Görev başarıyla bitti."))
		return
	var dl: int = int(s.get("deadline", 0))
	if dl > 0 and gs.turn - int(gs.scn.start) >= dl and not gs.victory_declared:
		gs.scn.over = true
		gs.game_over.emit(false, Loc.t("Süre doldu: hedeflere zamanında ulaşılamadı."))
