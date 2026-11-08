extends RefCounted
## Makro yönetim motoru: bütçe, doktrin, ticaret, sanayi, siber savaş, lojistik, askerlik ve silah alımı.
## Oyuncu tek tek birim yönetmez; bütçeyi, doktrini ve alım önceliğini seçer, simülasyon haritaya yansıtır.

const Arsenal = preload("res://scripts/arsenal.gd")
const Chokepoints = preload("res://scripts/chokepoints.gd")
const Politics = preload("res://scripts/politics.gd")
const Crises = preload("res://scripts/crises.gd")
const Carriers = preload("res://scripts/carriers.gd")
const Loc = preload("res://scripts/loc.gd")

const BUDGET_KEYS := ["mil", "ind", "cyber", "logi", "stab", "res"]
const BUDGET_NAMES := {"mil": "Savunma", "ind": "Sanayi", "cyber": "Siber", "logi": "Lojistik", "stab": "İç İstikrar", "res": "Hazine"}
const BUDGET_HINT := {
	"mil": "Maaş, askerlik ve silah alımı",
	"ind": "Gelir ve yerli silah indirimi",
	"cyber": "Siber saldırı ve savunma",
	"logi": "Yabancı toprakta tedarik gücü",
	"stab": "İsyan ve gelir kaybını önler",
	"res": "Doğrudan hazineye girer",
}

# att/def: savaş çarpanları, air: hava gücü etkisi, cyber: siber güç, logi: tedarik toleransı
const DOCTRINES := [
	{"name": "Dengeli Harekât", "att": 1.0, "def": 1.0, "air": 1.0, "cyber": 1.0, "logi": 1.0, "desc": "Her alanda orta düzey; artısı ve eksisi yok."},
	{"name": "Kitlesel Taarruz", "att": 1.12, "def": 0.95, "air": 0.9, "cyber": 0.9, "logi": 0.9, "desc": "Sayıya dayalı saldırı. Taarruz +%12, savunma −%5."},
	{"name": "Derinlemesine Savunma", "att": 0.92, "def": 1.18, "air": 1.0, "cyber": 1.0, "logi": 1.1, "desc": "Savunma +%18, taarruz −%8."},
	{"name": "Hava-Kara Harekâtı", "att": 1.03, "def": 1.0, "air": 1.8, "cyber": 1.0, "logi": 1.0, "desc": "Hava üstünlüğü etkisi neredeyse iki katı."},
	{"name": "Asimetrik Harp", "att": 0.95, "def": 1.12, "air": 0.7, "cyber": 1.3, "logi": 1.3, "desc": "Savunma +%12, tedarik toleransı yüksek, siber +%30."},
	{"name": "Ağ Merkezli Harp", "att": 1.04, "def": 1.0, "air": 1.2, "cyber": 1.6, "logi": 1.1, "desc": "Siber güç +%60, komuta ağı avantajı."},
]
const DOCTRINE_COOLDOWN := 26

const PRESETS := {
	"peace": {"mil": 18, "ind": 30, "cyber": 8, "logi": 12, "stab": 17, "res": 15},
	"war": {"mil": 38, "ind": 18, "cyber": 12, "logi": 17, "stab": 10, "res": 5},
	"hawk": {"mil": 28, "ind": 24, "cyber": 12, "logi": 14, "stab": 12, "res": 10},
	"poor": {"mil": 22, "ind": 22, "cyber": 4, "logi": 10, "stab": 30, "res": 12},
}

static var _mil: Dictionary = {}
static var _leaders: Dictionary = {}
static var era_on := false              # tarihî dönem modu: asker/silah verisi era_mil'den gelir
static var era_mil: Dictionary = {}     # name_en -> {personnel, tank, afv, arty, air, sub}
static var _loaded := false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var f := FileAccess.open("res://data/military.json", FileAccess.READ)
	if f == null:
		return
	var j = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(j) == TYPE_DICTIONARY and j.has("countries"):
		_mil = j["countries"]
	var lf := FileAccess.open("res://data/leaders.json", FileAccess.READ)
	if lf != null:
		var lj = JSON.parse_string(lf.get_as_text())
		lf.close()
		if typeof(lj) == TYPE_DICTIONARY and lj.has("leaders"):
			_leaders = lj["leaders"]


## Lider "Unvan|İsim" biçiminde saklanır (yalnızca metin; fotoğraf yok).
static func leader_of(c) -> Array:
	if c.leader == "" and not era_on:
		_load()
		var e: Dictionary = _leaders.get(c.name_en, {})
		if not e.is_empty():
			c.leader = "%s|%s" % [e["t"], e["n"]]
	var parts: PackedStringArray = c.leader.split("|")
	if parts.size() < 2:
		return ["", ""]
	return [parts[0], parts[1]]


# ===================================================================== biçimlendirme

static func _dec(x: float) -> String:
	if x >= 100.0:
		return str(int(x))
	return ("%.1f" % x).replace(".", Loc.dec)


static func money(m: float) -> String:
	var a := absf(m)
	var s := "-" if m < 0.0 else ""
	if a >= 1.0e6:
		return "%s$%s%s" % [s, _dec(a / 1.0e6), Loc.units["tr"]]
	if a >= 1000.0:
		return "%s$%s%s" % [s, _dec(a / 1000.0), Loc.units["mr"]]
	return "%s$%d%s" % [s, int(a), Loc.units["mn"]]


