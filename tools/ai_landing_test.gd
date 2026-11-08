extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(31)
	gs.start_game(gs.macro_idx.get("Turkey", 0))
	var cnt := 0
	var orig: Dictionary = {}
	for p in gs.provinces: orig[p.id] = p.owner
	var seen := {}
	for t in 260:
		gs.end_turn()
		for a in gs.armies.values():
			if a.op == "landing" or a.sp_op == "landing":
				seen["%d_%d" % [a.id, gs.turn]] = a.owner
	print("çıkarma emri sayısı: ", seen.size())
	# adalar: İngiltere, Japonya, Filipinler, Endonezya, İrlanda, Tayvan, Kıbrıs
	for n in ["United Kingdom", "Japan", "Philippines", "Indonesia", "Taiwan", "Cyprus", "Ireland", "Sri Lanka"]:
		var cid: int = gs.macro_idx.get(n, -1)
		if cid < 0: continue
		var lost := 0
		for p in gs.provinces:
			if orig[p.id] == cid and p.owner != cid: lost += 1
		print(n, " kaybedilen eyalet: ", lost)
	print("savaş: ", gs.wars.size())
	quit()
