extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(3)
	var me: int = gs.macro_idx.get("Turkey", 0)
	gs.start_game(me)
	var en: int = gs.macro_idx.get("Greece", 1)
	var pv
	for p in gs.provinces:
		if p.owner == en and p.coastal: pv = p; break
	var arm: Array = []
	for a in gs.armies.values():
		if a.owner == me: arm.append(a); break
	for op in gs.OP_ORDER:
		var ef: Dictionary = gs.op_effect(op, me, en)
		print(op, " uygun=", gs.op_available(op, pv, arm, 1.0), " att=", snapped(ef.att, 0.01), " dp=", snapped(ef.dp, 0.01), " tahmin=", snapped(gs.assault_estimate(pv.id, arm, op, 1.0).ratio, 0.01))
	print("özel (büyük ordu): ", gs.op_available("special", pv, arm, 1.0), " küçük: ", gs.op_available("special", pv, arm, 0.1))
	quit()
