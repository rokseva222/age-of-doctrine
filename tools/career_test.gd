extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Career = preload("res://scripts/career.gd")
func _init() -> void:
	var fails := 0
	for era in ["ott1520", ""]:
		var g = GS.new()
		Eras.prepare(era)
		g.new_world(5)
		if era != "":
			Eras.restructure(g, era)
		var host_en := "Turkey"
		g.start_game(g.macro_idx.get(host_en, 0))
		if era != "":
			Eras.start(g, era)
		var ok: bool = Career.begin(g, {"host_en": host_en, "bg": "cavalry", "name": "Test Bey"})
		if not ok:
			print("FAIL begin ", era); fails += 1; continue
		g.countries[g.player].gold = 1.0e12
		for id in ["policy", "policy", "hire_komutan", "hire_katip", "hire_casus", "hire_hekim", "policy"]:
			var r: String = Career.do_action(g, id)
			if r != "":
				print("action ", id, " -> ", r)
		print(era, " policy=", g.career.policy, " companions=", g.career.companions.size())
		if g.career.companions.size() != 4: fails += 1
		for t in 60:
			g.end_turn()
			g.career["pending"] = {}
		print(era, " 60 tur ok, tur=", g.turn, " altin=", g.countries[g.player].gold > 0.0)
	print("CAREER_FAILS=", fails)
	quit()
