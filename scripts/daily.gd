extends RefCounted
## Günlük Meydan Okuma: her gün herkes için aynı ülke, aynı dünya tohumu ve aynı "günün çarpıtması". 52 tur (1 yıl) sonunda
## skor hesaplanır. Skor ülkenin başlangıcına göre ilerlemeyi ölçer; küçük ve büyük ülkeler adil yarışır.
## İlk tamamlama günde bir kez AP verir; tekrar denemek serbesttir (en iyi skor tutulur). Oyun gücü satılmaz.

const Settings = preload("res://scripts/settings.gd")
const AP = preload("res://scripts/ap.gd")
const Loc = preload("res://scripts/loc.gd")
const Missions = preload("res://scripts/missions.gd")
const Scenarios = preload("res://scripts/scenarios.gd")

const TURNS := 52
const AP_FIRST := 20
const AP_TIER := [[1500, 10], [2500, 15], [4000, 25]]     # skor eşiği -> ek AP (yalnız günün ilk bitirişinde)
const COUNTRIES := ["Turkey", "Poland", "Egypt", "Brazil", "Japan", "France", "Germany", "India", "Indonesia", "Mexico", "Argentina",
	"South Africa", "Nigeria", "Iran", "Vietnam", "Thailand", "Spain", "Italy", "Ukraine", "Canada", "Australia", "South Korea",
	"Pakistan", "Saudi Arabia", "Colombia", "Chile", "Peru", "Philippines", "Greece", "Sweden", "Romania", "Algeria", "Kazakhstan",
	"Ethiopia", "Morocco", "Israel", "Norway", "Finland", "Serbia", "Cuba", "United Kingdom", "Malaysia", "Bangladesh"]

# id, ad [tr, en], açıklama [tr, en], sc: senaryo sözlüğü ("$P" oyuncu, "$N" ilk komşu)
const TWISTS := [
	{"id": "rich", "name": ["Dolu Kasa", "Full Treasury"], "desc": ["Hazine iki kat dolu, ama ordun zayıf. Parayı akıllıca harca.", "The treasury is doubled, but the army is weak. Spend wisely."],
		"sc": {"treasury_mult": {"$P": 2.0}, "troops_mult": {"$P": 0.75}}},
	{"id": "poor", "name": ["Kıt Kaynak", "Scarce Resources"], "desc": ["Hazine yarı yarıya, ama ordun güçlü. Hızlı davran.", "The treasury is halved, but the army is strong. Move fast."],
		"sc": {"treasury_mult": {"$P": 0.5}, "troops_mult": {"$P": 1.3}}},
	{"id": "invade", "name": ["Komşu Saldırısı", "Neighbor Attacks"], "desc": ["Bir komşun ilk günden savaş açtı. Savun ya da barış yap.", "A neighbor declared war on day one. Defend or make peace."],
		"sc": {"wars": [["$N", "$P"]], "troops_mult": {"$P": 1.15}}},
	{"id": "embargo", "name": ["Ambargo", "Embargo"], "desc": ["Komşunla ticaret kesildi; gelirin düşük başlıyor ama ordun hazır.", "Trade with your neighbor is cut; income starts low but the army is ready."],
		"sc": {"embargo": [["$P", "$N"]], "troops_mult": {"$P": 1.1}}},
	{"id": "unrest", "name": ["Huzursuz Ülke", "Restless Country"], "desc": ["İç istikrar düşük başlıyor; kontrolü kaybetme.", "Domestic stability starts low; do not lose control."],
		"sc": {"stability": {"$P": -22}, "treasury_mult": {"$P": 1.4}}},
	{"id": "golden", "name": ["Altın Çağ", "Golden Age"], "desc": ["Ülke huzurlu ve zengin; bu kolay başlangıcı büyümeye çevir.", "The country is calm and wealthy; turn this easy start into growth."],
		"sc": {"stability": {"$P": 15}, "treasury_mult": {"$P": 1.3}}},
	{"id": "cold", "name": ["Soğuk Savaş Gölgesi", "Shadow of Cold War"], "desc": ["Komşunla gerginlik var; her an savaşa dönebilir.", "Tension with your neighbor could turn into war at any moment."],
		"sc": {"cold": [["$P", "$N"]], "cyber": {"$N": 12}}},
]


static func _tr() -> bool:
	return Loc.lang == "tr"


static func today() -> int:
	return Missions.today()


