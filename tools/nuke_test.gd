extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(21)
	var me: int = gs.macro_idx.get("United States", gs.macro_idx.get("USA", 0))
	gs.start_game(me)
	var enemy: int = gs.macro_idx.get("Russia", 1)
	print("nukes? ", gs.player_has_nukes(), " (", gs.countries[me].name, ")")
	print("savaşsız: ", gs.player_nuke(0))
	gs.declare_war(me, enemy, true)
	var pid := -1
	for p in gs.provinces:
		if p.owner == enemy:
			pid = p.id; break
	var before = gs.armies.get(pid)
	var bs: int = 0 if before == null else before.size
	var r = gs.player_nuke(pid)
	print("sonuç: '", r, "' ordu ", bs, " -> ", 0 if gs.armies.get(pid) == null else gs.armies[pid].size, " cd=", gs.nuke_cd, " turn=", gs.turn)
	print("tekrar: ", gs.player_nuke(pid))
	for i in 5: gs.end_turn()
	gs.save_to("user://t_nuke.json")
	var g2 = GS.new(); g2.new_world(21); g2.load_from("user://t_nuke.json")
	print("yüklü nuke_cd=", g2.nuke_cd)
	var g3 = GS.new(); g3.new_world(21)
	g3.start_game(g3.macro_idx.get("Turkey", 0))
	print("Türkiye nukes? ", g3.player_has_nukes())
	quit()
