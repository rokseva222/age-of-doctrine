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

const REGIMES := ["democracy", "constitutional", "monarchy", "authoritarian", "communist", "junta", "fascist", "theocracy", "colonial", "feudal"]
const NAME_TR := {"democracy": "Demokrasi", "monarchy": "Monarşi", "authoritarian": "Otoriter yönetim", "communist": "Tek parti (komünist)", "junta": "Askerî yönetim", "fascist": "Faşist rejim", "constitutional": "Meşruti monarşi", "theocracy": "Teokrasi", "colonial": "Sömürge yönetimi", "feudal": "Feodal krallık"}
const NAME_EN := {"democracy": "Democracy", "monarchy": "Monarchy", "authoritarian": "Authoritarian rule", "communist": "One-party (communist)", "junta": "Military rule", "fascist": "Fascist rule", "constitutional": "Constitutional monarchy", "theocracy": "Theocracy", "colonial": "Colonial administration", "feudal": "Feudal kingdom"}
const DESC_TR := {
	"democracy": "Düzenli seçimler, güçlü meşruiyet ve ticaret. Savaş yorgunluğu istikrarı çabuk aşındırır; darbe riski çok düşüktür.",
	"monarchy": "Köklü hanedan; istikrar yavaş ve sağlam. Darbe riski düşük, ama reform esnekliği sınırlı.",
	"authoritarian": "Güçlü merkez: istikrar toparlanır, savaş yorgunluğu azdır. Verimlilik düşük, darbe riski orta.",
	"communist": "Planlı ekonomi ve sıkı örgütlenme: istikrar sağlam. Dış ticaret kısıtlı, darbe riski düşük-orta.",
	"junta": "Ordu iktidarda: savaş yorgunluğu yok ama ekonomi verimsiz; darbe riski yüksek.",
	"fascist": "Tek lider, milliyetçi seferberlik: istikrar sağlam, savaş yorgunluğu yok. Dünya tepkisi sert, ekonomi biraz verimsiz.",
	"constitutional": "Hanedan simgesel, yönetim seçilmiş meclisin elinde: meşruiyet ve ticaret güçlü, darbe riski çok düşük. Savaş yorgunluğu demokrasiden biraz hafif.",
	"theocracy": "Din adamları yönetir: istikrar sağlam, savaş yorgunluğu çok az. Ekonomi ve dış ticaret verimsiz, laik dünya mesafeli durur.",
	"colonial": "Metropolün atadığı valiler yönetir: istikrar yavaş ve sakin, ama gelir düşük ve halk bağımsızlık ister.",
	"feudal": "Krala bağlı soylular ve toprak ağaları: istikrar orta, savaş yorgunluğu düşük. Beyler güçlenirse hanedan içi darbe riski vardır.",
}
const DESC_EN := {
	"democracy": "Regular elections, strong legitimacy and trade. War weariness erodes stability quickly; coup risk is very low.",
	"monarchy": "An old dynasty: stability is slow and firm. Low coup risk, but little reform flexibility.",
	"authoritarian": "A strong center: stability recovers, little war weariness. Lower efficiency, moderate coup risk.",
	"communist": "Planned economy and tight organization: solid stability. Limited foreign trade, low-to-moderate coup risk.",
	"junta": "The army rules: no war weariness but an inefficient economy; high coup risk.",
	"fascist": "One leader and nationalist mobilization: firm stability, no war weariness. Harsh world reaction, a slightly inefficient economy.",
	"constitutional": "A symbolic dynasty with an elected parliament governing: strong legitimacy and trade, very low coup risk. War weariness is a little milder than in a democracy.",
	"theocracy": "Clerics rule: firm stability, very little war weariness. The economy and foreign trade are inefficient, and the secular world keeps its distance.",
	"colonial": "Governors appointed by the mother country rule: stability is slow and quiet, but income is low and the people want independence.",
	"feudal": "Nobles and landlords bound to the crown: middling stability, low war weariness. If the barons grow strong, palace coups threaten.",
}
const INCOME := {"democracy": 1.02, "monarchy": 1.0, "authoritarian": 0.98, "communist": 1.0, "junta": 0.96, "fascist": 0.97, "constitutional": 1.02, "theocracy": 0.97, "colonial": 0.95, "feudal": 0.97}
const STAB_DRIFT := {"democracy": 0.0, "monarchy": 0.05, "authoritarian": 0.08, "communist": 0.06, "junta": 0.03, "fascist": 0.07, "constitutional": 0.04, "theocracy": 0.08, "colonial": 0.05, "feudal": 0.05}
const WAR_WEARY := {"democracy": 0.10, "monarchy": 0.04, "authoritarian": 0.0, "communist": 0.02, "junta": 0.0, "fascist": 0.0, "constitutional": 0.07, "theocracy": 0.01, "colonial": 0.0, "feudal": 0.03}
const COUP_BASE := {"democracy": 0.0, "monarchy": 0.0012, "authoritarian": 0.004, "communist": 0.0015, "junta": 0.008, "fascist": 0.003, "constitutional": 0.0004, "theocracy": 0.0025, "colonial": 0.0008, "feudal": 0.0025}
const CHECK_EVERY := 4
const REFORM_COOLDOWN := 104
const MARTIAL_WEEKS := 12

