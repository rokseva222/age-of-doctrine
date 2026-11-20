extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init():
	var gs = GS.new(); gs.new_world(9); gs.start_game(int(gs.macro_idx.get("Turkey", 0)))
	gs.countries[gs.player].auto_cmd = true
	var m0 := OS.get_static_memory_usage()
	var t0 := Time.get_ticks_msec()
	for t in 1500:
		gs.end_turn()
		if t % 250 == 249:
			print("tur ", gs.turn, " bellek MB=", snapped(OS.get_static_memory_usage() / 1048576.0, 0.1), " haber=", gs.news.size() if "news" in gs else -1, " ms/tur=", (Time.get_ticks_msec() - t0) / (t + 1))
	print("başlangıç MB=", snapped(m0 / 1048576.0, 0.1))
	quit()