static func num(n: float) -> String:
	var v: int = int(round(n))
	var s: String = str(absi(v))
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = Loc.thou + out
	return ("-" if v < 0 else "") + out


## "425.000"; harita bandında kısa: "425K", "2,0M"
static func troops(n: float) -> String:
	return num(n)


static func compact(n: float) -> String:
	if n >= 1.0e6:
		return ("%.1fM" % (n / 1.0e6)).replace(".", Loc.dec)
	if n >= 10000.0:
		return "%dK" % int(round(n / 1000.0))
	if n >= 1000.0:
		return ("%.1fK" % (n / 1000.0)).replace(".", Loc.dec)
	return str(int(n))


# ===================================================================== kurulum

static func tier_weights(tech: float) -> Array:
	var w: Array = []
	var tot := 0.0
	for t in 4:
		var x: float = exp(-pow(float(t) / 3.0 - tech, 2.0) / 0.14)
		w.append(x)
		tot += x
	for t in 4:
		w[t] = w[t] / tot
	return w


## Haritadaki sahra ordusu: kayıtlı personelin (yedek, jandarma, destek) yalnızca bu kadarı savaşabilir birliktir.
## Gerçek personel sayıları olduğu gibi kullanılır (eskiden %60'ı sahaya çıkıyordu; Türkiye 255 bin görünüyordu).
## Maliyet dengesi bozulmasın diye modern çağda maaş buna göre ölçeklenir (WAGE_COMP).
const FIELD_RATIO := 1.0
const WAGE_COMP := 0.6

static func init_country(gs, c) -> void:
	_load()
	var gdp_pc: float = c.gdp / maxf(c.pop, 0.01)
	c.capacity = pow(clampf(gdp_pc / (12000.0 if era_on else 60000.0), 0.08, 1.0), 0.6)
	var tech_def: float = clampf(sqrt(clampf((gdp_pc - 1500.0) / 50000.0, 0.0, 1.0)), 0.05, 1.0)
	if era_on:
		tech_def = clampf(0.08 + 0.35 * sqrt(clampf(gdp_pc / 12000.0, 0.0, 1.0)), 0.08, 0.5)
	c.tech = Arsenal.TECH_OVR.get(c.name_en, tech_def)
	if c.tech_set >= 0.0:
		c.tech = c.tech_set
	c.bloc = Arsenal.bloc_for(c.name_en, c.a3, c.continent, c.tech)
	var d: Dictionary = era_mil.get(c.name_en, {}) if era_on else _mil.get(c.name_en, {})
	var pers: int
	if c.base_troops > 0:
		pers = c.base_troops
	elif d.has("personnel"):
		pers = int(d["personnel"] * (1.0 if era_on else FIELD_RATIO))
	else:
		if era_on:
			pers = int(clampf(c.pop * 1.0e6 * 0.007 * (0.7 + c.tech), 3000.0, 1500000.0))
		else:
			pers = int(clampf(c.pop * 1.0e6 * 0.0022 * (0.6 + c.tech * 0.8) * FIELD_RATIO, 2500.0, 300000.0))
	c.base_troops = pers
	var kt: float = pers / 1000.0
	var k_t: float = 0.5 + c.tech
	var counts: Dictionary
	if era_on:
		var w1: bool = Arsenal.key == "ww1"
		counts = {
			"inf": kt,
			"tank": float(d["tank"]) if d.has("tank") else (0.0 if w1 else kt * 0.5 * k_t),
			"afv": float(d["afv"]) if d.has("afv") else kt * (0.2 if w1 else 0.8) * k_t,
			"arty": float(d["arty"]) if d.has("arty") else kt * (3.0 if w1 else 3.5),
			"air": float(d["air"]) if d.has("air") else kt * (0.15 if w1 else 0.9) * k_t,
			"sub": float(d["sub"]) if d.has("sub") else 0.0,
		}
	else:
		counts = {
			"inf": kt,
			"tank": float(d["tank"]) if d.has("tank") else kt * 3.0 * k_t,
			"afv": float(d["afv"]) if d.has("afv") else kt * 7.0 * k_t,
			"arty": float(d["arty"]) if d.has("arty") else kt * 2.2 * k_t,
			"air": float(d["air"]) if d.has("air") else kt * 1.4 * (0.4 + c.tech),
			"sub": float(d["sub"]) if d.has("sub") else (float(int(pers / 90000.0)) if (pers > 60000 and c.tech > 0.35) else 0.0),
		}
	c.inv = {}
	var w: Array = tier_weights(c.tech)
	for cat in Arsenal.CATS:
		var ids: Array = Arsenal.family(c.name_en, cat, c.bloc)
		for t in 4:
			var n: int = int(round(counts[cat] * w[t]))
			var iid: String = ids[t]
			var tt := t
			while Arsenal.NEW_ITEMS.has(iid) and tt > 0:
				tt -= 1
				iid = ids[tt]
			if n > 0:
				c.inv[iid] = int(c.inv.get(iid, 0)) + n
	c.orders = []
	c.industry = clampf(30.0 + c.tech * 45.0 + c.capacity * 20.0, 15.0, 95.0)
	c.cyber = clampf(8.0 + c.tech * 55.0 + (20.0 if c.name_en in ["Russia", "China", "United States of America", "Israel", "North Korea", "Iran"] else 0.0), 5.0, 95.0)
	c.logistics = clampf(30.0 + c.tech * 40.0 + c.capacity * 20.0, 15.0, 95.0)
	c.stability = clampf(55.0 + c.capacity * 25.0 + gs.rng.randf_range(-8.0, 8.0), 25.0, 95.0)
	c.budget = (PRESETS["poor"] if c.capacity < 0.22 else PRESETS["peace"]).duplicate()
	if c.aggression > 0.65:
		c.budget = PRESETS["hawk"].duplicate()
	# doktrin
	if c.tech > 0.75:
		c.doctrine = 3 if gs.rng.randf() < 0.6 else 5
	elif c.aggression > 0.65:
		c.doctrine = 1
	elif c.capacity < 0.25:
		c.doctrine = 4
	else:
		c.doctrine = [0, 0, 2, 3][gs.rng.randi_range(0, 3)]
	c.doctrine_turn = -99
	c.fund = 0.0
	recalc(c)


