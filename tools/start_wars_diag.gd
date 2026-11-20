extends SceneTree
## kullanım: -- <çağ>  ; çağ başlangıcındaki tüm savaş çiftlerini yazar
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
func _init() -> void:
	var id: String = OS.get_cmdline_user_args()[0]
	Eras.prepare(id)
	var gs = GS.new()
	gs.new_world(4243)
	Eras.restructure(gs, id)
	gs.start_game(int(gs.macro_idx.get("Turkey", 0)))
	Eras.start(gs, id)
	var out: Array = []
	for w in gs.wars:
		if gs.countries[w.a].is_rebel or gs.countries[w.b].is_rebel: continue
		out.append(gs.countries[w.a].name_en + "-" + gs.countries[w.b].name_en)
	print(id, " (", out.size(), "): ", ", ".join(out))
	quit()
