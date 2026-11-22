extends SceneTree
## Çeçen savaşları çağ duman testi. ENV: ERA (ch94|ch94c|ch99|ch99c), WHO, PICK, TURNS
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Names = preload("res://scripts/names.gd")
const Macro = preload("res://scripts/macro.gd")
const EraMoments = preload("res://scripts/era_moments.gd")

func _dump(g, tag: String) -> void:
	var s := "  [%s] %s |" % [tag, Names.date_string(g.turn)]
	for n in ["Russia", "custom_0", "custom_1", "custom_2", "custom_3", "custom_4", "custom_5", "Turkey", "Georgia"]:
		if not g.macro_idx.has(n):
			continue
		var c = g.countries[g.macro_idx[n]]
		s += " %s:%s e=%d a=%d st=%.0f" % [n, "+" if c.alive else "x", c.prov_owned, c.troops, c.stability]
	print(s)
	var o := "     bölge:"
	for pid in [1851, 1850, 230, 1852]:
		var p = g.provinces[pid]
		o += " %s o=%s c=%s u=%d" % [p.name, g.countries[p.owner].name_en, g.countries[p.controller].name_en, p.unrest]
	print(o)
	if g.macro_idx.has("custom_0"):
		print("     RU-CH savaş:", g.at_war(g.macro_idx["Russia"], g.macro_idx["custom_0"]))

func _init() -> void:
	var id: String = OS.get_environment("ERA") if OS.get_environment("ERA") != "" else "ch94"
	var who: String = OS.get_environment("WHO") if OS.get_environment("WHO") != "" else "Russia"
	var pick: int = int(OS.get_environment("PICK")) if OS.get_environment("PICK") != "" else 0
	var turns: int = int(OS.get_environment("TURNS")) if OS.get_environment("TURNS") != "" else 60
	Eras.prepare(id)
	var g = GS.new()
	g.new_world(777)
	Eras.restructure(g, id)
	var me: int = g.macro_idx.get(who, 0)
	g.start_game(me)
	Eras.start(g, id)
	if g.scn_play >= 0:
		g.switch_player(g.scn_play)
		me = g.scn_play
	print("== ", id, " oyuncu: ", g.countries[me].name, " lider: ", Macro.leader_of(g.countries[me]))
	for n in ["Russia", "custom_0", "Turkey", "United States of America"]:
		if g.macro_idx.has(n):
			var c = g.countries[g.macro_idx[n]]
			print("   ", n, " ad=", c.name, " nüfus=%.2f gsyh=%.0f asker=%d lider=%s tech=%s" % [c.pop, c.gdp, c.troops, Macro.leader_of(c), str(c.get("tech"))])
	_dump(g, "baş")
	for t in turns:
		if not g.moment_pending.is_empty():
			var card: Dictionary = EraMoments.card(g)
			print("  KART: ", card.get("title"), " | ", (card.get("options") as Array).size(), " seçenek, rol=", g.moment_pending.role)
			EraMoments.choose(g, mini(pick, maxi(0, (card.get("options") as Array).size() - 1)))
			_dump(g, "kart sonrası")
		g.end_turn()
		if t % 10 == 9:
			_dump(g, "t%d" % t)
	print("haber son 6:")
	var nw: Array = g.news_log.slice(maxi(0, g.news_log.size() - 6))
	for x in nw:
		print("   ", x.get("text", x))
	quit()
