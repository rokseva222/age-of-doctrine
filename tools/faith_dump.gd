extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Faith = preload("res://scripts/faith.gd")
func summary(gs, tag: String) -> void:
	var cnt := {}
	for p in gs.provinces:
		var f: String = Faith.of(gs, p.id)
		cnt[f] = cnt.get(f, 0) + 1
	print(tag, " ", cnt)
	var bad := 0
	for p in gs.provinces:
		if not Faith.FAITHS.has(Faith.of(gs, p.id)): bad += 1
	print("  geçersiz kod: ", bad)
	for n in ["Germany", "Iraq", "India", "Nigeria", "Turkey", "Iran", "Russia", "Japan", "Brazil", "Lebanon", "United States of America"]:
		var c = gs.countries[gs.macro_idx.get(n, 0)]
		var d := {}
		for pid in c.owned_ids:
			var f2: String = Faith.of(gs, pid)
			d[f2] = d.get(f2, 0) + 1
		print("  ", n, " devlet=", Faith.state_faith(gs, c.id), " ", d, " gelir x", snapped(Faith.income_mult(gs, c), 0.001))
func _init() -> void:
	var gs = GS.new()
	gs.new_world(21)
	summary(gs, "MODERN")
	for era in ["ww2", "tim1380", "ott1520"]:
		Eras.prepare(era)
		var g2 = GS.new()
		g2.new_world(21)
		Eras.restructure(g2, era)
		summary(g2, era)
	quit()