## Verilen gün için sabit yapılandırma (aynı gün, aynı sonuç)
static func cfg(day: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 7919 + 13
	var country: String = COUNTRIES[rng.randi_range(0, COUNTRIES.size() - 1)]
	var twist: Dictionary = TWISTS[rng.randi_range(0, TWISTS.size() - 1)]
	return {"day": day, "seed": 100000 + (day * 104729) % 800000, "country": country, "twist": String(twist.id), "turns": TURNS}


static func twist_of(id: String) -> Dictionary:
	for t in TWISTS:
		if String(t.id) == id:
			return t
	return TWISTS[0]


static func twist_name(id: String) -> String:
	var n: Array = twist_of(id).name
	return String(n[0]) if _tr() else String(n[1])


static func twist_desc(id: String) -> String:
	var n: Array = twist_of(id).desc
	return String(n[0]) if _tr() else String(n[1])


static func _subst(v, p: String, n: String):
	if v is String:
		return p if v == "$P" else (n if v == "$N" else v)
	if v is Array:
		var out: Array = []
		for e in v:
			out.append(_subst(e, p, n))
		return out
	if v is Dictionary:
		var d: Dictionary = {}
		for k in v:
			d[_subst(k, p, n)] = _subst(v[k], p, n)
		return d
	return v


static func active(gs) -> bool:
	return gs.daily is Dictionary and bool(gs.daily.get("on", false))


static func _share(gs, c) -> float:
	var tot := 0.0
	for x in gs.countries:
		if x.alive and not x.is_rebel:
			tot += x.gdp
	return c.gdp / maxf(tot, 1.0) * 100.0


## Oyun başlangıcında (oyuncu seçildikten sonra) çağrılır.
static func begin(gs, conf: Dictionary) -> void:
	var pc = gs.countries[gs.player]
	var nb: Array = gs.neighbor_countries(gs.player)
	var neighbor := ""
	if not nb.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = int(conf.seed)
		neighbor = String(gs.countries[int(nb[rng.randi_range(0, nb.size() - 1)])].name_en)
	var tw: Dictionary = twist_of(String(conf.twist))
	var sc: Dictionary = _subst(tw.sc.duplicate(true), pc.name_en, neighbor)
	if neighbor == "":
		sc.erase("wars")
		sc.erase("embargo")
		sc.erase("cold")
	sc["intro"] = (Loc.t("Günlük Meydan Okuma: %s — %s") % [twist_name(String(conf.twist)), twist_desc(String(conf.twist))])
	Scenarios.apply_dict(gs, sc, false)
	gs.daily = {"on": true, "day": int(conf.day), "twist": String(conf.twist), "start": gs.turn, "turns": int(conf.turns), "done": false,
		"prov0": pc.prov_owned, "share0": _share(gs, pc), "score": 0}
	gs.difficulty = 1


## Anlık skor (oyuncu yaşıyorsa); ilerleme başlangıca göredir
static func score(gs) -> int:
	if not active(gs) or gs.player < 0:
		return 0
	var c = gs.countries[gs.player]
	if not c.alive:
		return 0
	var s: float = 500.0 + 100.0 * float(c.prov_owned - int(gs.daily.prov0)) + 15.0 * float(c.prov_owned)
	s += 150.0 * (_share(gs, c) - float(gs.daily.share0)) + 4.0 * c.stability + 40.0 * float(c.allies.size())
	return maxi(0, int(round(s)))


static func weeks_left(gs) -> int:
	return maxi(0, int(gs.daily.start) + int(gs.daily.turns) - gs.turn)


## Her tur: süre dolduysa bitir
static func tick(gs) -> void:
	if not active(gs) or bool(gs.daily.get("done", false)):
		return
	gs.daily["score"] = score(gs)
	if weeks_left(gs) <= 0:
		_finish(gs)


static func _tier_ap(sc: int) -> int:
	var add := 0
	for t in AP_TIER:
		if sc >= int(t[0]):
			add = int(t[1])
	return add


static func _finish(gs) -> void:
	gs.daily["done"] = true
	var sc: int = score(gs)
	gs.daily["score"] = sc
	var rec: Dictionary = record(int(gs.daily.day), sc)
	var text: String = Loc.t("Günlük Meydan Okuma tamamlandı!\nSkorun: %d") % sc
	if bool(rec.best):
		text += "\n" + Loc.t("Bugünün en iyi skorun!")
	if int(rec.ap) > 0:
		text += "\n" + Loc.t("Ödül: +%d AP") % int(rec.ap)
	if int(rec.streak) > 1:
		text += "\n" + Loc.t("Seri: %d gün") % int(rec.streak)
	gs.game_over.emit(true, text)


## Skoru kalıcı kayda yazar. Dönüş: {best: bool, ap: int, streak: int}
static func record(day: int, sc: int) -> Dictionary:
	var d: Dictionary = Settings.daily
	var out := {"best": false, "ap": 0, "streak": int(d.get("streak", 0))}
	var first: bool = int(d.get("last_day", -1)) != day
	if first:
		d["last_day"] = day
		d["best_today"] = 0
		var prev: int = int(d.get("last_done", -10))
		d["streak"] = (int(d.get("streak", 0)) + 1) if prev == day - 1 else 1
		d["last_done"] = day
		out["ap"] = AP_FIRST + _tier_ap(sc)
		AP.earn(int(out["ap"]), "daily")
		d["count"] = int(d.get("count", 0)) + 1
	if sc > int(d.get("best_today", 0)):
		d["best_today"] = sc
		out["best"] = true
	if sc > int(d.get("best_all", 0)):
		d["best_all"] = sc
	out["streak"] = int(d.get("streak", 0))
	Settings.daily = d
	Settings.save_all()
	return out


static func best_today(day: int) -> int:
	var d: Dictionary = Settings.daily
	return int(d.get("best_today", 0)) if int(d.get("last_day", -1)) == day else 0


static func done_today(day: int) -> bool:
	return int(Settings.daily.get("last_day", -1)) == day


## Seri hâlâ geçerli mi (dün ya da bugün bitirildiyse)
static func streak_now() -> int:
	var d: Dictionary = Settings.daily
	return int(d.get("streak", 0)) if int(d.get("last_done", -10)) >= today() - 1 else 0
