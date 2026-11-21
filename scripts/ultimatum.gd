extends RefCounted
## Ültimatom: barış zamanında bir ülkeden talepte bulun (geçiş izni, haraç, sınır eyaleti).
## Kabul ederse talep yerine gelir; reddederse savaş başlar. Kabul ihtimali güç oranına göre değişir.

const Macro = preload("res://scripts/macro.gd")
const Cmd = preload("res://scripts/cmd.gd")
const COOLDOWN := 8     # aynı ülkeye iki ültimatom arası hafta

const KINDS := {
	"passage": {"name": "Askerî geçiş izni", "need": 1.0, "rel": -8.0},
	"tribute": {"name": "Haraç", "need": 1.7, "rel": -15.0},
	"land": {"name": "Sınır eyaleti", "need": 2.6, "rel": -30.0},
}


## Oyuncunun gücünün hedefin (ve müttefiklerinin yarısı kadar) gücüne oranı.
static func power_ratio(gs, me: int, target: int) -> float:
	var mine: float = maxf(1.0, gs.power_of(gs.countries[me]))
	var theirs: float = gs.power_of(gs.countries[target])
	for a in gs.countries[target].allies:
		if a != me and not gs.is_allied(me, a) and gs.countries[a].alive:
			theirs += 0.5 * gs.power_of(gs.countries[a])
	return mine / maxf(1.0, theirs)


## Talep edilebilecek sınır eyaleti: hedefin, bizim toprağımıza komşu en ucuz eyaleti (başkent hariç).
static func border_province(gs, me: int, target: int) -> int:
	var best := -1
	var best_cost := 1 << 30
	for p in gs.provinces:
		if p.owner != target or p.is_capital:
			continue
		var touches := false
		for n in p.neighbors:
			if gs.provinces[n].owner == me:
				touches = true
				break
		if touches and p.peace_cost() < best_cost:
			best = p.id
			best_cost = p.peace_cost()
	return best


static func chance(gs, kind: String, target: int) -> float:
	var me: int = gs.player
	var need: float = KINDS[kind].need
	var ratio := power_ratio(gs, me, target)
	var rel: float = gs.relation_of(target, me)
	var base: float
	if ratio >= need:
		base = 0.92
	elif ratio >= need * 0.6:
		base = lerpf(0.08, 0.6, (ratio - need * 0.6) / (need * 0.4))
	else:
		base = 0.03
	if kind == "passage":
		base += (rel - 50.0) / 200.0
	return clampf(base, 0.02, 0.97)


static func chance_label(p: float) -> String:
	if p >= 0.75:
		return "Yüksek"
	if p >= 0.4:
		return "Orta"
	if p >= 0.15:
		return "Düşük"
	return "Çok düşük"


## Ültimatom verilebilir mi? Boş döner: evet; değilse nedeni.
static func blocked(gs, target: int) -> String:
	var me: int = gs.player
	var t = gs.countries[target]
	if target == me or not t.alive or t.is_rebel:
		return "Geçersiz hedef."
	if gs.at_war(me, target):
		return "Zaten savaştasınız."
	if gs.is_allied(me, target):
		return "Müttefike ültimatom verilmez."
	var tl: int = int(gs.countries[me].truce.get(target, -1)) - gs.turn
	if tl > 0:
		return "Ateşkes sürüyor (%d hafta); bu sürede ültimatom verilemez." % tl
	var cd: int = int(gs.countries[me].ult_turn.get(target, -999)) + COOLDOWN - gs.turn
	if cd > 0:
		return "Yeni ültimatom için %d hafta beklemelisin." % cd
	return ""


static func describe(gs, kind: String, target: int) -> String:
	var t = gs.countries[target]
	match kind:
		"passage":
			return "%s, ordularının topraklarından 52 hafta geçmesine izin versin." % t.name
		"tribute":
			return "%s hazinesinin bir kısmını (%s) bize ödesin." % [t.name, Macro.money(tribute_amount(gs, target))]
		"land":
			var pid := border_province(gs, gs.player, target)
			if pid < 0:
				return "Sınırımıza komşu, talep edilebilecek eyalet yok."
			return "%s eyaletini bize devretsin." % gs.provinces[pid].name
	return ""


static func tribute_amount(gs, target: int) -> float:
	var t = gs.countries[target]
	return maxf(0.0, minf(t.gold * 0.4, maxf(t.income, 0.0) * 12.0))


static func available(gs, kind: String, target: int) -> bool:
	if kind == "land":
		return border_province(gs, gs.player, target) >= 0
	if kind == "tribute":
		return tribute_amount(gs, target) >= 1.0
	if kind == "passage":
		return not gs.has_passage(gs.player, target)
	return true


## Ültimatomu ilet. {ok, accepted, text}
static func deliver(gs, kind: String, target: int) -> Dictionary:
	var _cmd := Cmd.Scope.new(gs, "Ultimatum.deliver", [kind, target])
	var why := blocked(gs, target)
	if why != "":
		return {"ok": false, "text": why}
	var me: int = gs.player
	var c = gs.countries[me]
	var t = gs.countries[target]
	c.ult_turn[target] = gs.turn
	var p := chance(gs, kind, target)
	if gs.rng.randf() < p:
		var txt := ""
		match kind:
			"passage":
				t.passage[me] = gs.turn + 52
				txt = "%s ültimatomu kabul etti: ordularımıza 52 hafta geçiş izni verdi." % t.name
			"tribute":
				var amt := tribute_amount(gs, target)
				t.gold -= amt
				c.gold += amt
				txt = "%s ültimatomu kabul etti ve %s haraç ödedi." % [t.name, Macro.money(amt)]
			"land":
				var pid := border_province(gs, me, target)
				if pid < 0:
					return {"ok": false, "text": "Talep edilebilecek eyalet kalmadı."}
				var pr = gs.provinces[pid]
				pr.owner = me
				pr.controller = me
				pr.siege = 0
				pr.acquired = gs.turn
				pr.unrest = 0
				txt = "%s ültimatomu kabul etti ve %s eyaletini devretti." % [t.name, pr.name]
				gs.refresh_stats()
				gs.province_changed.emit(pid)
				gs.armies_changed.emit()
		gs.relation_add(me, target, float(KINDS[kind].rel))
		gs.post_news("%s, %s'in ültimatomuna boyun eğdi." % [t.name, c.name], t.capital, "info")
		gs.state_changed.emit()
		return {"ok": true, "accepted": true, "text": txt}
	# reddetti: savaş
	gs.relation_add(me, target, -20.0)
	gs.declare_war(me, target)
	gs.post_news("%s, %s'in ültimatomunu reddetti. Savaş başladı!" % [t.name, c.name], t.capital, "war")
	gs.state_changed.emit()
	return {"ok": true, "accepted": false, "text": "%s ültimatomu reddetti: savaş başladı!" % t.name}
