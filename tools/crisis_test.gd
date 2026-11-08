extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Crises = preload("res://scripts/crises.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(4)
	gs.start_game(gs.macro_idx.get("Turkey", 0))
	var p = gs.countries[gs.player]
	# 1) doğal başlama sıklığı (320 tur, 3 tohum benzeri tek koşu)
	var starts := 0
	var last := ""
	var tot_wk := 0
	for i in 400:
		gs.end_turn()
		if not gs.crisis.is_empty():
			tot_wk += 1
			if gs.crisis.kind + str(gs.crisis.start) != last:
				last = gs.crisis.kind + str(gs.crisis.start); starts += 1
				print("  kriz t", gs.turn, " ", gs.crisis.kind, " süre=", gs.crisis.end - gs.crisis.start, " sev=", gs.crisis.sev)
	print("400 turda kriz sayısı=", starts, " kriz haftası=", tot_wk, " bekleyen kart=", not gs.crisis_pending.is_empty(), " istikrar=", snapped(p.stability, 0.1))
	# 2) etki ölçümü: aynı ülkenin gelir çarpanı
	gs.crisis = {"kind": "crash", "start": gs.turn, "end": gs.turn + 12, "sev": 1.0, "mit": 1.0}
	print("çarpan bekle=", snapped(Crises.income_mult(gs, p), 0.001))
	var card: Dictionary = Crises.card_for(gs, "crash")
	var Cab = load("res://scripts/cabinet.gd")
	var g0: float = p.gold
	var out: Array = Cab.apply(gs, card.o[0].e)
	print("önlem paketi: mit=", gs.crisis.mit, " çarpan=", snapped(Crises.income_mult(gs, p), 0.001), " altın farkı=", snapped(p.gold - g0, 1.0), " ", out.size(), " etki")
	# 3) kayıt/yükleme
	gs.save_to("user://t_cr.json")
	var g2 = GS.new(); g2.new_world(4); g2.load_from("user://t_cr.json")
	print("yüklü kriz=", g2.crisis.get("kind", "-"), " mit=", g2.crisis.get("mit", "-"), " last_end=", g2.crisis_last_end)
	# 4) bitiş
	for i in 14: gs.end_turn()
	print("bitti mi: ", gs.crisis.is_empty(), " last_end=", gs.crisis_last_end)
	quit()
