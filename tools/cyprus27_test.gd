extends SceneTree
## Modern Kıbrıs senaryosu duman testi: WHO=Turkey PICK=0 godot --headless --path . -s tools/cyprus27_test.gd
const GS = preload("res://scripts/game_state.gd")
const SC = preload("res://scripts/scenarios.gd")
const Names = preload("res://scripts/names.gd")
const EraMoments = preload("res://scripts/era_moments.gd")
const Objectives = preload("res://scripts/objectives.gd")

func _init() -> void:
	var who: String = OS.get_environment("WHO") if OS.get_environment("WHO") != "" else "Turkey"
	var pick: int = int(OS.get_environment("PICK")) if OS.get_environment("PICK") != "" else 0
	var id: String = OS.get_environment("SCN") if OS.get_environment("SCN") != "" else "cyprus27"
	var weeks: int = int(OS.get_environment("WEEKS")) if OS.get_environment("WEEKS") != "" else 60
	var g = GS.new()
	g.new_world(11)
	var me: int = g.macro_idx.get(who, 0)
	g.start_game(me)
	SC.apply(g, id)
	print("== ", id, " oyuncu=", g.countries[me].name, " tarih=", Names.date_string(g.turn))
	var cards := 0
	for t in weeks:
		if not g.moment_pending.is_empty():
			var card: Dictionary = EraMoments.card(g)
			cards += 1
			print("  KART t=%d: %s | rol=%s opt=%d" % [t, card.get("title"), g.moment_pending.role, (card.get("options") as Array).size()])
			if String(g.moment_pending.role) != "":
				EraMoments.choose(g, mini(pick, (card.get("options") as Array).size() - 1))
			else:
				g.moment_pending = {}
		g.end_turn()
	var s := ""
	for w in g.wars:
		var a = g.countries[w.a]
		var b = g.countries[w.b]
		if a.name_en in ["Turkey", "Greece", "Cyprus", "N. Cyprus"] or b.name_en in ["Turkey", "Greece", "Cyprus", "N. Cyprus"]:
			s += " %s-%s" % [a.name_en, b.name_en]
	print("  son tarih=", Names.date_string(g.turn), " kart=", cards, " savaşlar:", s, " bayraklar=", g.moment_flags.keys())
	var done: Array = []
	for k in g.scn.get("done", {}):
		done.append(k)
	print("  hedef tamam: ", done, " haber son 4:")
	for x in g.news_log.slice(maxi(0, g.news_log.size() - 4)):
		print("    ", x.get("text"))
	quit()
