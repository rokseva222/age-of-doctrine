extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Career = preload("res://scripts/career.gd")
func _init() -> void:
	var fails := 0
	for era in ["ott1520", ""]:
		var g = GS.new()
		Eras.prepare(era)
		g.new_world(5)
		if era != "":
			Eras.restructure(g, era)
		g.start_game(g.macro_idx.get("Turkey", 0))
		if era != "":
			Eras.start(g, era)
		if not Career.begin(g, {"host_en": "Turkey", "bg": "cavalry", "name": "Test Bey"}):
			print("FAIL begin"); fails += 1; continue
		g.countries[g.player].gold = 1.0e12
		var accepted := 0
		var offers := 0
		var after_accept := 0
		var rejected_turn := -1
		var early := 0
		for t in 700:
			g.end_turn()
			var pend: Dictionary = g.career.get("pending", {})
			if pend.get("kind", "") == "card" and String(pend.card.get("id", "")) == "marriage":
				offers += 1
				if accepted > 0:
					after_accept += 1
				if rejected_turn >= 0 and g.turn < rejected_turn + 52:
					early += 1
				if accepted == 0 and offers % 2 == 1 and OS.get_environment("ACC") != "0":
					Career.choose(g, 0)
					accepted += 1
				else:
					Career.choose(g, 1)
					rejected_turn = g.turn
			else:
				g.career["pending"] = {}
		print(era, " teklif=", offers, " kabul=", accepted, " kabulden_sonra_teklif=", after_accept, " erken_tekrar=", early)
		if after_accept > 0 or early > 0 or accepted > 1: fails += 1
		if offers == 0: print("  (uyarı: hiç evlilik teklifi gelmedi)")
	print("HATA SAYISI=", fails)
	quit()