static func ensure(gs, c) -> void:
	if c.inv.is_empty():
		init_country(gs, c)
	if c.carriers < 0:
		c.carriers = Carriers.start_count(c)


## envanterden türetilen savaş gücü göstergeleri
static func recalc(c) -> void:
	var kt: float = maxf(float(maxi(c.troops, int(c.base_troops * 0.6))), 3000.0) / 1000.0
	var sums: Dictionary = {}
	var infn := 0.0
	var infw := 0.0
	var val := 0.0
	for id in c.inv:
		var n: float = c.inv[id]
		if n <= 0.0 or not Arsenal.ITEMS.has(id):
			continue
		var cat: String = Arsenal.cat_of(id)
		var pw: float = Arsenal.power_of(id)
		sums[cat] = float(sums.get(cat, 0.0)) + n * pw
		val += n * Arsenal.cost_of(id)
		if cat == "inf":
			infn += n
			infw += n * pw
	c.equip_value = val
	var r_tank: float = clampf(float(sums.get("tank", 0.0)) / (kt * Arsenal.CAT_REF["tank"]), 0.0, 1.3)
	var r_afv: float = clampf(float(sums.get("afv", 0.0)) / (kt * Arsenal.CAT_REF["afv"]), 0.0, 1.3)
	var r_arty: float = clampf(float(sums.get("arty", 0.0)) / (kt * Arsenal.CAT_REF["arty"]), 0.0, 1.3)
	var infq: float = infw / infn if infn > 0.0 else 1.0
	var cov: float = clampf(infn / kt, 0.0, 1.0)
	var land: float = 0.45 * r_tank + 0.30 * r_afv + 0.25 * r_arty
	c.eq_land = (0.72 + 0.5 * land) * (0.93 + 0.05 * (infq - 1.0)) * (0.9 + 0.1 * cov)
	c.air_pow = float(sums.get("air", 0.0))
	c.naval_pow = float(sums.get("sub", 0.0)) + 0.8 * maxi(c.carriers, 0)
	c.ratios = {
		"inf": clampf(0.5 * cov + 0.5 * clampf((infq - 1.0) / 1.2, 0.0, 1.0), 0.0, 1.3),
		"tank": r_tank, "afv": r_afv, "arty": r_arty,
		"air": clampf(c.air_pow / (kt * 6.0), 0.0, 1.3),
		"sub": clampf(c.naval_pow / (kt * 0.12), 0.0, 1.3),
	}


static func build_idx(gs) -> void:
	gs.macro_idx = {}
	for c in gs.countries:
		if c.name_en != "" and not c.is_rebel:
			gs.macro_idx[c.name_en] = c.id


static func build_trade(gs) -> void:
	var rich: Array = []
	for c in gs.countries:
		if c.alive and not c.is_rebel:
			rich.append(c)
	rich.sort_custom(func(a, b): return a.gdp > b.gdp)
	for c in rich:
		var w: Dictionary = {}
		var nbs: Dictionary = {}
		for pid in c.owned_ids:
			for nb in gs.provinces[pid].neighbors:
				var o: int = gs.provinces[nb].owner
				if o != c.id and o >= 0:
					nbs[o] = true
			for sl in gs.provinces[pid].sea_links:
				var o2: int = gs.provinces[sl].owner
				if o2 != c.id and o2 >= 0:
					nbs[o2] = true
		for o3 in nbs:
			if not gs.countries[o3].is_rebel:
				w[o3] = sqrt(maxf(gs.countries[o3].gdp, 1.0)) * 1.8
		var hubs := 0
		for h in rich:
			if hubs >= 6:
				break
			if h.id == c.id:
				continue
			w[h.id] = float(w.get(h.id, 0.0)) + sqrt(maxf(h.gdp, 1.0)) * 0.3
			hubs += 1
		var arr: Array = []
		var tot := 0.0
		for k in w:
			arr.append([k, w[k]])
			tot += w[k]
		arr.sort_custom(func(a, b): return a[1] > b[1])
		if arr.size() > 14:
			arr.resize(14)
			tot = 0.0
			for e in arr:
				tot += e[1]
		for e in arr:
			e[1] = e[1] / maxf(tot, 1.0)
		c.partners = arr


