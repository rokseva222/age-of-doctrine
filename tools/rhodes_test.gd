extends SceneTree
## Türkiye -> Yunanistan savaşı: Rodos/adalara kara/deniz yolu var mı? godot --headless --path . -s tools/rhodes_test.gd
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(7)
	var tr := -1
	var gr := -1
	for c in gs.countries:
		if c.name_en == "Turkey": tr = c.id
		if c.name_en == "Greece": gr = c.id
	gs.start_game(tr)
	print("Yunan eyaletleri: ", gs.countries[gr].owned_ids.size())
	for pid in gs.countries[gr].owned_ids:
		var p = gs.provinces[pid]
		print("  ", pid, " ", p.name, " nb=", p.neighbors.size(), " sea=", p.sea_links.size(), " coast=", p.get("coastal"))
	gs.declare_war(tr, gr)
	var tarmy := []
	for a in gs.armies.values():
		if a.owner == tr: tarmy.append(a)
	print("Türk ordu sayısı: ", tarmy.size())
	for pid in gs.countries[gr].owned_ids:
		var p = gs.provinces[pid]
		var reach := 0
		var seaok := 0
		for a in tarmy:
			if not gs.path_to(tr, a.prov, pid).is_empty(): reach += 1
			elif p.sea_links.has(a.prov): seaok += 1
		print("  hedef ", p.name, ": kara yolu olan ordu=", reach, " deniz(çıkarma)=", seaok)
	var ids := []
	for a in tarmy: ids.append(a.id)
	for tgt in [2419, 1311, 2416]:
		var r = gs.player_launch_assault(tgt, ids, "assault", 1.0)
		print("assault ", gs.provinces[tgt].name, " -> ", r)
		var near = gs.armies_near(tgt, 6)
		print("  armies_near=", near.size())
	# ordu seçip dokunma yolu (Rodos = Notio Aigaio)
	for tgt in [2419, 1311]:
		var done := 0
		for a in tarmy:
			var e: String = gs.player_order_move(a, tgt, 0)
			if e == "":
				done += 1
				print("  move ok ", a.prov, "->", gs.provinces[tgt].name, " op=", a.op, " path=", a.path)
				break
			else:
				if done == 0 and a == tarmy[tarmy.size() - 1]: print("  move HATA: ", e)
	print("deniz gücü ", gs.countries[tr].naval_pow, " landing_cap ", gs.landing_cap(tr), " gold ", gs.countries[tr].gold)
	quit()
