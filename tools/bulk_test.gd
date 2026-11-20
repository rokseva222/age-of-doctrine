extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const F = preload("res://scripts/formables.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(21)
	var me: int = gs.macro_idx.get("Turkey", 0)
	gs.start_game(me)
	var bad := 0
	gs.countries[me].gold = 1.0e7
	var pv: Dictionary = gs.bulk_preview("build", "farm")
	print("build önizleme ", pv)
	var g0: float = gs.countries[me].gold
	var d: int = gs.player_bulk("build", "farm")
	print("yapılan ", d, " harcanan ", int(g0 - gs.countries[me].gold))
	if d != pv.n or d <= 0: bad += 1
	# asimile & din: bazı eyaletleri yabancılaştır
	var cnt := 0
	for pid in gs.countries[me].owned_ids:
		if cnt < 3:
			gs.provinces[pid].core = -1
			cnt += 1
	var pa: Dictionary = gs.bulk_preview("assimilate")
	var d2: int = gs.player_bulk("assimilate")
	print("asimile ", pa, " -> ", d2)
	if d2 != 3: bad += 1
	var f: Dictionary = F.all()[0]
	var tp: Dictionary = F.target_provinces(gs, f)
	print("form hedef eyalet: ", tp.size())
	if tp.size() < 10: bad += 1
	var pf: Dictionary = gs.bulk_preview("faith")
	print("din ", pf)
	gs.player_bulk("faith")
	print("== bulk: ", bad, " bad")
	quit()
