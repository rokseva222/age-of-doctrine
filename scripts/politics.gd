extends RefCounted
## Siyasi sistem: rejim türleri, darbe riski, yapay zekâ seçimleri ve oyuncunun siyasi reformları.
## Rejimler: democracy, monarchy, authoritarian, communist, junta. Etkiler küçük ve dengelidir; hiçbiri oyunu tek başına bitirmez.
## Oyuncuya darbe/kitlesel protesto "uyarı kartı" olarak gelir (üç seçenek); asla habersiz oyun sonu yok.
## Oyuncunun kendi seçimi cabinet.gd'de (yalnız demokrasilerde); burada yalnız YZ ülkelerin seçimi var.

const Icons = preload("res://scripts/icons.gd")
const Loc = preload("res://scripts/loc.gd")
const Eras = preload("res://scripts/eras.gd")
const NameGen = preload("res://scripts/name_gen.gd")
const Macro = preload("res://scripts/macro.gd")

const REGIMES := ["democracy", "monarchy", "authoritarian", "communist", "junta"]
const NAME_TR := {"democracy": "Demokrasi", "monarchy": "Monarşi", "authoritarian": "Otoriter yönetim", "communist": "Tek parti (komünist)", "junta": "Askerî yönetim"}
const NAME_EN := {"democracy": "Democracy", "monarchy": "Monarchy", "authoritarian": "Authoritarian rule", "communist": "One-party (communist)", "junta": "Military rule"}
const DESC_TR := {
	"democracy": "Düzenli seçimler, güçlü meşruiyet ve ticaret. Savaş yorgunluğu istikrarı çabuk aşındırır; darbe riski çok düşüktür.",
	"monarchy": "Köklü hanedan; istikrar yavaş ve sağlam. Darbe riski düşük, ama reform esnekliği sınırlı.",
	"authoritarian": "Güçlü merkez: istikrar toparlanır, savaş yorgunluğu azdır. Verimlilik düşük, darbe riski orta.",
	"communist": "Planlı ekonomi ve sıkı örgütlenme: istikrar sağlam. Dış ticaret kısıtlı, darbe riski düşük-orta.",
	"junta": "Ordu iktidarda: savaş yorgunluğu yok ama ekonomi verimsiz; darbe riski yüksek.",
}
const DESC_EN := {
	"democracy": "Regular elections, strong legitimacy and trade. War weariness erodes stability quickly; coup risk is very low.",
	"monarchy": "An old dynasty: stability is slow and firm. Low coup risk, but little reform flexibility.",
	"authoritarian": "A strong center: stability recovers, little war weariness. Lower efficiency, moderate coup risk.",
	"communist": "Planned economy and tight organization: solid stability. Limited foreign trade, low-to-moderate coup risk.",
	"junta": "The army rules: no war weariness but an inefficient economy; high coup risk.",
}
const INCOME := {"democracy": 1.02, "monarchy": 1.0, "authoritarian": 0.98, "communist": 1.0, "junta": 0.96}
const STAB_DRIFT := {"democracy": 0.0, "monarchy": 0.05, "authoritarian": 0.08, "communist": 0.06, "junta": 0.03}
const WAR_WEARY := {"democracy": 0.10, "monarchy": 0.04, "authoritarian": 0.0, "communist": 0.02, "junta": 0.0}
const COUP_BASE := {"democracy": 0.0, "monarchy": 0.0012, "authoritarian": 0.004, "communist": 0.0015, "junta": 0.008}
const CHECK_EVERY := 4
const REFORM_COOLDOWN := 104
const MARTIAL_WEEKS := 12

