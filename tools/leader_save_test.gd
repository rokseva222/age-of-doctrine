extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
func _init() -> void:
	Eras.prepare("ww2")
	var g = GS.new()
	g.new_world(5)
	Eras.restructure(g, "ww2")
	var idx: Dictionary = {}
	for c in g.countries: idx[c.name_en] = c.id
	g.start_game(idx["Japan"])
	Eras.start(g, "ww2")
	for i in 120: g.end_turn()
	var d: Dictionary = g.to_dict()
	var g2 = GS.new()
	g2.new_world(5)
	print("yükle: ", g2.from_dict(d))
	for n in ["Turkey", "United Kingdom", "France"]:
		print(n, " ", g.countries[idx[n]].leader, " | ", g2.countries[idx[n]].leader, " | at: ", Eras.leader_at("ww2", n, g.turn))
	Eras.clear()
	quit()
