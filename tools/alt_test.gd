extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Names = preload("res://scripts/names.gd")
const EraEvents = preload("res://scripts/era_events.gd")

func _war(g, a: String, b: String) -> bool:
	var ia: int = int(g.macro_idx.get(a, -1))
	var ib: int = int(g.macro_idx.get(b, -1))
	return ia >= 0 and ib >= 0 and g.at_war(ia, ib)

func _init() -> void:
	var errs := 0
	var checks := {
		"alt_ott_neutral": [["Turkey", "Russia", false], ["Germany", "Russia", true]],
		"alt_britain_out": [["United Kingdom", "Germany", false], ["Germany", "France", true]],
		"alt_italy_central": [["Italy", "France", true]],
		"alt_cuba_hot": [["United States of America", "Cuba", true], ["Russia", "Turkey", true]],
		"alt_japan_north": [["Japan", "Russia", true]],
		"alt_no_sarajevo": [["Germany", "France", false]],
		"alt_spain_axis": [["Spain", "United Kingdom", true]],
	}
	for id in checks:
		var g = GS.new()
		g.new_world(777)
		Eras.restructure(g, id)
		g.start_game(int(g.macro_idx.get(Eras.get_era(id).suggest[0], 0)))
		Eras.start(g, id)
		for c in checks[id]:
			var ok: bool = _war(g, c[0], c[1]) == bool(c[2])
			print(("OK   " if ok else "HATA ") + id + ": " + c[0] + " - " + c[1] + " savaş=" + str(c[2]))
			if not ok: errs += 1
	# olay mirası: ott_neutral Osmanlı girişi olayı yok, Italy 1915 olayı yok; britain_out 1914-09 öncesi olaylar
	var pool: Array = EraEvents._inherited("alt_ott_neutral")
	var has_ott := false
	for e in pool:
		if String(e.t).contains("Osmanlı Devleti Karadeniz"):
			has_ott = true
	print(("OK   " if not has_ott else "HATA ") + "alt_ott_neutral miras olaylar=" + str(pool.size()) + " Osmanlı girişi yok")
	if has_ott: errs += 1
	print("miras: italy=", EraEvents._inherited("alt_italy_central").size(), " maginot=", EraEvents._inherited("alt_maginot").size(), " cw alt=", EraEvents._inherited("alt_cuba_hot").size())
	print("HATA SAYISI=", errs)
	quit()
