extends SceneTree
## Modern dünya tanısı: isyan sayısı (kıtaya göre) ve Türkiye genişlemesi. godot --headless --path . -s tools/diag_world.gd -- <seed> <tur>
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var seed_val := int(args[0]) if args.size() > 0 else 7
	var turns := int(args[1]) if args.size() > 1 else 104
	var gs = GS.new()
	gs.new_world(seed_val)
	var pid := -1
	for c in gs.countries:
		if c.name_en == "Brazil": pid = c.id
	gs.start_game(pid)
	gs.countries[pid].auto_cmd = true
	var tid := -1
	for c in gs.countries:
		if c.name_en == "Turkey": tid = c.id
	var arr := []
	for c in gs.countries:
		if c.alive: arr.append(c)
	arr.sort_custom(func(a, b): return a.troops * 1.0 + a.gdp * 0.0 > b.troops * 1.0)
	print("-- ASKER SIRASI")
	var s := ""
	for i in 14:
		s += "%d.%s(%d) " % [i + 1, arr[i].name_en, arr[i].troops]
	print(s)
	var arr2 := arr.duplicate()
	arr2.sort_custom(func(a, b): return a.gdp > b.gdp)
	s = ""
	for i in 14:
		s += "%d.%s(%.0f) " % [i + 1, arr2[i].name_en, arr2[i].gdp]
	print("-- GSYH SIRASI ", s)
	for t in turns:
		gs.end_turn()
		if (t + 1) % 26 == 0:
			var reb := {}
			var unrest_eu := 0
			for c in gs.countries:
				if c.alive and c.is_rebel:
					reb[c.continent] = int(reb.get(c.continent, 0)) + 1
			for p in gs.provinces:
				if p.owner >= 0 and gs.countries[p.owner].continent == "Europe" and p.unrest >= 8: unrest_eu += 1
			var reb_eu := 0
			var broke_eu := 0
			for p in gs.provinces:
				if p.owner >= 0 and p.controller >= 0 and p.controller != p.owner and gs.countries[p.controller].is_rebel and gs.countries[p.owner].continent == "Europe": reb_eu += 1
			for c in gs.countries:
				if c.alive and c.continent == "Europe" and c.gold <= 0.0: broke_eu += 1
			print("   avrupa: isyancida eyalet=%d, altini bitirmis ulke=%d" % [reb_eu, broke_eu])
			var tc = gs.countries[tid]
			var af := 0
			for p in gs.provinces:
				if p.owner == tid and gs.countries[p.core].continent == "Africa": af += 1
			print("t=%d isyanci_ulke=%s avrupa_huzursuz_eyalet=%d | TR eyalet=%d (Afrika %d) asker=%d" % [gs.turn, str(reb), unrest_eu, tc.owned_ids.size(), af, tc.troops])
	quit()
