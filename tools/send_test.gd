extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(21)
	var me: int = gs.macro_idx.get("Turkey", 0)
	gs.start_game(me)
	var bg: int = gs.macro_idx.get("Bulgaria", 0)
	gs.declare_war(me, bg)
	# Türkiye'nin sınır ordusu
	var best = null
	for a in gs.armies_of(me):
		for nb in gs.provinces[a.prov].neighbors:
			if gs.provinces[nb].owner == bg and (best == null or a.size > best.size):
				best = a
	print("sınır ordusu: ", best.size if best else "yok")
	if best == null:
		quit(); return
	var tgt := -1
	for nb in gs.provinces[best.prov].neighbors:
		if gs.provinces[nb].owner == bg:
			tgt = nb
	var total_before: int = best.size
	var origin: int = best.prov
	print("hedef=", gs.provinces[tgt].name, " err=", gs.player_order_move(best, tgt, total_before / 4))
	# kayıt/yükleme
	gs.save_to("user://t_send.json")
	var gs2 = GS.new()
	gs2.new_world(21)
	gs2.load_from("user://t_send.json")
	print("yüklü sp_size=", gs2.armies[origin].sp_size, " path=", gs2.armies[origin].sp_path)
	gs.auto_idle = false
	gs.news_posted.connect(func(t, _p, k): print("   [", k, "] ", t))
	gs.end_turn()
	for a in gs.armies.values():
		if a.owner == me and a.prov != origin and (a.prov == tgt or gs.provinces[origin].neighbors.has(a.prov)): print("   TR ordu ", gs.provinces[a.prov].name, a.size)
	var a0 = gs.armies.get(origin)
	var a1 = gs.armies.get(tgt)
	print("kaynakta: ", a0.size if a0 else "yok", " | hedefte: ", (str(a1.owner) + ":" + str(a1.size)) if a1 else "yok", " (toplam önce=", total_before, ")")
	# otomatik atama
	gs.auto_idle = true
	var cnt := 0
	for t in 3:
		gs.end_turn()
		cnt += gs.last_auto
	print("otomatik atanan ordu (3 tur, emirsiz): ", cnt)
	gs.player_order_move(gs.armies.get(origin) if gs.armies.get(origin) else best, tgt)
	gs.end_turn()
	print("emir verilen turda otomatik: ", gs.last_auto)
	quit()
