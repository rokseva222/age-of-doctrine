extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(7)
	gs.start_game(0)
	var sea_wars := 0
	var seen := {}
	var landings := 0
	for i in 260:
		gs.end_turn()
		for w in gs.wars:
			var k: String = "%d-%d" % [mini(w.a, w.b), maxi(w.a, w.b)]
			if seen.has(k): continue
			seen[k] = true
			if not gs.neighbor_countries(w.a).has(w.b):
				sea_wars += 1
				print("deniz savasi: ", gs.countries[w.a].name, " - ", gs.countries[w.b].name, " hafta ", gs.turn)
	print("toplam savas ", seen.size(), " deniz savasi ", sea_wars)
	print("TAMAM"); quit()
