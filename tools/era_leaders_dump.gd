extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
func _init():
	var base := GS.new(); base.new_world(5)
	var modern := {}
	for c in base.countries: modern[c.name_en] = c.leader
	for e in OS.get_cmdline_user_args():
		Eras.prepare(e)
		var gs = GS.new(); gs.new_world(5); gs.start_game(0)
		Eras.restructure(gs, e)
		Eras.start(gs, e)
		var same := []
		for c in gs.countries:
			if c.alive and c.prov_owned > 0 and not c.is_rebel and modern.get(c.name_en, "") == c.leader:
				same.append("%s:%s" % [c.name_en, c.leader])
		print("== ", e, " modern liderle kalan: ", same.size())
		print("  ", "; ".join(same))
	quit()
