extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(3)
	var me: int = gs.macro_idx.get("United States", 0)
	gs.start_game(me)
	var en: int = gs.macro_idx.get("Cuba", 1)
	print("hava gücü ben ", gs.countries[me].air_pow, " rakip ", gs.countries[en].air_pow)
	for op in ["assault", "air"]:
		print(op, " ", gs.op_effect(op, me, en), " ", gs.op_effect(op, en, me))
	quit()
