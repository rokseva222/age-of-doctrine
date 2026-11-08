extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Goals = preload("res://scripts/goals.gd")
const Settings = preload("res://scripts/settings.gd")
func _init() -> void:
	Settings.ach = {}
	var gs = GS.new(); gs.new_world(5)
	gs.start_game(gs.macro_idx.get("Turkey", 0))
	print("ilk: ", Goals.next_tutorial().get("id"))
	for i in 3: gs.end_turn()
	print("1:", Goals.check(gs).map(func(d): return d.id))
	gs.stats.orders = 2; gs.stats.p_wars = 1
	print("2:", Goals.check(gs).map(func(d): return d.id), " sıradaki: ", Goals.next_tutorial().get("id"))
	gs.save_to("user://t_g.json")
	var g2 = GS.new(); g2.new_world(5); g2.load_from("user://t_g.json")
	print("yüklü orders=", g2.stats.orders, " nukes=", g2.stats.nukes)
	quit()
