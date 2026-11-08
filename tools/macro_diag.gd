extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const M = preload("res://scripts/macro.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(12345)
	gs.start_game(-1)
	var turns := int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 60
	var t0 := Time.get_ticks_usec()
	for i in 5:
		var t1 := Time.get_ticks_usec()
		M.weekly(gs)
		print("weekly ms: ", (Time.get_ticks_usec() - t1) / 1000.0)
	for t in turns:
		gs.end_turn()
	var names := ["Turkey", "United States of America", "China", "Russia", "North Korea", "Germany", "Israel", "Iran", "Ukraine", "India"]
	for n in names:
		var c = gs.countries[gs.macro_idx[n]]
		var f: Dictionary = c.fin
		print("%s | asker %s (taban %s) | gelir/hf %s | maaş %s | bakım %s | fon %s | kasa %s | net %s | eq_land %.2f air %.0f naval %.0f | sanayi %.0f stab %.0f | sipariş %d" % [c.name, M.num(c.troops), M.num(c.base_troops), M.money(f["rev"]), M.money(f["wages"]), M.money(f["upkeep"]), M.money(c.fund), M.money(c.gold), M.money(f["net"]), c.eq_land, c.air_pow, c.naval_pow, c.industry, c.stability, c.orders.size()])
	var broke := 0
	for c in gs.countries:
		if c.alive and not c.is_rebel and c.gold <= 0.5:
			broke += 1
	print("kasası bitmiş ülke: ", broke, " / ", gs.alive_count())
	quit()
