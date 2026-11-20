extends SceneTree
## Eski sürümde alınmış kaydı yükle, N tur oynat, tutarlılık kontrol et. -- <kayit> <tur> <era_id|->
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
func _init():
	var a := OS.get_cmdline_user_args()
	var gs = GS.new()
	if a.size() > 2 and a[2] != "-":
		Eras.prepare(a[2])
	gs.new_world(1)
	var ok: bool = gs.load_from(a[0])
	var bad := 0
	if not ok: print("YÜKLENEMEDİ"); quit(); return
	var t0: int = gs.turn
	for t in int(a[1]):
		gs.end_turn()
	var alive := 0; var neg := 0
	for c in gs.countries:
		if c.alive and not c.is_rebel:
			alive += 1
			if c.troops < 0 or c.gold < -1e9 or is_nan(c.gdp): neg += 1
	var pl = gs.countries[gs.player]
	print("OK yüklendi tur ", t0, " -> ", gs.turn, " canlı=", alive, " negatif=", neg, " oyuncu=", pl.name, " il=", pl.prov_owned)
	quit()
