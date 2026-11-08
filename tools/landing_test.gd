extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(21)
	var me: int = gs.macro_idx.get("Turkey", 0)
	gs.start_game(me)
	var asym := 0
	for p in gs.provinces:
		for q in p.sea_links:
			if not gs.provinces[q].sea_links.has(p.id): asym += 1
	print("asimetrik deniz bağı: ", asym)
	var src := -1
	var dst := -1
	for pid in gs.countries[me].owned_ids:
		for q in gs.provinces[pid].sea_links:
			if gs.provinces[q].owner != me and dst < 0 and gs.armies.get(pid) != null:
				src = pid; dst = q
	print("kaynak=", gs.provinces[src].name, " hedef=", gs.provinces[dst].name, " (", gs.countries[gs.provinces[dst].owner].name, ")")
	var foe: int = gs.provinces[dst].owner
	gs.declare_war(me, foe)
	var a = gs.armies[src]
	a.size = 60000
	print("yakında: ", gs.armies_near(dst, 6).map(func(e): return [gs.provinces[e.army.prov].name, e.get("sea", false)]))
	print("kasa: ", gs.countries[me].gold, " kapasite: ", gs.landing_cap(me))
	var r = gs.player_launch_assault(dst, [a.id], "assault", 1.0)
	print("emir: ", r)
	for t in 6:
		gs.end_turn()
		var d = gs.armies.get(dst)
		print(" tur ", t + 1, " kaynakta=", (gs.armies.get(src).size if gs.armies.get(src) else 0), " hedefte=", (str(gs.armies[dst].owner) + ":" + str(gs.armies[dst].size)) if gs.armies.get(dst) else "-", " sahip=", gs.provinces[dst].controller)
	quit()