# Modern: demokrasi dışındaki rejimler (kalanı demokrasi). Tarafsız, genel sınıflandırma.
const MODERN := {
	"China": "communist", "Vietnam": "communist", "Cuba": "communist", "Laos": "communist", "North Korea": "communist",
	"Russia": "authoritarian", "Belarus": "authoritarian", "Egypt": "authoritarian", "Syria": "authoritarian",
	"Venezuela": "authoritarian", "Azerbaijan": "authoritarian", "Kazakhstan": "authoritarian", "Uzbekistan": "authoritarian",
	"Turkmenistan": "authoritarian", "Tajikistan": "authoritarian", "Kyrgyzstan": "authoritarian", "Eritrea": "authoritarian",
	"Rwanda": "authoritarian", "Cameroon": "authoritarian", "Algeria": "authoritarian",
	"Nicaragua": "authoritarian", "Zimbabwe": "authoritarian", "Eq. Guinea": "authoritarian",
	"Chad": "authoritarian", "Congo": "authoritarian", "Djibouti": "authoritarian", "Uganda": "authoritarian", "Libya": "authoritarian",
	"Iran": "theocracy", "Afghanistan": "theocracy", "Vatican": "theocracy",
	"United Kingdom": "constitutional", "Spain": "constitutional", "Sweden": "constitutional", "Norway": "constitutional", "Denmark": "constitutional",
	"Netherlands": "constitutional", "Belgium": "constitutional", "Japan": "constitutional", "Thailand": "constitutional", "Luxembourg": "constitutional",
	"Malaysia": "constitutional", "Bhutan": "constitutional", "Lesotho": "constitutional", "Tonga": "constitutional", "Liechtenstein": "constitutional",
	"Monaco": "constitutional", "Andorra": "constitutional", "Cambodia": "constitutional",
	"Saudi Arabia": "monarchy", "United Arab Emirates": "monarchy", "Qatar": "monarchy", "Kuwait": "monarchy", "Oman": "monarchy",
	"Bahrain": "monarchy", "Jordan": "monarchy", "Morocco": "monarchy", "Brunei": "monarchy", "eSwatini": "monarchy",
	"Myanmar": "junta", "Sudan": "junta", "Mali": "junta", "Burkina Faso": "junta", "Niger": "junta", "Guinea": "junta", "Gabon": "junta",
}
const ERA := {
	"ww1": {
		"constitutional": ["United Kingdom", "Italy", "Belgium", "Netherlands", "Sweden", "Norway", "Denmark", "Japan", "Spain", "Greece", "Romania", "Bulgaria"],
		"monarchy": ["Germany", "Austria", "Russia", "Turkey", "Serbia", "Thailand", "Iran", "Ethiopia", "Montenegro"],
		"democracy": ["United States of America", "France", "Switzerland", "Brazil", "Argentina", "Canada", "Australia", "New Zealand", "Portugal", "Chile", "Uruguay"],
		"default": "authoritarian",
	},
	"ww2": {
		"fascist": ["Germany", "Italy", "Spain"],
		"authoritarian": ["Japan", "Portugal", "Turkey", "China", "Romania", "Hungary", "Bulgaria", "Greece", "Poland", "Slovakia", "Brazil"],
		"communist": ["Russia"],
		"constitutional": ["Iraq", "Egypt"],
		"monarchy": ["Saudi Arabia", "Iran", "Ethiopia", "Thailand"],
		"democracy": ["United States of America", "United Kingdom", "France", "Canada", "Australia", "New Zealand", "South Africa", "Netherlands", "Belgium",
			"Sweden", "Norway", "Denmark", "Switzerland", "Czechia", "Ireland", "Finland", "Mexico", "Chile", "Argentina"],
		"default": "authoritarian",
	},
	"cold": {
		"communist": ["Russia", "China", "Poland", "Czechia", "Hungary", "Romania", "Bulgaria", "Albania", "Cuba", "Serbia", "Vietnam", "North Korea", "Mongolia"],
		"constitutional": ["United Kingdom", "Netherlands", "Belgium", "Sweden", "Norway", "Denmark", "Luxembourg", "Japan", "Thailand", "Libya"],
		"monarchy": ["Saudi Arabia", "Iran", "Jordan", "Morocco", "Ethiopia", "Nepal", "Kuwait"],
		"democracy": ["United States of America", "United Kingdom", "France", "Germany", "Italy", "Canada", "Belgium", "Netherlands", "Luxembourg", "Denmark",
			"Norway", "Iceland", "Greece", "Turkey", "India", "Japan", "Australia", "New Zealand", "Israel", "Sweden", "Switzerland", "Ireland", "Austria", "Finland"],
		"default": "authoritarian",
	},
}


