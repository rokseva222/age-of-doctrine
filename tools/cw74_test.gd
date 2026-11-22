extends SceneTree
## Kıbrıs 1974 çağı duman testi: oyuncu ülkesiyle başlat, kartı seç, 60 tur oyna, Kıbrıs adasının durumunu yaz.
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Names = preload("res://scripts/names.gd")
const Macro = preload("res://scripts/macro.gd")
const EraMoments = preload("res://scripts/era_moments.gd")

func _dump(g, tag: String) -> void:
	var s := "  [%s] %s |" % [tag, Names.date_string(g.turn)]
	for n in ["Turkey", "Greece", "Cyprus", "N. Cyprus"]:
		var c = g.countries[g.macro_idx[n]]
		s += " %s:%s e=%d a=%d st=%.0f" % [n, "+" if c.alive else "x", c.prov_owned, c.troops, c.stability]
	print(s)
	var o := "     ada:"
	for pid in [1747, 1748, 1749, 2747, 2748, 1801]:
		var p = g.provinces[pid]
		o += " %s o=%s c=%s" % [p.name, g.countries[p.owner].name_en, g.countries[p.controller].name_en]
	print(o)
	var ws := ""
	for w in g.wars:
		var wa = g.countries[w.a]
		var wb = g.countries[w.b]
		if wa.name_en in ["Turkey","Greece","Cyprus","N. Cyprus","United Kingdom","Vietnam","Brunei"] or wb.name_en in ["Turkey","Greece","Cyprus","N. Cyprus"]:
			ws += " %s-%s" % [wa.name_en, wb.name_en]
	print("     savaslar:", ws)
	print("     toplam: ", g.wars.size(), " TR-CY:", g.at_war(g.macro_idx["Turkey"], g.macro_idx["Cyprus"]), " TR-GR:", g.at_war(g.macro_idx["Turkey"], g.macro_idx["Greece"]))

func _init() -> void:
	var who: String = OS.get_environment("WHO") if OS.get_environment("WHO") != "" else "Turkey"
	var pick: int = int(OS.get_environment("PICK")) if OS.get_environment("PICK") != "" else 0
	var id := "cw74"
	Eras.prepare(id)
	var g = GS.new()
	g.new_world(777)
	Eras.restructure(g, id)
	var me: int = g.macro_idx.get(who, 0)
	g.start_game(me)
	Eras.start(g, id)
	print("== cw74 başlıyor, oyuncu: ", g.countries[me].name, " lider: ", Macro.leader_of(g.countries[me]))
	_dump(g, "baş")
	for n in ["Turkey", "Greece", "Cyprus", "N. Cyprus", "United Kingdom"]:
		var c = g.countries[g.macro_idx[n]]
		print("   ", n, " ad=", c.name, " nüfus=%.2f gsyh=%.0f asker=%d lider=%s" % [c.pop, c.gdp, c.troops, c.leader])
	var guard := 0
	for t in 60:
		if not g.moment_pending.is_empty():
			var card: Dictionary = EraMoments.card(g)
			print("  KART: ", card.get("title"), " | ", (card.get("options") as Array).size(), " seçenek, rol=", g.moment_pending.role)
			EraMoments.choose(g, mini(pick, maxi(0, (card.get("options") as Array).size() - 1)))
			_dump(g, "kart sonrası")
		g.end_turn()
		if t % 10 == 9:
			_dump(g, "t%d" % t)
	print("haber son 8:")
	var nw: Array = g.news_log.slice(maxi(0, g.news_log.size() - 8))
	for x in nw:
		print("   ", x.get("text", x))
	quit()
