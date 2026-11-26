extends RefCounted
## Uçak gemisi grupları: denizden güç yansıtma. Çıkarma kapasitesini ve çıkarma saldırısını güçlendirir,
## kıyıdaki düşman eyaletlerini (ada ülkeleri dâhil) ordu olmadan vurabilir, deniz gücüne katkı verir.
## Oyuncu satın alabilir; yapay zekâ yalnızca başlangıçtaki gemilerine sahiptir (ek zorluk yok).

const Eras = preload("res://scripts/eras.gd")
const Macro = preload("res://scripts/macro.gd")
const Fleets = preload("res://scripts/fleets.gd")
const Cmd = preload("res://scripts/cmd.gd")

const START := {
	"": {"United States of America": 11, "China": 3, "United Kingdom": 2, "France": 1, "India": 2, "Italy": 2, "Japan": 2, "Russia": 1, "Spain": 1, "Turkey": 1, "Thailand": 1},
	"ww2": {"United States of America": 7, "United Kingdom": 7, "Japan": 8, "France": 1},
	"ww1": {},
}
const MAX_OWNED := 8
const STRIKE_CD := 3
const MIN_TECH := 0.35


static func start_count(c) -> int:
	var ext = Eras.field("carriers", null)
	if ext is Dictionary:
		return int(ext.get(c.name_en, 0))
	return int(START.get(Eras.current, {}).get(c.name_en, 0))


static func count(c) -> int:
	return maxi(0, c.carriers)


static func available() -> bool:
	return Eras.family() != "ww1" and Eras.family() != "pre"


static func cost(c) -> float:
	return clampf(c.income * 14.0, 3000.0, 14000.0)


static func upkeep(c) -> float:
	return float(c.carrier_extra) * cost(c) * 0.004


## Muharebe gemisi grubu (yüzey filosuna +1.2 güç): yaklaşık 2 gemi
const SHIP_MAX := 24
const SHIP_POWER := 1.2


static func ship_cost(c) -> float:
	return clampf(c.income * 3.0, 700.0, 3500.0)


static func ship_upkeep(c) -> float:
	return float(c.ship_extra) * ship_cost(c) * 0.003


## Denizde gerçekten ayakta kalan inşa edilmiş gemi grubu sayısı (muharebe kayıpları ship_extra sayacına yansımadığı için sayaçtan küçük olabilir).
static func effective_ships(gs, c) -> int:
	Fleets.ensure(gs)
	var cur: float = Fleets._sum_kind(Fleets.fleets_of(gs, c.id), "surface")
	var base: float = maxf(1.0, Fleets.SURFACE_RATIO * Fleets.sub_target(c) + 2.0 * float(maxi(c.carriers, 0)))
	return clampi(int(floor((cur - base) / SHIP_POWER + 0.5)), 0, maxi(c.ship_extra, 0))


static func can_build_ship(gs, c) -> String:
	if Eras.family() == "pre" and c.tech < 0.1:
		return "Gemi inşası için teknoloji yetersiz."
	if not c.alive or c.is_rebel or Fleets.Seas.home_port(gs, c.id)[1] == "":
		return "Gemi inşa edecek bir limanın yok."
	if c.ship_extra >= SHIP_MAX and effective_ships(gs, c) >= SHIP_MAX:
		return "Daha fazla gemi grubu işletemezsin."
	if c.gold < ship_cost(c):
		return "Kasa yetersiz: %s gerekir." % Macro.money(ship_cost(c))
	return ""


