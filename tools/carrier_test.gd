extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Carriers = preload("res://scripts/carriers.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(4)
	gs.start_game(gs.macro_idx.get("China", 0))
	var c = gs.countries[gs.player]
	for i in 3: gs.end_turn()
	print("Çin gemi=", c.carriers, " naval_pow=", snapped(c.naval_pow, 0.1), " landing_cap=", gs.landing_cap(gs.player), " maliyet=", snapped(Carriers.cost(c), 1.0))
	var tw := -1
	for x in gs.countries:
		if x.name_en == "Taiwan": tw = x.id
	print("savaş: ", gs.player_declare_war(tw))
	var tp := -1
	for pid in gs.countries[tw].owned_ids:
		if gs.provinces[pid].coastal and gs.armies.has(pid): tp = pid; break
	print("hedef=", tp, " ordu=", gs.armies[tp].size if tp >= 0 else 0)
	var r: Dictionary = Carriers.strike(gs, tp)
	print("saldırı: ", r, " kalan=", gs.armies[tp].size, " cd=", c.carrier_cd - gs.turn)
	print("tekrar: ", Carriers.strike(gs, tp).err)
	var g0: float = c.gold
	c.tech = 0.6; c.gold = 1.0e6
	print("satın al: [", Carriers.buy(gs), "] gemi=", c.carriers, " ekstra=", c.carrier_extra, " upkeep=", snapped(Carriers.upkeep(c), 0.1))
	var mx := 0
	for i in 12: if Carriers.buy(gs) == "": mx += 1
	print("en fazla alım sonrası gemi=", c.carriers, " (MAX=", Carriers.MAX_OWNED, ")")
	gs.save_to("user://t_car.json")
	var g2 = GS.new(); g2.new_world(4); g2.load_from("user://t_car.json")
	var c2 = g2.countries[g2.player]
	print("yüklü gemi=", c2.carriers, " ekstra=", c2.carrier_extra, " cd=", c2.carrier_cd)
	for i in 30: gs.end_turn()
	print("30 tur sonra kasa >=0: ", c.gold >= 0.0)
	quit()