# Modern: demokrasi dışındaki rejimler (kalanı demokrasi). Tarafsız, genel sınıflandırma.
const MODERN := {
	"China": "communist", "Vietnam": "communist", "Cuba": "communist", "Laos": "communist", "North Korea": "communist",
	"Russia": "authoritarian", "Belarus": "authoritarian", "Iran": "authoritarian", "Egypt": "authoritarian", "Syria": "authoritarian",
	"Venezuela": "authoritarian", "Azerbaijan": "authoritarian", "Kazakhstan": "authoritarian", "Uzbekistan": "authoritarian",
	"Turkmenistan": "authoritarian", "Tajikistan": "authoritarian", "Kyrgyzstan": "authoritarian", "Eritrea": "authoritarian",
	"Rwanda": "authoritarian", "Cameroon": "authoritarian", "Algeria": "authoritarian", "Afghanistan": "authoritarian",
	"Nicaragua": "authoritarian", "Cambodia": "authoritarian", "Zimbabwe": "authoritarian", "Eq. Guinea": "authoritarian",
	"Chad": "authoritarian", "Congo": "authoritarian", "Djibouti": "authoritarian", "Uganda": "authoritarian", "Libya": "authoritarian",
	"Saudi Arabia": "monarchy", "United Arab Emirates": "monarchy", "Qatar": "monarchy", "Kuwait": "monarchy", "Oman": "monarchy",
	"Bahrain": "monarchy", "Jordan": "monarchy", "Morocco": "monarchy", "Brunei": "monarchy", "eSwatini": "monarchy",
	"Myanmar": "junta", "Sudan": "junta", "Mali": "junta", "Burkina Faso": "junta", "Niger": "junta", "Guinea": "junta", "Gabon": "junta",
}
const ERA := {
	"ww1": {
		"monarchy": ["Germany", "Austria", "Russia", "Turkey", "United Kingdom", "Italy", "Belgium", "Serbia", "Bulgaria", "Romania", "Greece",
			"Japan", "Netherlands", "Sweden", "Norway", "Denmark", "Spain", "Thailand", "Iran", "Ethiopia", "Montenegro"],
		"democracy": ["United States of America", "France", "Switzerland", "Brazil", "Argentina", "Canada", "Australia", "New Zealand", "Portugal", "Chile", "Uruguay"],
		"default": "authoritarian",
	},
	"ww2": {
		"authoritarian": ["Germany", "Italy", "Japan", "Spain", "Portugal", "Turkey", "China", "Romania", "Hungary", "Bulgaria", "Greece", "Poland", "Slovakia", "Brazil"],
		"communist": ["Russia"],
		"monarchy": ["Saudi Arabia", "Iran", "Ethiopia", "Thailand", "Iraq", "Egypt"],
		"democracy": ["United States of America", "United Kingdom", "France", "Canada", "Australia", "New Zealand", "South Africa", "Netherlands", "Belgium",
			"Sweden", "Norway", "Denmark", "Switzerland", "Czechia", "Ireland", "Finland", "Mexico", "Chile", "Argentina"],
		"default": "authoritarian",
	},
	"cold": {
		"communist": ["Russia", "China", "Poland", "Czechia", "Hungary", "Romania", "Bulgaria", "Albania", "Cuba", "Serbia", "Vietnam", "North Korea", "Mongolia"],
		"monarchy": ["Saudi Arabia", "Iran", "Jordan", "Morocco", "Ethiopia", "Nepal", "Thailand", "Kuwait", "Libya"],
		"democracy": ["United States of America", "United Kingdom", "France", "Germany", "Italy", "Canada", "Belgium", "Netherlands", "Luxembourg", "Denmark",
			"Norway", "Iceland", "Greece", "Turkey", "India", "Japan", "Australia", "New Zealand", "Israel", "Sweden", "Switzerland", "Ireland", "Austria", "Finland"],
		"default": "authoritarian",
	},
}


static func _tr() -> bool:
	return Loc.lang == "tr"


static func name_of(r: String) -> String:
	return String(NAME_TR[r]) if _tr() else String(NAME_EN[r])


static func desc_of(r: String) -> String:
	return String(DESC_TR[r]) if _tr() else String(DESC_EN[r])


static func ensure(gs) -> void:
	if not (gs.pol is Dictionary):
		gs.pol = {}
	for k in ["reg", "elect", "cd", "martial", "risk_cd", "pending", "reform"]:
		if not gs.pol.has(k):
			gs.pol[k] = {}


static func _default_regime(name_en: String) -> String:
	var fam: String = Eras.family()
	if fam == "ww1" or fam == "ww2" or fam == "cold":
		var t: Dictionary = ERA[fam]
		for r in REGIMES:
			if t.has(r) and (t[r] as Array).has(name_en):
				return String(r)
		return String(t["default"])
	return String(MODERN.get(name_en, "democracy"))


static func regime(gs, cid: int) -> String:
	ensure(gs)
	var key := str(cid)
	if not gs.pol.reg.has(key):
		gs.pol.reg[key] = _default_regime(String(gs.countries[cid].name_en))
	return String(gs.pol.reg[key])


static func has_elections(gs, cid: int) -> bool:
	return regime(gs, cid) == "democracy"


static func income_mult(gs, c) -> float:
	var m: float = float(INCOME[regime(gs, c.id)])
	if martial_on(gs, c.id):
		m *= 0.92
	return m


static func martial_on(gs, cid: int) -> bool:
	ensure(gs)
	return int(gs.pol.martial.get(str(cid), -1)) > gs.turn


