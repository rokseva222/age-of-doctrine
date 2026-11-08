extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(11)
	gs.start_game(gs.macro_idx.get("Turkey", 0))
	for i in 150: gs.end_turn()
	var n := 0; var mx := 0; var ex := ""
	for a in gs.armies.values():
		if a.cmd_lvl > 0:
			n += 1; mx = maxi(mx, a.cmd_lvl); ex = "%s (sv %d, %d zafer)" % [a.cmd_name, a.cmd_lvl, a.cmd_wins]
	print("komutanlı ordu: ", n, "/", gs.armies.size(), " en yüksek sv ", mx, " örnek: ", ex)
	gs.save_to("user://t_cmd.json")
	var g2 = GS.new(); g2.new_world(11); g2.load_from("user://t_cmd.json")
	var n2 := 0
	for a in g2.armies.values():
		if a.cmd_lvl > 0: n2 += 1
	print("yüklü komutanlı: ", n2)
	quit()
