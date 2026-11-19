extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
func _init() -> void:
	Eras.prepare("ww2")
	var g = GS.new(); g.new_world(12345)
	Eras.restructure(g, "ww2")
	var idx := {}
	for c in g.countries: idx[c.name_en] = c.id
	g.start_game(int(idx["France"]))
	Eras.start(g, "ww2")
	print("vasal sayisi: ", g.vassals.size())
	var alg: int = int(idx["Algeria"])
	if g.lord_of(alg) != g.player or not g.countries[alg].alive:
		print("HATA: Cezayir vasal degil ", g.lord_of(alg), " alive=", g.countries[alg].alive); quit(1); return
	if g.neighbor_countries(g.player).size() == 0: print("uyari")
	var gold0: float = g.countries[g.player].gold
	for i in 10: g.end_turn()
	print("hazine ", gold0, " -> ", g.countries[g.player].gold, " vasal sayisi ", g.vassals_of(g.player).size())
	# ortak savaş
	var ger: int = int(idx["Germany"])
	var war_ok := true
	for v in g.vassals_of(g.player):
		if g.countries[g.player].enemies.has(ger) and not g.countries[v].enemies.has(ger):
			war_ok = false
	print("ortak savas: ", war_ok)
	if not war_ok: print("HATA ortak savas"); quit(1); return
	# ilhak
	g.vassals[alg].since = -100
	g.countries[g.player].gold = 1.0e9
	var np0: int = g.countries[g.player].prov_owned
	var e: String = g.player_annex_vassal(alg)
	g.refresh_stats()
	print("ilhak: '", e, "' eyalet ", np0, " -> ", g.countries[g.player].prov_owned)
	if e != "" or g.countries[g.player].prov_owned <= np0: print("HATA ilhak"); quit(1); return
	var d: Dictionary = g.to_dict()
	var g2 = GS.new(); g2.new_world(12345)
	Eras.restructure(g2, "ww2")
	if not g2.from_dict(d) or g2.vassals.size() != g.vassals.size():
		print("HATA kayit"); quit(1); return
	print("TAMAM"); Eras.clear(); quit()
