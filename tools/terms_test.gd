extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(9)
	var me: int = gs.macro_idx.get("Turkey", 0)
	gs.start_game(me)
	var en: int = gs.macro_idx.get("Greece", 1)
	gs.declare_war(me, en, true)
	var w = gs.get_war(me, en)
	gs.countries[en].gold = 1000.0
	var g0: float = gs.countries[me].gold
	var sz0 := 0
	for a in gs.armies.values():
		if a.owner == en: sz0 += a.size
	gs.finish_peace(w, me, [], ["reparations", "disarm", "buffer"])
	var sz1 := 0
	for a in gs.armies.values():
		if a.owner == en: sz1 += a.size
	print("altın +", gs.countries[me].gold - g0, " rakip altın ", gs.countries[en].gold, " ordu ", sz0, "->", sz1, " ateşkes ", gs.countries[me].truce[en] - gs.turn)
	quit()
