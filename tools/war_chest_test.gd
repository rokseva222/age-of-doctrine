extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
func _init() -> void:
	for era in ["ww1", "ww2"]:
		Eras.prepare(era)
		var gs = GS.new()
		gs.new_world(7)
		Eras.restructure(gs, era)
		var g: int = gs.macro_idx.get("Germany", -1)
		var c = gs.countries[g]
		gs.start_game(g)
		var g0: float = c.gold
		Eras.start(gs, era)
		print(era, " Almanya düşman=", c.enemies.size(), " kasa ", int(g0), " -> ", int(c.gold), " (gelir ", int(c.income), ")")
	quit()
