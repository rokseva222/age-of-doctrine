extends RefCounted
## Askeri Ar-Ge: piyade (tüfek), zırh (tank), topçu, hava ve deniz gücünü kalıcı olarak artıran dal seviyeleri.
## Aynı anda tek dal araştırılır; araştırma sürerken haftalık gelirin bir kısmı harcanır. Eğitim payı hızlandırır.
## Seviye başına ilgili sınıfın savaş gücü +%5 (en çok 8 seviye). YZ ülkeleri de araştırır.
const Cmd = preload("res://scripts/cmd.gd")
const Loc = preload("res://scripts/loc.gd")

const BRANCHES := ["inf", "tank", "arty", "air", "sub"]
const NAMES := {"inf": "Piyade ve tüfek", "tank": "Zırh ve tank", "arty": "Topçu", "air": "Hava kuvvetleri", "sub": "Deniz kuvvetleri"}
const ICONS := {"inf": "uc_inf", "tank": "uc_tank", "arty": "uc_arty", "air": "uc_jet", "sub": "uc_ship"}
const MAX_LV := 8
const PER_LV := 0.05            # seviye başına güç
const COST_SHARE := 0.035       # araştırma sürerken haftalık gelirin payı


static func ensure(c) -> void:
	if not (c.mres is Dictionary) or not c.mres.has("lv"):
		c.mres = {"lv": {}, "cur": "", "prog": 0.0}
	for b in BRANCHES:
		if not c.mres["lv"].has(b):
			c.mres["lv"][b] = 0


static func level(c, b: String) -> int:
	if not (c.mres is Dictionary) or not c.mres.has("lv"):
		return 0
	return int(c.mres["lv"].get(b, 0))


## Sınıf (Arsenal kategorisi) için güç çarpanı; afv zırh dalından yararlanır.
static func mult(c, cat: String) -> float:
	var b: String = cat
	if cat == "afv":
		b = "tank"
	return 1.0 + PER_LV * float(level(c, b))


## Seviye için gereken araştırma puanı (hafta başına ~1 puan; eğitim payı hızlandırır)
static func need(c, b: String) -> float:
	return 10.0 + 6.0 * float(level(c, b))


static func weekly_cost(c) -> float:
	if not (c.mres is Dictionary) or String(c.mres.get("cur", "")) == "":
		return 0.0
	return maxf(c.income, 1.0) * COST_SHARE


static func speed(c) -> float:
	var edu: float = float(c.budget.get("edu", 4)) if c.budget is Dictionary else 4.0
	return clampf(0.7 + 0.06 * edu + 0.6 * c.tech, 0.6, 2.2)


## Oyuncu emri: dal seç ("" = durdur). Hata metni döner.
static func set_research(c, b: String) -> String:
	var _cmd := Cmd.Scope.new(Cmd.rec_gs, "MilRes.set_research", [c, b])
	ensure(c)
	if b != "" and not BRANCHES.has(b):
		return "?"
	if b != "" and level(c, b) >= MAX_LV:
		return "Bu dal en üst seviyede."
	if String(c.mres["cur"]) != b:
		c.mres["cur"] = b
		c.mres["prog"] = 0.0
	return ""


## Haftalık ilerleme; Macro.weekly çağırır. Harcanan parayı (negatif) döndürür, seviye atlarsa true işaretler.
static func weekly(gs, c) -> float:
	ensure(c)
	var human: bool = c.id == gs.player or gs.humans.has(c.id)
	if not human and String(c.mres["cur"]) == "":
		_ai_pick(gs, c)
	var b: String = String(c.mres["cur"])
	if b == "":
		return 0.0
	if c.gold < -c.income * 0.5:
		return 0.0                           # borç batağında araştırma durur
	var cost: float = weekly_cost(c)
	c.mres["prog"] = float(c.mres["prog"]) + speed(c)
	if float(c.mres["prog"]) >= need(c, b):
		c.mres["lv"][b] = level(c, b) + 1
		c.mres["prog"] = 0.0
		c.mres["cur"] = "" if level(c, b) >= MAX_LV or not human else b
		if human:
			gs.post_news(Loc.t("Askeri Ar-Ge tamamlandı: %s seviye %d (+%d%% güç)") % [Loc.t(NAMES[b]), level(c, b), int(round(PER_LV * 100.0 * level(c, b)))], -1, "info", "", c.id)
	return -cost


## YZ: çoğunlukla en zayıf ya da doktrinine uygun dal; fakir ülkeler araştırmaz
static func _ai_pick(gs, c) -> void:
	if c.income < 40.0 or c.gold < 0.0:
		return
	if (gs.turn + c.id) % 6 != 0:
		return
	var best := ""
	var bs := 1e9
	for b in BRANCHES:
		var lv: int = level(c, b)
		if lv >= MAX_LV:
			continue
		var sc: float = float(lv) + gs.rng.randf() * 1.5
		if b == "sub" and c.naval_pow <= 0.0:
			sc += 3.0
		if b == "air" and c.air_pow <= 0.0:
			sc += 3.0
		if sc < bs:
			bs = sc
			best = b
	c.mres["cur"] = best
	c.mres["prog"] = 0.0


static func to_dict(c) -> Dictionary:
	if not (c.mres is Dictionary):
		return {}
	return c.mres.duplicate(true)


static func from_dict(c, d) -> void:
	c.mres = {"lv": {}, "cur": "", "prog": 0.0}
	if d is Dictionary and d.has("lv"):
		for b in BRANCHES:
			c.mres["lv"][b] = clampi(int((d["lv"] as Dictionary).get(b, 0)), 0, MAX_LV)
		var cur: String = String(d.get("cur", ""))
		c.mres["cur"] = cur if BRANCHES.has(cur) else ""
		c.mres["prog"] = float(d.get("prog", 0.0))
	ensure(c)