static func _tr() -> bool:
	return Loc.lang == "tr"


static func name_of(r: String) -> String:
	return String(NAME_TR[r]) if _tr() else Loc.t(String(NAME_TR[r]))


## Simge: regime_<kod> (varsa) yoksa genel rejim simgesi
static func icon(r: String) -> String:
	return Icons.pick("regime_" + r, "regime")


static func desc_of(r: String) -> String:
	return String(DESC_TR[r]) if _tr() else String(DESC_EN[r])


static func ensure(gs) -> void:
	if not (gs.pol is Dictionary):
		gs.pol = {}
	for k in ["reg", "elect", "cd", "martial", "risk_cd", "pending", "reform"]:
		if not gs.pol.has(k):
			gs.pol[k] = {}


static func _default_regime(name_en: String, continent: String = "") -> String:
	var fam: String = Eras.family()
	if Eras.current != "" and fam != "pre" and Eras._colony_names(Eras.current).has(name_en):
		return "colonial"
	if fam == "pre":
		return "feudal" if (continent == "Europe" or name_en == "Japan") else "monarchy"
	if fam == "ww1" or fam == "ww2" or fam == "cold":
		var t: Dictionary = ERA[fam]
		for r in ["constitutional", "fascist", "communist", "monarchy", "democracy", "authoritarian"]:
			if t.has(r) and (t[r] as Array).has(name_en):
				return String(r)
		return String(t["default"])
	return String(MODERN.get(name_en, "democracy"))


static func regime(gs, cid: int) -> String:
	ensure(gs)
	var key := str(cid)
	if not gs.pol.reg.has(key):
		gs.pol.reg[key] = _default_regime(String(gs.countries[cid].name_en), String(gs.countries[cid].continent))
	return String(gs.pol.reg[key])


static func has_elections(gs, cid: int) -> bool:
	var rg: String = regime(gs, cid)
	return rg == "democracy" or rg == "constitutional"


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
	if (r == "democracy" or r == "constitutional") and c.stability < 25.0:
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
	if c.id != gs.player and (r == "democracy" or r == "constitutional"):
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
		var pre_e: bool = Macro.era_on and Eras.family() == "pre"
		var cm: String = ("SARAY DARBESİ: %s'de hanedan içi darbe; yeni hükümdar %s." if pre_e else "DARBE: %s'de ordu yönetime el koydu; yeni lider %s.") if _tr() else ("PALACE COUP: a coup inside the %s court; new ruler %s." if pre_e else "COUP: the army seized power in %s; new leader %s.")
		gs.post_news(cm % [c.name, nm], c.capital, "event")


# ------------------------------------------------------------------ oyuncu uyarı kartları

static func _t(tr: String, en: String) -> String:
	return tr if _tr() else en


