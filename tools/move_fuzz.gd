extends SceneTree
## Ordu emirleri rastgele deney: ülke × dönem × durum (barış/savaş/ateşkes/ittifak/geçiş izni/dünya savaşı) × rastgele hedef
## godot --headless --path . -s tools/move_fuzz.gd -- <dönem|-> <tohum> <emir_sayısı> <tur> <mod_listesi 0,1,2,3,4,5>
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")

func _bfs_free(gs, from: int, to: int) -> bool:
	# sahiplik kısıtı olmadan: kara komşuluğu + deniz bağlantısı ile ulaşılabilir mi (coğrafi)
	var seen := {from: true}
	var q: Array = [from]
	var i := 0
	while i < q.size():
		var c: int = q[i]; i += 1
		if c == to: return true
		for nb in gs.provinces[c].neighbors:
			if not seen.has(nb): seen[nb] = true; q.append(nb)
		for nb2 in gs.provinces[c].sea_links:
			if not seen.has(nb2): seen[nb2] = true; q.append(nb2)
	return false

func _find(gs, id: int):
	for a in gs.armies.values():
		if a.id == id: return a
	return null

func _run(era: String, seed_val: int, norders: int, turns: int, mode: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 31 + mode * 7 + era.length()
	if era != "-": Eras.prepare(era)
	else: Eras.clear()
	var gs = GS.new()
	gs.new_world(seed_val)
	if era != "-": Eras.restructure(gs, era)
	# oyuncu: ordusu olan, rastgele bir ülke (küçük/büyük/ada karışık)
	var cands: Array = []
	for c in gs.countries:
		if not c.alive or c.is_rebel: continue
		var has_army := false
		for a in gs.armies.values():
			if a.owner == c.id: has_army = true; break
		if has_army and c.owned_ids.size() >= 1: cands.append(c.id)
	var pid: int = cands[rng.randi() % cands.size()]
	gs.start_game(pid)
	if era != "-": Eras.start(gs, era)
	var me = gs.countries[pid]
	me.auto_cmd = rng.randf() < 0.5
	me.gold = 1.0e13
	var nbs: Array = gs.neighbor_countries(pid)
	var snb: Array = gs.sea_neighbor_countries(pid)
	var pool: Array = nbs.duplicate()
	pool.append_array(snb)
	pool = pool.filter(func(x): return gs.countries[x].alive and not gs.countries[x].is_rebel and x != pid)
	var setup := "barış"
	match mode:
		1:
			setup = "savaş"
			for k in mini(2, pool.size()):
				var t: int = pool[rng.randi() % pool.size()]
				if not gs.at_war(pid, t) and not gs.is_allied(pid, t): gs.player_declare_war(t)
		2:
			setup = "ateşkes"
			for k in mini(2, pool.size()):
				var t2: int = pool[rng.randi() % pool.size()]
				if gs.at_war(pid, t2): continue
				me.truce[t2] = gs.turn + 25
				gs.countries[t2].truce[pid] = gs.turn + 25
		3:
			setup = "ittifak"
			for k in mini(2, pool.size()):
				var t3: int = pool[rng.randi() % pool.size()]
				if not gs.at_war(pid, t3): gs.make_alliance(pid, t3)
		4:
			setup = "geçiş"
			for k in mini(3, pool.size()):
				var t4: int = pool[rng.randi() % pool.size()]
				if not gs.at_war(pid, t4): gs.countries[t4].passage[pid] = gs.turn + 26
		5:
			setup = "dünya"
			var alive_ids: Array = []
			for c2 in gs.countries:
				if c2.alive and not c2.is_rebel and c2.id != pid: alive_ids.append(c2.id)
			for k in 3:
				var t5: int = alive_ids[rng.randi() % alive_ids.size()]
				if not gs.at_war(pid, t5) and not gs.is_allied(pid, t5): gs.player_declare_war(t5)
	# emirler
	var armies_mine: Array = []
	for a in gs.armies.values():
		if a.owner == pid: armies_mine.append(a)
	var enemy_provs: Array = []
	var nb_provs: Array = []
	for p in gs.provinces:
		if p.owner >= 0 and p.owner != pid:
			if gs.at_war(pid, p.owner): enemy_provs.append(p.id)
			if pool.has(p.owner): nb_provs.append(p.id)
	var orders: Array = []
	for k in norders:
		if armies_mine.is_empty(): break
		var a = armies_mine[rng.randi() % armies_mine.size()]
		if gs.armies.get(a.prov) != a: continue
		var r := rng.randf()
		var tgt: int
		if r < 0.45 or (enemy_provs.is_empty() and nb_provs.is_empty()):
			tgt = rng.randi() % gs.provinces.size()
		elif r < 0.75 and not nb_provs.is_empty():
			tgt = nb_provs[rng.randi() % nb_provs.size()]
		elif not enemy_provs.is_empty():
			tgt = enemy_provs[rng.randi() % enemy_provs.size()]
		else:
			tgt = nb_provs[rng.randi() % nb_provs.size()]
		if tgt == a.prov: continue
		var pre_path: Array = gs.path_to(pid, a.prov, tgt)
		var cnt := 0 if rng.randf() < 0.65 else int(a.size / 2)
		var gold0: float = me.gold
		var err: String = gs.player_order_move(a, tgt, cnt)
		var tp = gs.provinces[tgt]
		var rec := {"aid": a.id, "from": a.prov, "to": tgt, "cnt": cnt, "err": err, "pre_hops": pre_path.size(),
			"geo": _bfs_free(gs, a.prov, tgt), "owner_to": tp.owner, "tgt_state": ("savaş" if (tp.owner >= 0 and gs.at_war(pid, tp.owner)) else ("kendi" if tp.owner == pid else ("müttefik" if gs.is_allied(pid, tp.owner) else ("ateşkes" if int(me.truce.get(tp.owner, -1)) > gs.turn else ("izinli" if gs.has_passage(pid, tp.owner) else "tarafsız"))))),
			"landing": a.op == "landing" or me.gold < gold0 - 1.0, "coastal": tp.coastal, "first_path": (a.path[0] if not a.path.is_empty() else -1)}
		orders.append(rec)
	# sürdür
	var progress := {}
	for o in orders: progress[o.aid] = {"moved_turn": -1, "reached": false}
	for t in turns:
		gs.end_turn()
		for o in orders:
			if o.err != "": continue
			var cur = _find(gs, o.aid)
			var pr = progress[o.aid]
			if cur != null and cur.prov != o.from and pr.moved_turn < 0: pr.moved_turn = t
			# hedefte bizim ordu var mı?
			if not pr.reached:
				var at_t = gs.armies.get(o.to)
				if at_t != null and at_t.owner == pid: pr.reached = true; pr.reached_turn = t
	var results: Array = []
	for o in orders:
		var pr2 = progress[o.aid]
		var cur2 = _find(gs, o.aid)
		o["moved_turn"] = pr2.moved_turn
		o["reached"] = pr2.reached
		o["alive"] = cur2 != null
		o["now"] = cur2.prov if cur2 != null else -1
		o["pathleft"] = cur2.path.size() if cur2 != null else -1
		o["pid"] = pid
		o["pname"] = me.name_en
		o["setup"] = setup
		o["era"] = era
		o["seed"] = seed_val
		o["turn_end"] = gs.turn
		results.append(o)
	print("RESULT\t", JSON.stringify({"era": era, "seed": seed_val, "mode": setup, "pid": pid, "pname": me.name_en, "orders": results}))
	Eras.clear()

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var era: String = args[0] if args.size() > 0 else "-"
	var seed_val := int(args[1]) if args.size() > 1 else 7
	var norders := int(args[2]) if args.size() > 2 else 14
	var turns := int(args[3]) if args.size() > 3 else 24
	var modes: PackedStringArray = (args[4] if args.size() > 4 else "0,1,2,3,4,5").split(",")
	for m in modes:
		_run(era, seed_val, norders, turns, int(m))
	quit()