## Kontrol başına darbe olasılığı (oyuncu için kart tetikler, YZ için gerçekleşir)
static func coup_risk(gs, cid: int) -> float:
	var c = gs.countries[cid]
	var r: String = regime(gs, cid)
	var base: float = float(COUP_BASE[r])
	if r == "democracy" and c.stability < 25.0:
		base = 0.0025
	if base <= 0.0:
		return 0.0
	var f: float = 1.0 + maxf(0.0, (45.0 - c.stability) / 20.0)
	if not c.enemies.is_empty():
		f *= 1.3
	if martial_on(gs, cid):
		f *= 0.4
	return minf(0.08, base * f)


static func risk_label(p: float) -> String:
	if p <= 0.0005:
		return Loc.t("Çok düşük")
	if p < 0.006:
		return Loc.t("Düşük")
	if p < 0.016:
		return Loc.t("Orta")
	return Loc.t("Yüksek")


static func weeks_to_election(gs, cid: int) -> int:
	if not has_elections(gs, cid):
		return -1
	var c = gs.countries[cid]
	if cid == gs.player:
		return maxi(0, int(c.elect_turn) - gs.turn) if c.elect_turn >= 0 else -1
	return maxi(0, int(gs.pol.elect.get(str(cid), gs.turn)) - gs.turn)


static func _new_leader(gs, c, key_extra: String) -> String:
	var cur: Array = Macro.leader_of(c)
	var key := "%s|pol|%d|%s" % [c.name_en, gs.turn, key_extra]
	var nm: String = NameGen.person(NameGen.culture_of(c), key, NameGen.is_female(key, 0.25))
	if cur[0] != "":
		c.leader = "%s|%s" % [cur[0], nm]
	return nm


static func _close_to_player(gs, c) -> bool:
	if gs.player < 0:
		return false
	return c.enemies.has(gs.player) or c.allies.has(gs.player) or gs.neighbor_countries(gs.player).has(c.id)


## Her tur
static func tick(gs) -> void:
	ensure(gs)
	if gs.player < 0:
		return
	for c in gs.countries:
		if not c.alive or c.is_rebel:
			continue
		var r: String = regime(gs, c.id)
		# haftalık istikrar eğilimi: rejime göre yavaş toparlanma / savaş yorgunluğu
		var d: float = float(STAB_DRIFT[r]) if c.stability < 60.0 else 0.0
		if not c.enemies.is_empty():
			d -= float(WAR_WEARY[r])
		if martial_on(gs, c.id):
			d += 0.5
			if c.id == gs.player:
				gs.infamy = minf(100.0, gs.infamy + 0.2)
		if absf(d) > 0.0001:
			c.stability = clampf(c.stability + d, 5.0, 100.0)
		if (gs.turn + c.id) % CHECK_EVERY != 0 or gs.turn < 12:
			continue
		_check(gs, c, r)


static func _check(gs, c, r: String) -> void:
	# YZ demokrasi seçimi
	if c.id != gs.player and r == "democracy":
		var key := str(c.id)
		if not gs.pol.elect.has(key):
			gs.pol.elect[key] = gs.turn + 40 + absi(hash(c.name_en)) % 160
		if gs.turn >= int(gs.pol.elect[key]):
			gs.pol.elect[key] = gs.turn + 208
			_ai_election(gs, c)
			return
	var p: float = coup_risk(gs, c.id)
	if p <= 0.0 or gs.rng.randf() >= p * float(CHECK_EVERY) * 0.5:
		return
	if c.id == gs.player:
		if int(gs.pol.risk_cd.get(str(c.id), 0)) > gs.turn or not gs.pol.pending.is_empty():
			return
		_player_card(gs, c, r)
	else:
		_ai_coup(gs, c)


static func _ai_election(gs, c) -> void:
	var lose: float = clampf(0.45 - (c.stability - 50.0) / 160.0, 0.12, 0.7)
	if gs.rng.randf() < lose:
		var nm: String = _new_leader(gs, c, "elect")
		c.stability = clampf(c.stability - 3.0, 5.0, 100.0)
		if _close_to_player(gs, c):
			gs.post_news((("%s'de seçimi muhalefet kazandı; yeni lider %s." if _tr() else "The opposition won the election in %s; new leader %s.") % [c.name, nm]), c.capital, "info")
	elif _close_to_player(gs, c):
		gs.post_news((("%s'de iktidar seçimi kazandı." if _tr() else "The government won the election in %s.") % c.name), c.capital, "info")