static func _player_card(gs, c, r: String) -> void:
	var inc: float = maxf(c.income, 1.0)
	var title := ""
	var body := ""
	var ch: Array = []
	if r == "democracy" or r == "constitutional":
		title = _t("Kitlesel Protestolar", "Mass Protests")
		body = _t("Başkentte yüz binler sokakta; hükûmetin istifası isteniyor. Meclis bölünmüş durumda.", "Hundreds of thousands are on the streets of the capital demanding the government resign. Parliament is divided.")
		ch = [{"t": _t("Erken seçim ilan et", "Call early elections"), "k": "early"}, {"t": _t("Sıkıyönetim", "Martial law"), "k": "martial"}, {"t": _t("Reform sözü ver", "Promise reforms"), "k": "reform"}]
	else:
		title = _t("Darbe Hazırlığı", "Coup Plot")
		body = _t("İstihbarat, bir grup generalin hükûmeti devirmek için toplandığını bildiriyor. Ne yapalım?", "Intelligence reports that a group of generals has met to overthrow the government. What do we do?")
		ch = [{"t": _t("Generallere ikramiye ver", "Pay off the generals"), "k": "pay"}, {"t": _t("Tasfiye et", "Purge them"), "k": "purge"}, {"t": _t("Görmezden gel", "Ignore it"), "k": "ignore"}]
	gs.pol.pending = {"title": title, "body": body, "choices": ch, "kind": "coup", "icon": Icons.pick("reform" if (r == "democracy" or r == "constitutional") else "generals_plot", "")}
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


## Rejim değiştirme eylemleri: id → hedef rejim, istikrar farkı, kötü şöhret, demokrasilerle ilişki farkı.
const SHIFT := {
	"democratize": {"to": "democracy", "stab": -10.0, "infamy": 0.0, "rel": 0.0},
	"constitutionalize": {"to": "constitutional", "stab": -6.0, "infamy": 0.0, "rel": 0.0},
	"monarchize": {"to": "monarchy", "stab": -10.0, "infamy": 4.0, "rel": 0.0},
	"centralize": {"to": "authoritarian", "stab": 8.0, "infamy": 8.0, "rel": 0.0},
	"fascize": {"to": "fascist", "stab": 6.0, "infamy": 15.0, "rel": -8.0},
	"communize": {"to": "communist", "stab": 4.0, "infamy": 8.0, "rel": -5.0},
	"theocratize": {"to": "theocracy", "stab": 5.0, "infamy": 6.0, "rel": -4.0},
}


## Eylemin hedef rejimi (simge seçimi için)
static func target_of(id: String) -> String:
	if id == "centralize" and Macro.era_on and Eras.family() == "pre":
		return "monarchy"
	return String(SHIFT.get(id, {}).get("to", ""))


static func _shift_desc(id: String) -> String:
	match id:
		"democratize":
			return _t("Seçimli sisteme geç: istikrar −10 şimdi, meşruiyet ve gelir kalıcı artar.", "Move to a system with elections: stability −10 now; legitimacy and income rise permanently.")
		"constitutionalize":
			return _t("Hanedanı korurken yetkiyi seçilmiş meclise ver: istikrar −6 şimdi, meşruiyet ve ticaret artar, darbe riski çok düşer.", "Keep the dynasty but hand power to an elected parliament: stability −6 now; legitimacy and trade rise, coup risk drops.")
		"monarchize":
			return _t("Hanedan düzenine dön: istikrar −10 şimdi, sonra yavaş ve sağlam; savaş yorgunluğu düşük, dünya tepkisi hafif artar.", "Return to dynastic rule: stability −10 now, then slow and firm; low war weariness, mild world backlash.")
		"centralize":
			if Macro.era_on and Eras.family() == "pre":
				return _t("Soyluların gücünü kır, yetkiyi tahtta topla: mutlak monarşi. İstikrar +8, savaş yorgunluğu azalır; dünya tepkisi artar.", "Break the nobles and gather power in the throne: absolute monarchy. Stability +8, less war weariness; backlash grows.")
			return _t("Otoriter yönetime geç: istikrar +8, savaş yorgunluğu biter; gelir −%2, dünya tepkisi artar.", "Move to authoritarian rule: stability +8, no war weariness; income −2%, world backlash grows.")
		"fascize":
			return _t("Tek lider ve milliyetçi seferberlik: istikrar +6, savaş yorgunluğu biter; gelir −%3, dünya tepkisi çok sert artar, demokrasilerle ilişkiler bozulur.", "One leader and nationalist mobilization: stability +6, no war weariness; income −3%, a very harsh world backlash and worse ties with democracies.")
		"communize":
			return _t("Tek parti ve planlı ekonomi: istikrar +4, gelir sabit; dünya tepkisi artar, demokrasilerle ilişkiler bozulur.", "One party and a planned economy: stability +4, steady income; backlash grows and ties with democracies worsen.")
		"theocratize":
			return _t("Din adamları yönetimi devralır: istikrar +5, savaş yorgunluğu çok azalır; gelir −%3, laik ülkelerle ilişkiler bozulur.", "Clerics take over government: stability +5, much less war weariness; income −3%, ties with secular states worsen.")
	return ""


