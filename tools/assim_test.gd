extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(21)
	var me: int = gs.macro_idx.get("Turkey", 0); gs.start_game(me)
	var en: int = gs.macro_idx.get("Greece", 1)
	var fails := 0
	var pid := -1
	for p in gs.provinces:
		if p.owner == en: pid = p.id; break
	var p = gs.provinces[pid]
	p.owner = me; p.controller = me; p.core = en; p.unrest = 6
	gs.countries[me].gold = 1.0e12
	var cost: float = gs.assimilate_cost(pid)
	var r: String = gs.player_assimilate(pid)
	print("asimile: '", r, "' maliyet=", cost, " core=", p.core, " unrest=", p.unrest)
	if r != "" or p.core != me or p.unrest != 0: fails += 1; print("HATA")
	if gs.player_assimilate(pid) == "": fails += 1; print("HATA: ikinci kez")
	print("HATA SAYISI=", fails)
	quit()