static func _ai_coup(gs, c) -> void:
	var nm: String = _new_leader(gs, c, "coup")
	var was: String = regime(gs, c.id)
	gs.pol.reg[str(c.id)] = "junta" if was != "junta" else "authoritarian"
	c.stability = clampf(c.stability - 12.0, 10.0, 100.0)
	c.gold *= 0.9
	if gs.rng.randf() < 0.4:
		for e in c.enemies.duplicate():
			if int(e) == gs.player:
				continue
			var w = gs.get_war(c.id, int(e))
			if w != null:
				gs.finish_peace(w, -1, [])
	if _close_to_player(gs, c) or gs.rng.randf() < 0.3:
		gs.post_news((("DARBE: %s'de ordu yönetime el koydu; yeni lider %s." if _tr() else "COUP: the army seized power in %s; new leader %s.") % [c.name, nm]), c.capital, "event")


# ------------------------------------------------------------------ oyuncu uyarı kartları

static func _t(tr: String, en: String) -> String:
	return tr if _tr() else en


static func _player_card(gs, c, r: String) -> void:
	var inc: float = maxf(c.income, 1.0)
	var title := ""
	var body := ""
	var ch: Array = []
	if r == "democracy":
		title = _t("Kitlesel Protestolar", "Mass Protests")
		body = _t("Başkentte yüz binler sokakta; hükûmetin istifası isteniyor. Meclis bölünmüş durumda.", "Hundreds of thousands are on the streets of the capital demanding the government resign. Parliament is divided.")
		ch = [{"t": _t("Erken seçim ilan et", "Call early elections"), "k": "early"}, {"t": _t("Sıkıyönetim", "Martial law"), "k": "martial"}, {"t": _t("Reform sözü ver", "Promise reforms"), "k": "reform"}]
	else:
		title = _t("Darbe Hazırlığı", "Coup Plot")
		body = _t("İstihbarat, bir grup generalin hükûmeti devirmek için toplandığını bildiriyor. Ne yapalım?", "Intelligence reports that a group of generals has met to overthrow the government. What do we do?")
		ch = [{"t": _t("Generallere ikramiye ver", "Pay off the generals"), "k": "pay"}, {"t": _t("Tasfiye et", "Purge them"), "k": "purge"}, {"t": _t("Görmezden gel", "Ignore it"), "k": "ignore"}]
	gs.pol.pending = {"title": title, "body": body, "choices": ch, "kind": "coup", "icon": Icons.pick("reform" if r == "democracy" else "generals_plot", "")}
	gs.pol_card.emit()


## Oyuncunun seçimi. Dönüş: sonuç metni
static func choose(gs, idx: int) -> String:
	ensure(gs)
	var pend: Dictionary = gs.pol.pending
	if pend.is_empty():
		return ""
	var ch: Array = pend.get("choices", [])
	if idx < 0 or idx >= ch.size():
		return ""
	var k: String = String(ch[idx].get("k", ""))
	gs.pol.pending = {}
	var c = gs.countries[gs.player]
	var inc: float = maxf(c.income, 1.0)
	var res := ""
	match k:
		"early":
			c.elect_turn = gs.turn + 1
			c.stability = clampf(c.stability + 3.0, 5.0, 100.0)
			gs.pol.risk_cd[str(gs.player)] = gs.turn + 26
			res = _t("Erken seçim ilan edildi; sokaklar sakinleşti.", "Early elections were called; the streets calmed.")
		"martial":
			start_martial(gs)
			res = _t("Sıkıyönetim ilan edildi.", "Martial law was declared.")
		"reform":
			c.gold = maxf(0.0, c.gold - inc * 1.5)
			c.stability = clampf(c.stability + 6.0, 5.0, 100.0)
			gs.pol.risk_cd[str(gs.player)] = gs.turn + 20
			res = _t("Reform paketi açıklandı; protestolar yatıştı.", "A reform package was announced; the protests eased.")
		"pay":
			c.gold = maxf(0.0, c.gold - inc * 6.0)
			gs.pol.risk_cd[str(gs.player)] = gs.turn + 26
			res = _t("Subaylara ikramiye dağıtıldı; darbe fikri rafa kalktı.", "The officers were paid off; the coup plan was shelved.")
		"purge":
			c.stability = clampf(c.stability - 6.0, 5.0, 100.0)
			c.troops = int(c.troops * 0.95)
			gs.pol.risk_cd[str(gs.player)] = gs.turn + 52
			res = _t("Komplocular tasfiye edildi. Ordu sessiz ama tedirgin.", "The plotters were purged. The army is quiet but uneasy.")
		"ignore":
			if gs.rng.randf() < 0.30 + 0.25 * maxf(0.0, (45.0 - c.stability) / 45.0):
				res = _player_coup(gs, c)
			else:
				gs.pol.risk_cd[str(gs.player)] = gs.turn + 12
				res = _t("Komplo kendiliğinden dağıldı.", "The plot fizzled out on its own.")
	gs.post_news(res, c.capital, "event_player")
	return res


