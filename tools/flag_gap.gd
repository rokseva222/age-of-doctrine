extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Flags = preload("res://scripts/flags.gd")
func _init():
	for e in OS.get_cmdline_user_args():
		Eras.prepare(e)
		var gs = GS.new(); gs.new_world(5)
		gs.start_game(0)
		Eras.restructure(gs, e)
		var miss := []
		var n := 0
		for c in gs.countries:
			if c.alive and not c.is_rebel and c.prov_owned > 0:
				n += 1
				if not Flags.era_specs.has(c.name_en):
					miss.append("%s[%s]" % [c.name, c.name_en])
		print("== ", e, " canlı=", n, " bayraksız(bugünkü)=", miss.size())
		print(", ".join(miss))
	quit()