static func prime(gs) -> void:
	if gs.macro_idx.is_empty():
		build_idx(gs)
	build_trade(gs)
	for c in gs.countries:
		if not c.alive or c.is_rebel:
			continue
		ensure(gs, c)
		_trade(gs, c)
		recalc(c)
		c.fin = calc(gs, c)
		c.gold_delta = c.fin["net"]


static func trade_open(gs, c, j: int) -> bool:
	var o = gs.countries[j]
	return o.alive and not c.enemies.has(j) and not c.embargo.has(j) and not o.embargo.has(c.id) and o.trade_block <= 0


static func stance(c, enemy: int) -> String:
	if c.fronts.has(enemy):
		return c.fronts[enemy].get("stance", "attack")
	return "attack"


static func cyber_focus(c, enemy: int) -> String:
	if c.fronts.has(enemy):
		return c.fronts[enemy].get("cyber", "auto")
	return "auto"


static func set_front(c, enemy: int, key: String, val: String) -> void:
	if not c.fronts.has(enemy):
		c.fronts[enemy] = {"stance": "attack", "cyber": "auto"}
	c.fronts[enemy][key] = val


# ===================================================================== bütçe / doktrin

static func set_budget(c, key: String, val: int) -> void:
	val = clampi(val, 0, 70)
	var others: Array = []
	var sum_o := 0
	for k in BUDGET_KEYS:
		if k != key:
			others.append(k)
			sum_o += int(c.budget[k])
	var remain: int = 100 - val
	c.budget[key] = val
	if sum_o <= 0:
		for k in others:
			c.budget[k] = remain / others.size()
	else:
		var acc := 0
		var big: String = others[0]
		for k in others:
			var nv: int = int(round(float(c.budget[k]) * remain / sum_o))
			c.budget[k] = nv
			acc += nv
			if nv > int(c.budget[big]):
				big = k
		c.budget[big] = int(c.budget[big]) + (remain - acc)
	for k in BUDGET_KEYS:
		c.budget[k] = maxi(0, int(c.budget[k]))


static func doctrine_cost(gs, c) -> float:
	return maxf(c.income, 1.0) * 0.6


static func set_doctrine(gs, c, idx: int) -> String:
	if idx == c.doctrine:
		return ""
	if gs.turn - c.doctrine_turn < DOCTRINE_COOLDOWN:
		return "Doktrin değişikliği için %d hafta beklemelisin." % (DOCTRINE_COOLDOWN - (gs.turn - c.doctrine_turn))
	var cost: float = doctrine_cost(gs, c)
	if c.gold < cost:
		return "Doktrin değişimi %s tutuyor; hazinede yeterli para yok." % money(cost)
	c.gold -= cost
	c.doctrine = idx
	c.doctrine_turn = gs.turn
	return ""


static func ai_policy(gs, c) -> void:
	if c.id == gs.player or c.is_rebel:
		return
	var key := "peace"
	if not c.enemies.is_empty():
		key = "war"
	elif c.aggression > 0.65:
		key = "hawk"
	elif c.capacity < 0.22:
		key = "poor"
	if c.gold < c.income * 2.0:
		key = "peace"
	c.budget = PRESETS[key].duplicate()


# ===================================================================== mali tablo

static func wage_week(c) -> float:
	if era_on:
		return 3.0 + 25.0 * pow(clampf(c.gdp / maxf(c.pop, 0.01) / 12000.0, 0.0, 1.0), 0.9)
	return (12.0 + 400.0 * pow(clampf(c.gdp / maxf(c.pop, 0.01) / 60000.0, 0.0, 1.0), 0.9)) * WAGE_COMP


static func calc(gs, c) -> Dictionary:
	var base: float = c.income
	var ind_f: float = 0.85 + 0.30 * c.industry / 100.0
	var stab_f: float = 0.8 + 0.2 * c.stability / 100.0
	var rev: float = (base * ind_f + c.trade_income) * stab_f
	if gs.turn < c.sanction_until:
		rev *= 0.75
	rev *= Crises.income_mult(gs, c)
	rev *= Chokepoints.income_mult(c)
	rev *= Politics.income_mult(gs, c)
	if c.id != gs.player:
		rev *= [0.85, 1.0, 1.2][clampi(gs.difficulty, 0, 2)]
	var wages: float = c.troops * wage_week(c) * 1.0e-6
	var upkeep: float = c.equip_value * 0.0015 + Carriers.upkeep(c)
	var pots: Dictionary = {}
	for k in BUDGET_KEYS:
		pots[k] = rev * float(c.budget[k]) / 100.0
	var forced: float = wages + upkeep
	var fund_in: float = maxf(0.0, pots["mil"] - forced)
	var need: float = maxf(0.0, forced - pots["mil"])
	var covered := 0.0
	if need > 0.0:
		# ordu masrafı savunma fonunu aşıyorsa diğer kalemlerden (önce hazine, sanayi…) kesilir
		for k in ["res", "ind", "logi", "cyber", "stab"]:
			var take: float = minf(pots[k], need)
			pots[k] -= take
			need -= take
			covered += take
	var short: float = need
	return {"rev": rev, "wages": wages, "upkeep": upkeep, "pots": pots, "forced": forced,
		"fund_in": fund_in, "short": short, "covered": covered, "net": pots["res"] - short, "trade": c.trade_income}


