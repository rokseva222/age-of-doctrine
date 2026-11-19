extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(4)
	# Türkiye'yi bul
	var tr := -1
	for c in gs.countries:
		if c.name_en == "Turkey" or c.name_en == "Türkiye": tr = c.id
	gs.start_game(tr)
	var isl := -1; var main_ := -1
	for p in gs.provinces:
		if isl >= 0: break
		if p.neighbors.size() > 0 and p.neighbors.size() <= 2:
			for q in p.sea_links:
				if gs.provinces[q].landmass != p.landmass and not gs.provinces[q].neighbors.has(p.id):
					isl = p.id; main_ = q; break
	print("ada=", isl, " ", gs.provinces[isl].name if isl >= 0 else "", " anakara=", main_, " ", gs.provinces[main_].name if main_ >= 0 else "")
	if isl < 0:
		print("TEST ATLANDI"); quit(); return
	for pid in [isl, main_]:
		gs.provinces[pid].owner = gs.player; gs.provinces[pid].controller = gs.player
	var ar = gs.armies_of(gs.player)[0]
	if gs.armies.has(isl): gs.armies.erase(isl)
	gs.armies.erase(ar.prov); ar.prov = isl; gs.armies[isl] = ar
	if gs.armies.has(main_): gs.armies.erase(main_)
	var err: String = gs.player_order_move(ar, main_)
	print("emir sonucu='", err, "' yol=", ar.path)
	if err != "" or ar.path.is_empty():
		print("HATA: yol yok"); quit(1); return
	print("hold=", ar.hold, " leaving=", ar.leaving, " op=", ar.op, " armies[isl]==ar ", gs.armies.get(isl)==ar)
	gs._step_army(ar)
	print("step sonrası ", ar.prov, " path=", ar.path)
	gs.end_turn()
	print("sonra konum=", ar.prov, " beklenen=", main_)
	if ar.prov != main_:
		print("HATA: ordu taşınmadı"); quit(1); return
	print("TAMAM")
	quit()
