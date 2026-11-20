extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
func _init():
	var ids: Array = OS.get_cmdline_user_args()
	for e in ids:
		Eras.prepare(e)
		var gs = GS.new(); gs.new_world(5)
		gs.start_game(int(gs.macro_idx["Turkey"]) if gs.macro_idx.has("Turkey") else 0)
		Eras.restructure(gs, e)
		var arr := []
		for c in gs.countries:
			if c.alive and c.prov_owned > 0 and not c.is_rebel:
				arr.append([c.prov_owned, c.name, c.name_en])
		arr.sort_custom(func(a, b): return a[0] > b[0])
		var s := []
		for a in arr: s.append("%s[%s]%d" % [a[1], a[2], a[0]])
		print("== ", e, " ülke=", arr.size(), "\n", ", ".join(s))
	quit()