static func net_income(gs, c) -> float:
	if c.fin.is_empty():
		return calc(gs, c)["net"]
	return c.fin.get("net", 0.0)


# ===================================================================== haftalık işlemler

static func weekly(gs) -> void:
	if gs.macro_idx.is_empty():
		build_idx(gs)
	if gs.turn % 26 == 1:
		build_trade(gs)
	for c in gs.countries:
		if not c.alive:
			continue
		if c.is_rebel:
			_rebel_week(gs, c)
			continue
		ensure(gs, c)
		if c.trade_block > 0:
			c.trade_block -= 1
		var slot: int = gs.turn + c.id
		if slot % 4 == 0 or c.id == gs.player:
			_trade(gs, c)
		if slot % 2 == 0 or c.id == gs.player or not c.enemies.is_empty():
			recalc(c)
		var f: Dictionary = calc(gs, c)
		c.fin = f
		c.gold += f["pots"]["res"] - f["short"]
		c.fund += f["fund_in"]
		_invest(gs, c, f)
		c.gold_delta = f["net"]
		if c.gold < 0.0:
			for a in gs.armies_of(c.id):
				a.size = maxi(100, int(a.size * 0.97))
			c.stability = maxf(5.0, c.stability - 1.0)
			c.gold = 0.0
		_deliver(gs, c)
		if slot % 2 == 0:
			_recruit(gs, c, 2.0)
		if slot % 3 == 0:
			_procure(gs, c, 3)
		if c.id != gs.player and (gs.turn + c.id) % 8 == 0:
			ai_policy(gs, c)
	_blockades(gs)
	_war_ops(gs)


static func _trade(gs, c) -> void:
	var share := 0.0
	for e in c.partners:
		if trade_open(gs, c, e[0]):
			share += e[1]
	c.trade_share = share
	c.trade_income = 0.10 * c.income * share * (1.0 - c.blockade)


static func _invest(gs, c, f: Dictionary) -> void:
	var inc: float = maxf(c.income, 1.0)
	var pots: Dictionary = f["pots"]
	c.industry = _grow(c.industry, pots["ind"] / (inc * 0.25), 0.35, 0.18)
	c.cyber = _grow(c.cyber, pots["cyber"] / (inc * 0.10), 0.30, 0.12)
	c.logistics = _grow(c.logistics, pots["logi"] / (inc * 0.15), 0.30, 0.12)
	var war_pen: float = 0.12 if not c.enemies.is_empty() else 0.0
	c.stability = _grow(c.stability, pots["stab"] / (inc * 0.15), 0.35, 0.15 + war_pen)
	if c.stability < 25.0 and gs.rng.randf() < 0.05 and not c.owned_ids.is_empty():
		var p = gs.provinces[c.owned_ids[gs.rng.randi_range(0, c.owned_ids.size() - 1)]]
		if not p.is_capital and p.controller == p.owner:
			p.unrest += 3


static func _grow(x: float, ratio: float, gain: float, decay: float) -> float:
	var d: float = clampf(ratio, 0.0, 2.2) * gain - decay
	if d > 0.0:
		d *= (1.0 - x / 110.0)
	return clampf(x + d, 3.0, 100.0)


static func _blockades(gs) -> void:
	for c in gs.countries:
		c.blockade = 0.0
	for w in gs.wars:
		var a = gs.countries[w.a]
		var b = gs.countries[w.b]
		if not a.alive or not b.alive:
			continue
		var ra: float = a.naval_pow / (a.naval_pow + b.naval_pow + 0.5)
		var rb: float = 1.0 - ra
		b.blockade = minf(0.8, b.blockade + 0.5 * ra * minf(1.0, a.naval_pow / 6.0))
		a.blockade = minf(0.8, a.blockade + 0.5 * rb * minf(1.0, b.naval_pow / 6.0))


# ===================================================================== askerlik

static func recruit_cost(c) -> float:
	return 0.0015 + 0.02 * c.capacity


static func troop_goal(c) -> float:
	var g: float = c.base_troops * (0.75 + float(c.budget["mil"]) / 100.0)
	if not c.enemies.is_empty():
		g *= 1.35
	return minf(g, c.pop * 1.0e6 * 0.03)


static func _recruit(gs, c, mult: float) -> void:
	var goal: float = troop_goal(c)
	if c.troops >= goal or c.fund <= 0.0:
		return
	var unit: float = recruit_cost(c)
	var maxn: int = int(goal * 0.012 * mult)
	var n: int = mini(int(goal - c.troops), mini(maxn, int(c.fund * 0.45 / unit)))
	if n < 200:
		return
	c.fund -= n * unit
	gs.place_recruits(c, n)


# ===================================================================== silah alımı

static func tier_cap(c) -> int:
	return 4 if c.tech >= 0.3 else 3


static func origin_id(gs, id: String) -> int:
	return int(gs.macro_idx.get(Arsenal.origin_of(id), -1))


