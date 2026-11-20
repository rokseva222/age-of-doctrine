extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Pol = preload("res://scripts/politics.gd")
const Faith = preload("res://scripts/faith.gd")
func _init() -> void:
	var bad := 0
	for era in ["", "ww1", "ww2", "cw62", "tim1380", "ott1520"]:
		var gs = GS.new()
		if era != "":
			Eras.prepare(era)
		gs.new_world(7)
		if era != "":
			Eras.restructure(gs, era)
		var out := {}
		for c in gs.countries:
			if c.is_rebel or not c.alive: continue
			var r: String = Pol.regime(gs, c.id)
			if not Pol.NAME_TR.has(r): bad += 1
			out[r] = out.get(r, 0) + 1
		print("ERA '", era, "': ", out)
		var me: int = gs.macro_idx.get("Germany" if era != "tim1380" else "Turkey", 0)
		gs.start_game(me)
		if era != "": Eras.start(gs, era)
		var acts: Array = Pol.actions(gs)
		print("  eylemler(", Pol.regime(gs, me), "): ", acts.map(func(a): return a.id))
		for a in acts:
			if a.id == "martial": continue
			var g2 = gs
			var res: String = Pol.do_action(g2, a.id)
			if res == "": bad += 1
			print("    ", a.id, " -> ", Pol.regime(gs, me), " | ", res, " | ikon ", Pol.icon(Pol.regime(gs, me)))
			gs.pol.reform[str(me)] = 0
		for i in 60: gs.end_turn()
	print("== regime: ", bad, " bad")
	quit()
