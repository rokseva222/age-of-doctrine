extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var g0 = GS.new(); g0.new_world(4)
	var who := -1
	for c in g0.countries:
		if not c.alive or c.is_rebel or g0.neighbor_countries(c.id).size() == 0: continue
		for pid in c.owned_ids:
			for q in g0.provinces[pid].sea_links:
				var o = g0.provinces[q].owner
				if o != c.id and g0.neighbor_countries(o).is_empty() and c.owned_ids.size() >= 5 and who < 0:
					who = c.id
	var gs = GS.new(); gs.new_world(4)
	gs.start_game(who)
	var me = gs.countries[gs.player]
	# hedef: denizle bağlantılı en yakın ada ülkesi eyaleti
	var tgt := -1; var from := -1
	for pid in me.owned_ids:
		for q in gs.provinces[pid].sea_links:
			var o = gs.provinces[q].owner
			if o != gs.player and gs.neighbor_countries(o).is_empty():
				tgt = q; from = pid; break
		if tgt >= 0: break
	if tgt >= 0 and not gs.armies.has(from):
		var ar = gs.armies_of(gs.player)[0]
		gs._relocate(ar, from)
	print("oyuncu=", me.name, " kıyı eyaleti=", from, " hedef=", tgt, " ", gs.provinces[tgt].name if tgt>=0 else "", " ülke=", gs.countries[gs.provinces[tgt].owner].name if tgt>=0 else "")
	if tgt < 0: quit(); return
	var vic: int = gs.provinces[tgt].owner
	print("savaş ilan: ", gs.player_declare_war(vic))
	var near: Array = gs.armies_near(tgt, 6)
	print("armies_near=", near.size())
	var ids: Array = []
	for a in gs.armies_of(gs.player):
		if a.prov == from: ids.append(a.id)
	var res: Dictionary = gs.player_launch_assault(tgt, ids, "landing", 1.0)
	print("saldırı: ", res)
	gs.auto_idle = true
	var cap0: int = gs.stats.p_captures
	for i in 60:
		gs.end_turn()
		if i % 10 == 9:
			var held := 0
			for pid in gs.countries[vic].owned_ids: pass
			var mine := 0
			for p in gs.provinces:
				if p.owner == vic and p.controller == gs.player: mine += 1
			print("t", gs.turn, " işgal edilen=", mine, " fetih=", gs.stats.p_captures - cap0, " ordu=", gs.armies_of(gs.player).size(), " savaşta=", gs.at_war(gs.player, vic))
	quit()