## "" = alınabilir; aksi halde nedeni
static func availability(gs, c, id: String) -> String:
	if not Arsenal.ITEMS.has(id) or not Arsenal.buyable(id):
		return "Satışta değil"
	var t: int = Arsenal.tier_of(id)
	var own: bool = Arsenal.origin_of(id) == c.name_en
	if Arsenal.GATE.has(id) and gs.turn < int(Arsenal.GATE[id]):
		return "Henüz geliştirilmedi (%d. haftada)" % int(Arsenal.GATE[id])
	if not own:
		if t > tier_cap(c):
			return "Teknoloji düzeyin yetersiz"
		if t >= 3 and c.industry < (t - 2) * 20.0:
			return "Sanayi altyapısı yetersiz (%%%d gerekli)" % int((t - 2) * 20)
		var oid: int = origin_id(gs, id)
		if oid >= 0:
			var o = gs.countries[oid]
			if not o.alive:
				return "Üretici ülke yok"
			if c.enemies.has(oid) or c.embargo.has(oid) or o.embargo.has(c.id):
				return "%s satmıyor (savaş/ambargo)" % o.name
	return ""


static func price(c, id: String) -> float:
	var p: float = Arsenal.cost_of(id)
	if Arsenal.origin_of(id) == c.name_en:
		p *= 1.0 - 0.25 * c.industry / 100.0
	return p


static func lead_time(c, id: String) -> int:
	var l: int = 3 + Arsenal.tier_of(id) * 2
	if Arsenal.origin_of(id) == c.name_en:
		l -= 3
	return maxi(2, l)


static func available_funds(c) -> float:
	return c.fund + c.gold


static func buy(gs, c, id: String, qty: int) -> String:
	ensure(gs, c)
	var why: String = availability(gs, c, id)
	if why != "":
		return why
	var cost: float = price(c, id) * qty
	if available_funds(c) < cost:
		return "Yetersiz bütçe: %s gerekiyor." % money(cost)
	var from_fund: float = minf(c.fund, cost)
	c.fund -= from_fund
	c.gold -= cost - from_fund
	c.orders.append({"id": id, "qty": qty, "due": gs.turn + lead_time(c, id)})
	return ""


static func _deliver(gs, c) -> void:
	if c.orders.is_empty():
		return
	var keep: Array = []
	for o in c.orders:
		if o["due"] > gs.turn:
			keep.append(o)
			continue
		var id: String = o["id"]
		var qty: int = o["qty"]
		c.inv[id] = int(c.inv.get(id, 0)) + qty
		_retire(c, id, qty)
		if c.id == gs.player:
			gs.post_news("Teslimat: %d × %s envantere katıldı." % [qty, Arsenal.name_of(id)], c.capital, "arms")
	c.orders = keep
	recalc(c)


## yeni silah gelince en eski nesil kısmen emekli edilir
static func _retire(c, new_id: String, qty: int) -> void:
	var cat: String = Arsenal.cat_of(new_id)
	var nt: int = Arsenal.tier_of(new_id)
	var frac: float = 1.0 if cat == "inf" else (0.6 if cat == "air" else 0.4)
	var left: int = int(qty * frac)
	while left > 0:
		var worst := ""
		var wt := 99
		for id in c.inv:
			if id == new_id or int(c.inv[id]) <= 0 or not Arsenal.ITEMS.has(id) or Arsenal.cat_of(id) != cat:
				continue
			var t: int = Arsenal.tier_of(id)
			if t < nt and t < wt:
				wt = t
				worst = id
		if worst == "":
			return
		var take: int = mini(left, int(c.inv[worst]))
		c.inv[worst] = int(c.inv[worst]) - take
		left -= take


static func _pick_cat(gs, c) -> String:
	var wsum := 0.0
	var ws: Dictionary = {}
	for cat in Arsenal.CATS:
		var need: float = maxf(0.05, 1.3 - float(c.ratios.get(cat, 0.0)))
		var pr: float = float(c.pri.get(cat, 1.0))
		if cat == "air":
			pr *= 1.0 + 0.4 * (DOCTRINES[c.doctrine]["air"] - 1.0)
		if cat == "sub" and c.naval_pow <= 0.0 and c.tech < 0.5:
			pr *= 0.2
		ws[cat] = need * pr
		wsum += ws[cat]
	var r: float = gs.rng.randf() * wsum
	for cat in Arsenal.CATS:
		r -= ws[cat]
		if r <= 0.0:
			return cat
	return "tank"


static func _pick_item(gs, c, cat: String, budget: float) -> String:
	var best: Array = []
	var top_t := 0
	var lst: Array = Arsenal.list_cat(cat)
	for k in range(lst.size() - 1, -1, -1):
		var id: String = lst[k]
		var t: int = Arsenal.tier_of(id)
		if t < top_t:
			break
		if availability(gs, c, id) != "" or price(c, id) > budget:
			continue
		top_t = t
		best.append(id)
	if best.is_empty():
		return ""
	return best[gs.rng.randi_range(0, best.size() - 1)]


static func _procure(gs, c, mult: int) -> void:
	if c.id == gs.player and not c.auto_buy:
		return
	var tries := 0
	var qcap: float = clampf(c.income / 1500.0, 1.0, 40.0) * mult
	while c.fund > 8.0 and tries < 3:
		tries += 1
		var cat: String = _pick_cat(gs, c)
		var id: String = _pick_item(gs, c, cat, c.fund * 0.6)
		if id == "":
			continue
		var pr: float = price(c, id)
		var step: int = int(Arsenal.CAT_STEP[cat])
		var qty: int = clampi(int(c.fund * 0.5 / pr), 1, int(step * 2 * qcap))
		c.fund -= pr * qty
		c.orders.append({"id": id, "qty": qty, "due": gs.turn + lead_time(c, id)})


