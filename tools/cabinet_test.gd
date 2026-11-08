extends SceneTree
## Kabine kadrosu: aday üretimi, atama, skandal/istifa, seçim, yeni kartlar, kayıt/yükleme. 700 tur.
const GS = preload("res://scripts/game_state.gd")
const Cabinet = preload("res://scripts/cabinet.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(3)
	var me := 0
	for c in gs.countries:
		if c.name == "Türkiye":
			me = c.id
	gs.start_game(me)
	var c = gs.countries[me]
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var appointed := 0
	var why := {}
	var elections := 0
	var cards_seen := {}
	var recent: Array = []
	var last := -99
	for t in 700:
		gs.end_turn()
		if not c.alive:
			print("öldü t=", t)
			break
		if t == 30:
			print("ilk kadro: ", c.cab.keys().map(func(r): return "%s=%s(q%d)" % [r, c.cab[r].n, c.cab[r].q]))
		if Cabinet.election_due(gs):
			var card: Dictionary = Cabinet.scheduled(gs)
			var r: Dictionary = Cabinet.resolve(gs, rng, card, card.o[1])
			elections += 1
			if elections == 1:
				print("seçim: ", r.r)
		for role in Cabinet.vacancies(gs):
			why[c.cab[role].why] = why.get(c.cab[role].why, 0) + 1
			var cs: Array = Cabinet.candidates(gs, role)
			assert(cs.size() == 3 and cs[0].cost <= cs[1].cost and cs[1].cost <= cs[2].cost)
			if t == 100 or appointed == 0:
				print("adaylar ", role, ": ", cs.map(func(x): return "%s q%d %s" % [x.n, x.q, Macro_money(x.cost)]))
			Cabinet.appoint(gs, role, cs[(appointed % 3)])
			appointed += 1
		var card2: Dictionary = Cabinet.pick(gs, last, recent, rng, true)
		if not card2.is_empty():
			last = t
			recent.append(card2.id)
			if recent.size() > 10:
				recent.pop_front()
			var opt: Dictionary = card2.o[rng.randi_range(0, card2.o.size() - 1)]
			Cabinet.resolve(gs, rng, card2, opt)
			cards_seen[card2.id] = cards_seen.get(card2.id, 0) + 1
	print("atama: ", appointed, " nedenler: ", why, " seçim: ", elections)
	print("kartlar: ", cards_seen.keys().size(), " tür; yeni: ", ["t_crates", "t_arms", "t_tea", "s_cup", "s_games", "r_coup", "r_leak"].filter(func(k): return cards_seen.has(k)))
	var path := "user://cab_test.dat"
	gs.save_to(path)
	var g2 = GS.new()
	print("yükle: ", g2.load_from(path), " kabine aynı: ", g2.countries[me].cab == c.cab, " seçim=", g2.countries[me].elect_turn, "/", c.elect_turn)
	quit()

func Macro_money(x: float) -> String:
	return "%.0f" % x
