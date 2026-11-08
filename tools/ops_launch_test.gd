extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(3)
	var me: int = gs.macro_idx.get("Turkey", 0)
	gs.start_game(me)
	var en: int = gs.macro_idx.get("Greece", 1)
	gs.declare_war(me, en, true)
	var tgt := -1
	for p in gs.provinces:
		if p.owner == en and p.coastal:
			tgt = p.id; break
	var ids: Array = []
	for e in gs.armies_near(tgt, 6): ids.append(e.army.id)
	for op in ["paradrop", "naval", "missile", "special"]:
		var r = gs.player_launch_assault(tgt, ids, op, 0.2)
		print(op, " -> ", r)
	for i in 30: gs.end_turn()
	print("tur ", gs.turn, " hata yok")
	quit()
