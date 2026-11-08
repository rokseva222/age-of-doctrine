extends SceneTree
func _init() -> void:
	var gs = load("res://scripts/game_state.gd").new()
	gs.new_world(7)
	gs.start_game(-1)
	var out := []
	for c in gs.countries:
		out.append([c.name_en, c.pop, c.gdp, c.base_troops, c.troops, c.owned_ids.size(), round(c.tech * 100) / 100.0])
	var f := FileAccess.open("/tmp/countries_dump.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	quit()