static func _shift_label(id: String) -> String:
	match id:
		"democratize": return _t("Demokratikleşme", "Democratize")
		"constitutionalize": return _t("Meşruti monarşiye geç", "Become a constitutional monarchy")
		"monarchize": return _t("Monarşi ilan et", "Restore the monarchy")
		"centralize": return _t("Mutlak monarşi (merkezileştir)", "Absolute monarchy (centralize)") if (Macro.era_on and Eras.family() == "pre") else _t("Yetkileri merkezileştir", "Centralize power")
		"fascize": return _t("Faşist düzene geç", "Adopt fascist rule")
		"communize": return _t("Tek parti rejimine geç", "Adopt one-party rule")
		"theocratize": return _t("Teokrasi ilan et", "Declare a theocracy")
	return id


## UI için eylem listesi: [{id, label, desc, ok, why}]
static func actions(gs) -> Array:
	ensure(gs)
	var r: String = regime(gs, gs.player)
	var out: Array = []
	var cd_left: int = int(gs.pol.reform.get(str(gs.player), 0)) - gs.turn
	var mart_left: int = int(gs.pol.reform.get(str(gs.player) + "_mart", 0)) - gs.turn
	var fam: String = Eras.family() if Macro.era_on else ""
	var why: String = _t("%d hafta sonra", "in %d weeks") % cd_left if cd_left > 0 else ""
	var ids: Array = []
	if fam != "pre":
		if r != "democracy":
			ids.append("democratize")
		if r in ["monarchy", "feudal", "colonial", "authoritarian"] or (fam == "" and r == "junta"):
			ids.append("constitutionalize")
		if r in ["democracy", "constitutional", "colonial"]:
			ids.append("monarchize")
		if r in ["democracy", "constitutional", "monarchy", "colonial", "junta", "communist"]:
			ids.append("centralize")
		if fam != "ww1" and r != "fascist":
			ids.append("fascize")
		if fam != "ww1" and r != "communist":
			ids.append("communize")
		if r != "theocracy":
			ids.append("theocratize")
	else:
		if r == "feudal":
			ids.append("centralize")
	for id in ids:
		out.append({"id": id, "label": _shift_label(id), "desc": _shift_desc(id), "ok": cd_left <= 0, "why": why})
	out.append({"id": "martial", "label": _t("Sıkıyönetim (12 hafta)", "Martial law (12 weeks)"),
		"desc": _t("İstikrar haftada +0,5, darbe riski düşer; gelir −%8, dünya tepkisi artar.", "Stability +0.5 per week and lower coup risk; income −8%, world backlash grows."),
		"ok": mart_left <= 0 and not martial_on(gs, gs.player), "why": _t("%d hafta sonra", "in %d weeks") % mart_left if mart_left > 0 else ""})
	return out


static func do_action(gs, id: String) -> String:
	ensure(gs)
	var c = gs.countries[gs.player]
	var key: String = str(gs.player)
	if id == "martial":
		start_martial(gs)
		gs.post_news(_t("%s'de sıkıyönetim ilan edildi.", "Martial law declared in %s.") % c.name, c.capital, "event_player")
		return _t("Sıkıyönetim ilan edildi.", "Martial law was declared.")
	if not SHIFT.has(id):
		return ""
	var sh: Dictionary = SHIFT[id]
	var to: String = target_of(id)
	gs.pol.reg[key] = to
	c.stability = clampf(c.stability + float(sh.stab), 5.0, 100.0)
	gs.infamy = minf(100.0, gs.infamy + float(sh.infamy))
	gs.pol.reform[key] = gs.turn + REFORM_COOLDOWN
	if id == "democratize":
		c.elect_turn = gs.turn + 104
	if float(sh.rel) != 0.0:
		for o in gs.countries:
			if o.alive and not o.is_rebel and o.id != gs.player and (regime(gs, o.id) == "democracy" or regime(gs, o.id) == "constitutional"):
				gs.relation_add(gs.player, o.id, float(sh.rel))
	var nm: String = name_of(to)
	gs.post_news(_t("%s yönetim biçimini değiştirdi: %s.", "%s changed its form of government: %s.") % [c.name, nm], c.capital, "event_player")
	return _t("Yönetim biçimi değişti: %s.", "Form of government changed: %s.") % nm
