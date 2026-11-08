extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const SC = preload("res://scripts/scenarios.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(21)
	var me: int = gs.macro_idx.get("Turkey", 0)
	gs.start_game(me)
	SC.apply(gs, "ukr")
	var ukr = gs.countries[gs.macro_idx.get("Ukraine", 0)]
	var rus = gs.countries[gs.macro_idx.get("Russia", 0)]
	print("başlangıç: UKR asker=%d base=%d eyalet=%d | RUS asker=%d base=%d eyalet=%d" % [ukr.troops, ukr.base_troops, ukr.prov_owned, rus.troops, rus.base_troops, rus.prov_owned])
	var sizes: Array = []
	for a in gs.armies.values():
		if a.owner == ukr.id: sizes.append(a.size)
	sizes.sort(); sizes.reverse()
	print("UKR ordu sayısı=%d en büyük 6: %s" % [sizes.size(), str(sizes.slice(0, 6))])
	sizes = []
	for a in gs.armies.values():
		if a.owner == rus.id: sizes.append(a.size)
	sizes.sort(); sizes.reverse()
	print("RUS ordu sayısı=%d en büyük 6: %s" % [sizes.size(), str(sizes.slice(0, 6))])
	var big: Array = []
	for c in gs.countries:
		if c.alive: big.append(c)
	big.sort_custom(func(a, b): return a.troops > b.troops)
	var s := ""
	for i in 14: s += "%s=%dk " % [big[i].name, big[i].troops / 1000]
	print("en büyük orduler: ", s)
	var uid: int = ukr.id
	gs.news_posted.connect(func(tx, pv, k):
		if k.begins_with("capture") and pv >= 0 and (tx.find("Ukrayna") >= 0 or gs.provinces[pv].controller == uid):
			print("   T%d %s | need=%d def=%d owner=%s" % [gs.turn, tx, gs.provinces[pv].siege_needed(), gs.provinces[pv].defense, gs.countries[gs.provinces[pv].owner].name]))
	for t in 14:
		var before: int = ukr.prov_owned
		var bh: int = ukr.prov_held
		gs.end_turn()
		print("tur %d: UKR held=%d (owned %d) RUS held=%d | UKR asker=%d RUS asker=%d" % [gs.turn, ukr.prov_held, ukr.prov_owned, rus.prov_held, ukr.troops, rus.troops])
	for n in gs.news_log.slice(maxi(0, gs.news_log.size() - 14)):
		print("  [%s] %s" % [n.kind, n.text])
	quit()
