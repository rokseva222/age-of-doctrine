extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Mil = preload("res://scripts/militias.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(21)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for n in ["Russia", "Turkey", "Taiwan", "Japan", "United States of America", "Germany", "Iran", "Brazil", "Nigeria", "India", "Saudi Arabia", "Vietnam"]:
		var c = gs.countries[gs.macro_idx.get(n, 0)]
		print("%-26s isyan: %s | şirket: %s | hücre: %s" % [n, Mil.make(c, rng, "rebel"), Mil.make(c, rng, "merc"), Mil.make(c, rng, "cell")])
	var me: int = gs.macro_idx.get("Turkey", 0)
	gs.start_game(me)
	var c = gs.countries[me]
	c.gold = 1.0e6
	for t in 3:
		var o: Dictionary = gs.merc_offer(c, t)
		var r: Dictionary = gs.hire_merc(me, t)
		print("kademe ", t, " teklif n=", o.n, " bedel=", int(o.cost), " hf=", o.weeks, " -> ", r)
	gs.save_to("user://t_m.json")
	var g2 = GS.new()
	g2.new_world(21)
	g2.load_from("user://t_m.json")
	var cnt := 0
	for a in g2.armies.values():
		if a.merc != "": cnt += 1
	print("yüklenen paralı birlik: ", cnt)
	for i in 30:
		gs.end_turn()
	var left := 0
	for a in gs.armies.values():
		if a.merc != "": left += 1
	print("30 tur sonra kalan paralı: ", left, " (bitmesi gereken: çete 13 hf)")
	var terror := [0]
	gs.news_posted.connect(func(t, _p, k): if t.find("saldır") >= 0 or t.find("üstlendi") >= 0: terror[0] += 1)
	for i in 120: gs.end_turn()
	print("120 turda terör haberi: ", terror[0])
	quit()
