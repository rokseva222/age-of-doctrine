extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(21)
	var me: int = gs.macro_idx.get("Turkey", 0)
	gs.start_game(me)
	var bg: int = gs.macro_idx.get("Bulgaria", 0)
	var gr: int = gs.macro_idx.get("Georgia", 0)
	gs.declare_war(me, bg)
	gs.countries[me].auto_cmd = true
	# Gürcistan sınırında kendi eyaleti
	var tgt := -1
	for p in gs.provinces:
		if p.owner == me:
			for nb in p.neighbors:
				if gs.provinces[nb].owner == gr:
					tgt = p.id
	var best = null
	for a in gs.armies_of(me):
		if best == null or a.size > best.size:
			best = a
	best.size = 100000
	var origin: int = best.prov
	print("kaynak=", gs.provinces[origin].name, " hedef=", gs.provinces[tgt].name, " hata=", gs.player_order_move(best, tgt, 50000))
	for t in 12:
		gs.end_turn()
	var held = gs.armies.get(tgt)
	print("hedefte: ", held.size if held else "yok", " hold=", held.hold if held else "-")
	var src = gs.armies.get(origin)
	print("kaynakta: ", src.size if src else "yok (otomatik ilerledi)")
	var n := 0
	for a in gs.armies_of(me):
		if a.prov != tgt and a.size > 20000: n += 1; print("  başka büyük ordu: ", gs.provinces[a.prov].name, " ", a.size, " hold=", a.hold)
	gs.save_to("user://t_hold.json")
	var g2 = GS.new(); g2.new_world(21); g2.load_from("user://t_hold.json")
	print("yüklü hold=", g2.armies[tgt].hold if g2.armies.get(tgt) else "yok")
	quit()
