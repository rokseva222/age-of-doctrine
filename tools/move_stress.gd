extends SceneTree
## Oyuncu ordu emirleri gerçekten yürüyor mu? godot --headless --path . -s tools/move_stress.gd -- <seed> <ülke>
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var seed_val := int(args[0]) if args.size() > 0 else 7
	var who: String = args[1] if args.size() > 1 else "Turkey"
	var gs = GS.new()
	gs.new_world(seed_val)
	var pid := -1
	for c in gs.countries:
		if c.name_en == who: pid = c.id
	gs.start_game(pid)
	gs.countries[pid].auto_cmd = false
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var orders := []
	for a in gs.armies.values():
		if a.owner != pid or orders.size() >= 14: continue
		# 3-9 adım uzaklıkta ulaşılabilir bir hedef seç
		var cands := []
		for tp in gs.provinces:
			if tp.id == a.prov: continue
			var pth: Array = gs.path_to(pid, a.prov, tp.id)
			if pth.size() >= 2 and pth.size() <= 8: cands.append([tp.id, pth.size()])
		if cands.is_empty(): continue
		var pick = cands[rng.randi() % cands.size()]
		var cnt := 0 if rng.randf() < 0.6 else int(a.size / 2)
		var err: String = gs.player_order_move(a, pick[0], cnt)
		orders.append({"id": a.id, "from": a.prov, "to": pick[0], "hops": pick[1], "err": err, "cnt": cnt})
	var bad := 0
	for t in 14:
		gs.end_turn()
		if t < 8:
			var line := "t%d " % t
			for o in orders:
				var f := "x"
				for a3 in gs.armies.values():
					if a3.id == o.id: f = str(a3.prov) + ("*" if a3.leaving else "") + ("h" if a3.hold else "")
				line += "%d:%s " % [o.id, f]
			print(line)
	for o in orders:
		var arrived := false
		var alive := false
		var where := -1
		for a2 in gs.armies.values():
			if a2.owner == pid:
				if a2.id == o.id: alive = true; where = a2.prov
				if a2.prov == o.to: arrived = true
		var ok: bool = o.err == "" and arrived
		if not ok:
			bad += 1
			print("  SORUN: ", o, " alive=", alive, " şimdi=", where, " varış=", arrived)
	print("emir=", orders.size(), " sorunlu=", bad)
	quit()
