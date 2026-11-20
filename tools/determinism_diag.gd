extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var snaps: Array = []
	for k in 3:
		var g = GS.new()
		g.new_world(999)
		g.start_game(int(g.macro_idx.get("Poland", 0)))
		var per: Array = []
		for i in 30:
			g.end_turn()
			var d := {}
			for c in g.countries: d[c.id] = [c.gold, c.owned_ids.size()]
			per.append(d)
		snaps.append(per)
	var bad := 0
	for k in [1, 2]:
		for i in 30:
			for id in snaps[0][i]:
				if snaps[0][i][id] != snaps[k][i][id]:
					bad += 1
					if bad < 4: print("run", k, " t=", i + 1, " ", id, " ", snaps[0][i][id], " vs ", snaps[k][i][id])
	print("fark=", bad)
	quit()
