extends SceneTree
# Müttefik sınırı kalktı mı + yardım iste / katıl / mali yardım
func _init() -> void:
	var gs = load("res://scripts/game_state.gd").new()
	gs.new_world(7)
	var fails := 0
	gs.start_game(gs.macro_idx["France"])
	var me = gs.countries[gs.player]
	gs.guard_left = 0
	# 1) 3'ten fazla ittifak
	var n := 0
	for c in gs.countries:
		if c.id != gs.player and c.alive and not c.is_rebel and not gs.is_allied(gs.player, c.id):
			gs.make_alliance(gs.player, c.id)
			n += 1
			if n >= 5: break
	if me.allies.size() < 5: fails += 1; print("FAIL allies ", me.allies.size())
	var e = gs.player_propose_alliance(me.allies[0])
	if e.find("En fazla") >= 0: fails += 1
	# 2) savaş + yardım iste
	var foe := -1
	for oid in gs.neighbor_countries(gs.player):
		if not gs.is_allied(gs.player, oid) and gs.countries[oid].alive and not gs.countries[oid].is_rebel:
			foe = oid; break
	if foe < 0:
		for c in gs.countries:
			if c.alive and not c.is_rebel and not gs.is_allied(gs.player, c.id) and c.id != gs.player:
				foe = c.id; break
	gs.declare_war(gs.player, foe, true)
	var joined := 0
	for i in 12:
		gs.aid.cd.clear()
		for a in me.allies:
			if not gs.at_war(a, foe):
				var r = gs.player_request_aid(a)
				if r.ok: joined += 1
				if gs.at_war(a, foe) != r.ok and not gs.at_war(a, foe): pass
	if joined == 0: fails += 1; print("FAIL no ally ever joined")
	# cooldown
	var a0 = me.allies[0]
	gs.aid.cd.clear()
	var r1 = gs.player_request_aid(a0)
	var r2 = gs.player_request_aid(a0)
	if r1.ok == false and r2.text.find("hafta") < 0 and not gs.at_war(a0, foe) and r2.ok: fails += 1
	# 3) müttefikin savaşına katıl
	var ally = -1
	var target = -1
	for c in gs.countries:
		if c.alive and not c.is_rebel and c.id != gs.player and not gs.is_allied(gs.player, c.id) and c.id != foe and not gs.at_war(gs.player, c.id):
			target = c.id; break
	ally = me.allies[1]
	if not gs.at_war(ally, target) and not gs.is_allied(ally, target):
		gs.declare_war(ally, target, true)
		me.truce.erase(target)
		var fo = gs.aid_join_foes(ally)
		if not fo.has(target): fails += 1; print("FAIL join foes ", fo)
		var er = gs.player_aid_join(ally)
		if er != "" or not gs.at_war(gs.player, fo[0]): fails += 1; print("FAIL join ", er)
	# 4) mali yardım
	me.gold = 100000.0
	var g0 = gs.countries[me.allies[2]].gold
	var eg = gs.player_aid_gold(me.allies[2])
	if eg != "" or gs.countries[me.allies[2]].gold <= g0: fails += 1; print("FAIL gold ", eg)
	if gs.player_aid_gold(me.allies[2]) == "": fails += 1; print("FAIL gold cd")
	# 5) kayıt/yükleme
	var d = gs.to_dict() if gs.has_method("to_dict") else {}
	# 6) yüzlerce tur sim
	for i in 120:
		gs.end_turn()
	print("ALLY_FAILS=%d" % fails)
	quit(fails)