static func attrition(gs, cid: int, lost: int, before: int) -> void:
	if before <= 0 or lost <= 0:
		return
	var c = gs.countries[cid]
	var frac: float = clampf(float(lost) / maxf(float(c.troops), float(before)), 0.0, 1.0) * 0.5
	if frac < 0.0005:
		return
	for id in c.inv.keys():
		if not Arsenal.ITEMS.has(id) or Arsenal.cat_of(id) == "inf":
			continue
		c.inv[id] = int(int(c.inv[id]) * (1.0 - frac))


# ===================================================================== savaş çarpanları

static func battle_mult(gs, me_id: int, foe_id: int, attacking: bool, prov) -> float:
	var me = gs.countries[me_id]
	var foe = gs.countries[foe_id]
	if me.is_rebel:
		return 0.9
	var dm: Dictionary = DOCTRINES[me.doctrine]
	var m: float = me.eq_land * (dm["att"] if attacking else dm["def"])
	var a: float = me.air_pow * dm["air"]
	var b: float = foe.air_pow * (DOCTRINES[foe.doctrine]["air"] if not foe.is_rebel else 1.0)
	var share: float = (a - b) / (a + b + 1.0)
	m *= 1.0 + 0.22 * share * minf(1.0, (a + b) / 150.0)
	if attacking and prov.controller != me_id:
		m *= minf(1.0, 0.78 + 0.22 * clampf(me.logistics / 100.0 * dm["logi"], 0.0, 1.2))
	m *= 0.9 + 0.1 * me.stability / 100.0
	return m


static func power(gs, c) -> float:
	return (c.troops * c.eq_land + c.air_pow * 60.0 + c.naval_pow * 300.0) / 1000.0 + c.income * 0.01


# ===================================================================== siber ve hava harekâtı

const CYBER_TARGETS := ["industry", "logistics", "trade", "finance"]
const CYBER_NAMES := {"auto": "Otomatik", "industry": "Sanayi", "logistics": "Lojistik", "trade": "Ticaret", "finance": "Finans", "off": "Kapalı"}


static func _war_ops(gs) -> void:
	for w in gs.wars:
		var a = gs.countries[w.a]
		var b = gs.countries[w.b]
		if not a.alive or not b.alive:
			continue
		_cyber_op(gs, a, b)
		_cyber_op(gs, b, a)
		_air_op(gs, a, b)
		_air_op(gs, b, a)
	for pr in gs.cold:
		var ca = gs.countries[pr[0]]
		var cb = gs.countries[pr[1]]
		if not ca.alive or not cb.alive or gs.at_war(ca.id, cb.id):
			continue
		if gs.rng.randf() < 0.5:
			_cyber_op(gs, ca, cb)
		if gs.rng.randf() < 0.5:
			_cyber_op(gs, cb, ca)


static func _cyber_op(gs, atk, dfn) -> void:
	if era_on:
		return
	if atk.is_rebel or dfn.is_rebel:
		return
	var focus: String = cyber_focus(atk, dfn.id) if atk.id == gs.player else "auto"
	if focus == "off":
		return
	if gs.rng.randf() > 0.30:
		return
	var ac: float = atk.cyber * DOCTRINES[atk.doctrine]["cyber"]
	var dc: float = dfn.cyber * DOCTRINES[dfn.doctrine]["cyber"] * 1.1
	var p_ok: float = ac / (ac + dc + 10.0)
	var tgt: String = focus
	if tgt == "auto":
		tgt = CYBER_TARGETS[gs.rng.randi_range(0, 3)]
	var involved: bool = atk.id == gs.player or dfn.id == gs.player
	if gs.rng.randf() > p_ok:
		if involved and gs.rng.randf() < 0.5:
			if dfn.id == gs.player:
				gs.post_news("Siber savunma: %s kaynaklı saldırı engellendi." % atk.name, -1, "cyber")
			else:
				gs.post_news("%s siber güvenlik duvarın bir saldırıyı püskürttü." % dfn.name, -1, "cyber")
		return
	var s: float = clampf(p_ok * 1.6, 0.3, 1.0)
	var txt := ""
	match tgt:
		"industry":
			dfn.industry = maxf(3.0, dfn.industry - 5.0 * s)
			txt = "%s kaynaklı fidye yazılımı %s fabrikalarını durdurdu." % [atk.name, dfn.name]
		"logistics":
			dfn.logistics = maxf(3.0, dfn.logistics - 5.0 * s)
			txt = "%s, %s demiryolu ve liman sinyalizasyonunu çökertti; tedarik hatları aksıyor." % [atk.name, dfn.name]
		"trade":
			dfn.trade_block = maxi(dfn.trade_block, 3)
			txt = "%s siber saldırısı: %s liman ve borsa bağlantıları kesildi, dış ticaret duruyor." % [atk.name, dfn.name]
		_:
			var loot: float = minf(dfn.gold * 0.05, maxf(dfn.income, 1.0) * 0.4) * s
			dfn.gold -= loot
			atk.gold += loot * 0.7
			txt = "%s, %s bankalarından %s çaldı." % [atk.name, dfn.name, money(loot * 0.7)]
	if involved or gs.rng.randf() < 0.12:
		gs.post_news(txt, dfn.capital, "cyber")


