extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
func _init():
	var flags: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/era_flags.json"))
	var base := GS.new(); base.new_world(5)
	var modern := {}
	for c in base.countries: modern[c.name_en] = c.name
	var out := {}
	for e in OS.get_cmdline_user_args():
		Eras.prepare(e)
		var gs = GS.new(); gs.new_world(5)
		gs.start_game(0)
		Eras.restructure(gs, e)
		var fam: String = Eras.family()
		var fk: String = e if flags.has(e) else (fam if flags.has(fam) else "")
		var fl: Dictionary = flags.get(fk, {})
		var no_name := []; var no_flag := []
		for c in gs.countries:
			if not (c.alive and c.prov_owned > 0) or c.is_rebel: continue
			if modern.get(c.name_en, "") == c.name: no_name.append(c.name_en)
			if not fl.has(c.name_en): no_flag.append(c.name_en)
		print("== ", e, " (bayrak tablosu=", fk, ") ülke=", gs.countries.filter(func(c): return c.alive and c.prov_owned > 0 and not c.is_rebel).size())
		print("  modern adla kalan: ", no_name)
		print("  bayraksız: ", no_flag)
	quit()
