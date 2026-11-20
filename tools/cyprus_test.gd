extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(21)
	var me: int = gs.macro_idx.get("Turkey", 0)
	gs.start_game(me)
	var fam := 2748
	var ow: int = gs.provinces[fam].owner
	print("owner ", gs.countries[ow].name, " coastal ", gs.provinces[fam].coastal, " links ", gs.provinces[fam].sea_links.size())
	print("savaş: ", gs.player_declare_war(ow))
	gs.countries[me].gold = 1.0e6
	for a in gs.armies.values():
		if a.owner == me and gs.provinces[a.prov].coastal and a.size > 5000:
			print("ordu ", gs.provinces[a.prov].name, " ", a.size, " -> [", gs.player_order_move(a, fam), "] path ", a.path)
			break
	quit()