## Generaller yönetimi aldı: oyun devam eder, ama yeni bir düzende
static func _player_coup(gs, c) -> String:
	var nm: String = _new_leader(gs, c, "pcoup")
	gs.pol.reg[str(gs.player)] = "junta"
	c.stability = clampf(c.stability - 18.0, 10.0, 100.0)
	c.gold *= 0.85
	gs.pol.risk_cd[str(gs.player)] = gs.turn + 40
	return _t("Generaller yönetime el koydu. Yeni lider %s; ülke askerî yönetime geçti.", "The generals seized power. New leader %s; the country is now under military rule.") % nm


# ------------------------------------------------------------------ oyuncunun siyasi eylemleri

static func start_martial(gs) -> void:
	ensure(gs)
	gs.pol.martial[str(gs.player)] = gs.turn + MARTIAL_WEEKS
	gs.pol.reform[str(gs.player) + "_mart"] = gs.turn + MARTIAL_WEEKS + 52


## UI için eylem listesi: [{id, label, desc, ok, why}]
static func actions(gs) -> Array:
	ensure(gs)
	var r: String = regime(gs, gs.player)
	var out: Array = []
	var cd_left: int = int(gs.pol.reform.get(str(gs.player), 0)) - gs.turn
	var mart_left: int = int(gs.pol.reform.get(str(gs.player) + "_mart", 0)) - gs.turn
	if r != "democracy":
		out.append({"id": "democratize", "label": _t("Demokratikleşme", "Democratize"),
			"desc": _t("Seçimli sisteme geç: istikrar −10 şimdi, meşruiyet ve gelir kalıcı artar.", "Move to a system with elections: stability −10 now; legitimacy and income rise permanently."),
			"ok": cd_left <= 0, "why": _t("%d hafta sonra", "in %d weeks") % cd_left if cd_left > 0 else ""})
	if r == "democracy" or r == "monarchy":
		out.append({"id": "centralize", "label": _t("Yetkileri merkezileştir", "Centralize power"),
			"desc": _t("Otoriter yönetime geç: istikrar +8, savaş yorgunluğu biter; gelir −%2, dünya tepkisi artar.", "Move to authoritarian rule: stability +8, no war weariness; income −2%, world backlash grows."),
			"ok": cd_left <= 0, "why": _t("%d hafta sonra", "in %d weeks") % cd_left if cd_left > 0 else ""})
	out.append({"id": "martial", "label": _t("Sıkıyönetim (12 hafta)", "Martial law (12 weeks)"),
		"desc": _t("İstikrar haftada +0,5, darbe riski düşer; gelir −%8, dünya tepkisi artar.", "Stability +0.5 per week and lower coup risk; income −8%, world backlash grows."),
		"ok": mart_left <= 0 and not martial_on(gs, gs.player), "why": _t("%d hafta sonra", "in %d weeks") % mart_left if mart_left > 0 else ""})
	return out


static func do_action(gs, id: String) -> String:
	ensure(gs)
	var c = gs.countries[gs.player]
	var key: String = str(gs.player)
	match id:
		"democratize":
			gs.pol.reg[key] = "democracy"
			c.stability = clampf(c.stability - 10.0, 5.0, 100.0)
			c.elect_turn = gs.turn + 104
			gs.pol.reform[key] = gs.turn + REFORM_COOLDOWN
			gs.post_news(_t("%s seçimli bir sisteme geçti.", "%s moved to a system with elections.") % c.name, c.capital, "event_player")
			return _t("Demokratikleşme başladı.", "Democratization has begun.")
		"centralize":
			gs.pol.reg[key] = "authoritarian"
			c.stability = clampf(c.stability + 8.0, 5.0, 100.0)
			gs.infamy = minf(100.0, gs.infamy + 8.0)
			gs.pol.reform[key] = gs.turn + REFORM_COOLDOWN
			gs.post_news(_t("%s'de yetkiler merkezileştirildi.", "Power was centralized in %s.") % c.name, c.capital, "event_player")
			return _t("Yetkiler merkezileştirildi.", "Power was centralized.")
		"martial":
			start_martial(gs)
			gs.post_news(_t("%s'de sıkıyönetim ilan edildi.", "Martial law declared in %s.") % c.name, c.capital, "event_player")
			return _t("Sıkıyönetim ilan edildi.", "Martial law was declared.")
	return ""
