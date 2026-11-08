extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Names = preload("res://scripts/names.gd")
func _init() -> void:
	for id in ["ww2", "ww1"]:
		Eras.prepare(id)
		var g = GS.new(); g.new_world(5)
		Eras.restructure(g, id)
		g.start_game(g.macro_idx.get("Turkey", 0))
		Eras.start(g, id)
		var seen := 0
		g.news_posted.connect(func(t, _p, k): if k == "event": seen += 1; print("  ", Names.date_string(g.turn), " ", String(t).substr(0, 70)))
		var yrs := 8 if id == "ww2" else 26
		for t in yrs * 52: g.end_turn()
		print("== ", id, " olay haberi: ", seen, " savaş: ", g.wars.size())
	Eras.clear()
	quit()
