extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Macro = preload("res://scripts/macro.gd")
const Names = preload("res://scripts/names.gd")

func _init() -> void:
	var watch := ["Turkey", "United Kingdom", "Germany", "France", "Thailand"]
	for id in ["ww1", "ww2"]:
		Eras.prepare(id)
		var g = GS.new()
		g.new_world(777)
		Eras.restructure(g, id)
		var idx: Dictionary = {}
		for c in g.countries:
			idx[c.name_en] = c.id
		var pl: int = idx["Japan"]
		g.start_game(pl)
		Eras.start(g, id)
		var last: Dictionary = {}
		var years := 26 if id == "ww1" else 14
		for t in years * 52:
			g.end_turn()
			for n in watch:
				var c = g.countries[idx[n]]
				if last.get(n, "") != c.leader:
					last[n] = c.leader
					print(id, " ", Names.date_string(g.turn), " ", n, " -> ", c.leader)
		print("== ", id, " bitti ", Names.date_string(g.turn))
	Eras.clear()
	quit()
