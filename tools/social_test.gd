extends SceneTree
## İlişki bozma + savaş şartı + ticaret anlaşması + sipariş etkisi + savaşsız Dünya Savaşı başlangıcı
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Settings = preload("res://scripts/settings.gd")
const Macro = preload("res://scripts/macro.gd")
func ck(name: String, ok: bool) -> int:
	print(("OK   " if ok else "FAIL ") + name)
	return 0 if ok else 1
func _init() -> void:
	var f := 0
	Settings.tut_done = true
	Settings.sandbox = false
	Settings.war_gate = true
	var g = GS.new()
	g.new_world(5)
	g.start_game(g.macro_idx.get("Turkey", 0))
	g.countries[g.player].gold = 1.0e9
	var nb: int = -1
	for c in g.neighbor_countries(g.player):
		if not g.at_war(g.player, c) and not g.is_allied(g.player, c) and g.countries[c].alive and not g.countries[c].is_rebel:
			nb = c
			break
	g.countries[g.player].relation[nb] = 60.0
	g.countries[nb].relation[g.player] = 60.0
	f += ck("savaş şartı: ilişki 60 -> engel", g.war_gate_error(nb) != "")
	# ticaret
	var gold0: float = g.countries[g.player].gold
	f += ck("ticaret imzalandı", g.player_sign_trade(nb) == "")
	var tg: float = g.trade_total()
	f += ck("ticaret kazancı > 0", tg > 0.0)
	var gold1: float = g.countries[g.player].gold
	g._trade_tick()
	f += ck("ticaret haftalık gelir", g.countries[g.player].gold > gold1)
	# kaydet/yükle
	var d: Dictionary = g.to_dict() if g.has_method("to_dict") else {}
	if not d.is_empty():
		var g2 = GS.new()
		g2.new_world(5)
		g2.from_dict(d)
		f += ck("ticaret kayıtta", g2.trade.has(nb))
	# ilişki bozma
	var tries := 0
	while g.relation_of(g.player, nb) > 20.0 and tries < 12:
		tries += 1
		for k in ["border", "smear", "protest"]:
			g.player_worsen_relations(nb, k)
		g.turn += 9      # bekleme sürelerini geç
	f += ck("ilişki bozuldu (<=20): %d" % int(g.relation_of(g.player, nb)), g.relation_of(g.player, nb) <= 20.0)
	f += ck("bozulunca ticaret bitti", not g.trade.has(nb))
	f += ck("savaş şartı geçti", g.war_gate_error(nb) == "")
	f += ck("savaş ilanı", g.player_declare_war(nb) == "")
	# gate kapalı
	Settings.war_gate = false
	var other: int = -1
	for c in g.neighbor_countries(g.player):
		if not g.at_war(g.player, c) and not g.is_allied(g.player, c) and g.countries[c].alive and not g.countries[c].is_rebel and c != nb:
			other = c
			break
	if other >= 0:
		g.countries[g.player].relation[other] = 70.0
		f += ck("gate kapalıyken engel yok", g.war_gate_error(other) == "")
	Settings.war_gate = true
	# sipariş etkisi
	var c0 = g.countries[g.player]
	Macro.ensure(g, c0)
	var shown := 0
	for cat in ["tank", "air", "sub", "inf"]:
		var lst: Array = Macro.Arsenal.list_cat(cat)
		for id in lst:
			if Macro.availability(g, c0, id) == "":
				var t: String = Macro.effect_text(c0, id, 10 * Macro.step_scale(c0, cat))
				print("   ", cat, ": ", Macro.Arsenal.name_of(id), " -> ", t)
				shown += 1
				break
	f += ck("sipariş etkisi metni", shown >= 3)
	# Dünya Savaşı savaşsız başlangıç
	for peace in [false, true]:
		Settings.era_peace = peace
		var h = GS.new()
		Eras.prepare("ww1")
		h.new_world(5)
		Eras.restructure(h, "ww1")
		h.start_game(h.macro_idx.get("Germany", 0))
		Eras.start(h, "ww1")
		print("   ww1 era_peace=", peace, " savaş sayısı=", h.wars.size())
		if peace:
			f += ck("savaşsız başladı", h.wars.size() == 0)
		else:
			f += ck("savaşlı başladı", h.wars.size() > 0)
		for t in 30:
			h.end_turn()
		Eras.clear()
	Settings.era_peace = false
	print("HATA SAYISI=", f)
	quit()
