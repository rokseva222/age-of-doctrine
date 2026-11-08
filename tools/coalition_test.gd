extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(4)
	gs.start_game(gs.macro_idx.get("Turkey", 0))
	var w0: int = 0
	for w in gs.wars: if w.involves(gs.player): w0 += 1
	gs.infamy = 80.0
	for i in 17: gs.end_turn()
	var w1: int = 0
	for w in gs.wars: if w.involves(gs.player): w1 += 1
	print("oyuncu savaşı ", w0, " -> ", w1, " infamy=", snapped(gs.infamy, 0.1))
	for n in gs.news_log.slice(-6): print("  ", n.text if n is Dictionary and n.has("text") else n)
	gs.save_to("user://t_inf.json")
	var g2 = GS.new(); g2.new_world(4); g2.load_from("user://t_inf.json")
	print("yüklü infamy=", snapped(g2.infamy, 0.1))
	quit()