static func _air_op(gs, atk, dfn) -> void:
	if atk.air_pow < 8.0 or gs.rng.randf() > 0.22:
		return
	var a: float = atk.air_pow * DOCTRINES[atk.doctrine]["air"]
	var b: float = dfn.air_pow * (DOCTRINES[dfn.doctrine]["air"] if not dfn.is_rebel else 1.0)
	var p_ok: float = a / (a + b * 1.2 + 5.0)
	if gs.rng.randf() > p_ok:
		return
	var s: float = clampf(p_ok * minf(1.0, a / 80.0) * 1.4, 0.15, 1.0)
	var kind: int = gs.rng.randi_range(0, 2)
	var txt := ""
	match kind:
		0:
			dfn.industry = maxf(3.0, dfn.industry - 4.0 * s)
			txt = "%s hava harekâtı: %s sanayi tesisleri vuruldu." % [atk.name, dfn.name]
		1:
			dfn.logistics = maxf(3.0, dfn.logistics - 4.0 * s)
			txt = "%s uçakları %s lojistik hatlarını ve köprüleri vurdu." % [atk.name, dfn.name]
		_:
			attrition(gs, dfn.id, int(dfn.troops * 0.02 * s), dfn.troops)
			txt = "%s, %s cephane depolarını ve araç parklarını bombaladı." % [atk.name, dfn.name]
	if atk.id == gs.player or dfn.id == gs.player or gs.rng.randf() < 0.1:
		gs.post_news(txt, dfn.capital, "ops")


static func _rebel_week(gs, c) -> void:
	c.gold += c.income * 0.4
	if c.troops < 40000 and c.gold > 60.0 and not c.held_ids.is_empty() and gs.rng.randf() < 0.5:
		c.gold -= 40.0
		gs.place_recruits(c, 1500)


# ===================================================================== arayüz yardımcıları

static func inventory_rows(c) -> Array:
	var rows: Array = []
	for cat in Arsenal.CATS:
		var items: Array = []
		var tot := 0
		for id in c.inv:
			if int(c.inv[id]) > 0 and Arsenal.ITEMS.has(id) and Arsenal.cat_of(id) == cat:
				items.append(id)
				tot += int(c.inv[id])
		items.sort_custom(func(a, b): return Arsenal.tier_of(a) > Arsenal.tier_of(b))
		rows.append({"cat": cat, "total": tot, "items": items})
	return rows


static func cat_total(c, cat: String) -> int:
	var tot := 0
	for id in c.inv:
		if Arsenal.ITEMS.has(id) and Arsenal.cat_of(id) == cat:
			tot += int(c.inv[id])
	return tot


## macro durumunu kayıt için sözlüğe çevirir
static func to_dict(c) -> Dictionary:
	return {"budget": c.budget, "doctrine": c.doctrine, "dturn": c.doctrine_turn, "industry": c.industry, "cyber": c.cyber,
		"logistics": c.logistics, "stability": c.stability, "capacity": c.capacity, "tech": c.tech, "bloc": c.bloc,
		"inv": c.inv, "orders": c.orders, "auto_buy": c.auto_buy, "auto_cmd": c.auto_cmd, "pri": c.pri, "base": c.base_troops,
		"fund": c.fund, "embargo": c.embargo, "fronts": c.fronts, "tblock": c.trade_block, "alliance": c.alliance, "leader": c.leader, "carriers": c.carriers, "car_x": c.carrier_extra, "car_cd": c.carrier_cd, "covert": c.covert_cd, "cab": c.cab, "elect": c.elect_turn}


static func from_dict(c, d: Dictionary) -> void:
	c.budget = d.get("budget", c.budget).duplicate()
	c.doctrine = d.get("doctrine", 0)
	c.carriers = int(d.get("carriers", -1))
	c.carrier_extra = int(d.get("car_x", 0))
	c.carrier_cd = int(d.get("car_cd", -1))
	c.doctrine_turn = d.get("dturn", -99)
	c.industry = d.get("industry", 55.0)
	c.cyber = d.get("cyber", 20.0)
	c.logistics = d.get("logistics", 50.0)
	c.stability = d.get("stability", 70.0)
	c.capacity = d.get("capacity", 0.5)
	c.tech = d.get("tech", 0.5)
	c.bloc = d.get("bloc", "us")
	c.inv = d.get("inv", {}).duplicate()
	c.orders = d.get("orders", []).duplicate(true)
	c.auto_buy = d.get("auto_buy", true)
	c.auto_cmd = d.get("auto_cmd", false)
	c.pri = d.get("pri", c.pri).duplicate()
	c.base_troops = d.get("base", 0)
	c.fund = d.get("fund", 0.0)
	c.embargo = d.get("embargo", []).duplicate()
	c.fronts = d.get("fronts", {}).duplicate(true)
	c.trade_block = d.get("tblock", 0)
	c.alliance = d.get("alliance", -1)
	c.leader = d.get("leader", "")
	c.cab = d.get("cab", {}).duplicate(true)
	c.elect_turn = int(d.get("elect", -1))
	c.covert_cd = {}
	for k in d.get("covert", {}):
		c.covert_cd[int(k)] = int(d.covert[k])