static func build_ship(gs) -> String:
	var _cmd := Cmd.Scope.new(gs, "Carriers.build_ship", [])
	var c = gs.countries[gs.player]
	var err := can_build_ship(gs, c)
	if err != "":
		return err
	Fleets.ensure(gs)
	if c.ship_extra >= SHIP_MAX:
		c.ship_extra = effective_ships(gs, c)      # savaşta batan gemiler sayaçtan düşer; sınırda kilitli kalma
	c.gold -= ship_cost(c)
	c.ship_extra += 1
	var home: String = String(Fleets.Seas.home_port(gs, c.id)[1])
	var f = Fleets._port_fleet(gs, Fleets.fleets_of(gs, c.id), "surface", home)
	if f != null:
		f.size += SHIP_POWER
	else:
		Fleets.new_fleet(gs, c.id, home, "surface", SHIP_POWER)
	gs.post_news("%s yeni savaş gemileri denize indirdi." % c.name, c.capital, "event_player", "ship")
	gs.state_changed.emit()
	return ""


static func can_buy(gs, c) -> String:
	if not available():
		return "Bu çağda uçak gemisi yok."
	if c.tech < MIN_TECH:
		return "Uçak gemisi için teknoloji yetersiz (en az %%%d)." % int(MIN_TECH * 100.0)
	if count(c) >= MAX_OWNED:
		return "Daha fazla uçak gemisi grubu işletemezsin."
	if c.gold < cost(c):
		return "Kasa yetersiz: %s gerekir." % Macro.money(cost(c))
	return ""


static func buy(gs) -> String:
	var _cmd := Cmd.Scope.new(gs, "Carriers.buy", [])
	var c = gs.countries[gs.player]
	var err := can_buy(gs, c)
	if err != "":
		return err
	c.gold -= cost(c)
	c.carriers = count(c) + 1
	c.carrier_extra += 1
	Macro.recalc(c)
	Fleets.ensure(gs)
	Fleets.sync_country(gs, c, {})      # yeni grup limanda filo olarak belirir
	gs.post_news("%s yeni bir uçak gemisi grubu devreye aldı." % c.name, c.capital, "event_player", "ship")
	gs.state_changed.emit()
	return ""


static func strike_cost(c) -> float:
	return clampf(c.income * 0.25, 10.0, 400.0)


## Oyuncu uçak gemisi saldırısı: kıyı eyaletindeki düşman ordusunu vurur. Dönüş: {err, killed}
static func strike(gs, pid: int) -> Dictionary:
	var _cmd := Cmd.Scope.new(gs, "Carriers.strike", [pid])
	var res := {"err": "", "killed": 0}
	var c = gs.countries[gs.player]
	var p = gs.provinces[pid]
	if count(c) < 1:
		res.err = "Uçak gemin yok."
		return res
	if c.carrier_cd > gs.turn:
		res.err = "Uçak gemisi grubu hazırlanıyor (%d hafta)." % (c.carrier_cd - gs.turn)
		return res
	var holder: int = gs._holder(pid)
	if holder < 0 or not gs.at_war(gs.player, holder):
		res.err = "Hedefle savaşta olmalısın."
		return res
	if not p.coastal:
		res.err = "Hedef kıyıda değil."
		return res
	var sc: float = strike_cost(c)
	if c.gold < sc:
		res.err = "Kasa yetersiz: %s." % Macro.money(sc)
		return res
	c.gold -= sc
	c.carrier_cd = gs.turn + STRIKE_CD
	var d = gs.armies.get(pid)
	var n: int = mini(count(c), 6)
	var foe = gs.countries[holder]
	var air_share: float = foe.air_pow / (foe.air_pow + c.air_pow + n * 2.0 + 1.0)
	var k: float = clampf((0.10 + 0.05 * n) * (1.0 - 0.6 * air_share), 0.05, 0.40)
	if d != null and d.owner != gs.player:
		res.killed = int(d.size * k)
		d.size = maxi(1, d.size - res.killed)
	if n >= 2 and p.defense > 0:
		p.defense -= 1
	gs.stats.strikes = int(gs.stats.get("strikes", 0)) + 1
	gs.post_news("%s uçak gemileri %s eyaletini vurdu%s." % [c.name, p.name, (": %s asker kaybı" % Macro.num(res.killed)) if res.killed > 0 else ""], pid, "war_player", "ship")
	gs.province_changed.emit(pid)
	gs.armies_changed.emit()
	gs.state_changed.emit()
	return res
