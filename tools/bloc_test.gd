extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(5)
	var me: int = gs.macro_idx["Turkey"]
	gs.start_game(me)
	print("kur: ", gs.player_found_bloc("Boğaz Paktı", {"shape": 1, "inner": 1, "symbol": "star", "c1": "2f4f9a", "c2": "ece6d6", "c3": "2f4f9a"}))
	var n := 0
	for oid in gs.neighbor_countries(me):
		var r: String = gs.player_invite(oid)
		print("davet ", gs.countries[oid].name, ": ", "KABUL" if r == "" else r)
		n += 1
		if n >= 8: break
	var b = gs.bloc_get(gs.countries[me].alliance)
	print("üyeler: ", b.members.size(), " | ", b.name)
	for t in 200:
		gs.end_turn()
	print("blok sayısı: ", gs.blocs.size())
	for bb in gs.blocs:
		print("  ", bb.name, " üye=", bb.members.size())
	var path := "user://b.dat"
	gs.save_to(path)
	var g2 = GS.new()
	print("yükle: ", g2.load_from(path), " blok=", g2.blocs.size())
	quit()
