extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const WR = preload("res://scripts/war_room.gd")

func _init() -> void:
	var errs := 0
	var g = GS.new()
	g.new_world(2024)
	var pl: int = int(g.macro_idx.get("Egypt", 0))
	var foe: int = int(g.macro_idx.get("Israel", 0))
	g.start_game(pl)
	g.declare_war(pl, foe, false)
	g.deploy_front(pl)
	var cards := []
	g.news_posted.connect(func(t, p2, k): if str(t).begins_with("Savaş Odası"): print("  NEWS: ", t, " turn=", g.turn, " launched=", g.wroom.phases[0].launched if g.wroom.phases.size() > 0 else -1))
	g.wroom_card.connect(func(t, b, s): cards.append(t))
	WR.new_plan(g, foe)
	print("adaylar: ", WR.candidates(g, foe).size())
	var sug: Array = WR.suggest(g, foe)
	print("öneri aşama sayısı: ", sug.size())
	if sug.is_empty():
		print("HATA öneri yok"); errs += 1
	for s in sug:
		print("  ", g.provinces[int(s.pid)].title(), " ", s.op, " şans=", WR.odds(g, int(s.pid), String(s.op), 1.0))
		var e: String = WR.add_phase(g, int(s.pid), String(s.op), float(s.frac), int(s.delay))
		if e != "": print("HATA ", e); errs += 1
	print("start: ", WR.start(g))
	g.countries[pl].gold = 1.0e9
	for i in 80:
		g.end_turn()
		var ss: Array = []
		for ph in g.wroom.phases: ss.append(String(ph.state) + ":" + str(g.provinces[int(ph.pid)].controller == pl))
		if i < 30: print(" t", g.turn, " ", ss, " gold=", int(g.countries[pl].gold))
		if not WR.active(g) and i > 2:
			break
	var st: Array = []
	for ph in g.wroom.phases:
		st.append(String(ph.state))
	print("aşamalar: ", st, " aktif=", WR.active(g), " kartlar=", cards)
	if st.has("wait") or st.has("go"):
		if WR.active(g): print("(plan hâlâ sürüyor)")
	# kayıt/yükleme
	var d: Dictionary = g.to_dict()
	var g2 = GS.new(); g2.new_world(2024); g2.from_dict(d)
	if g2.wroom.phases.size() != g.wroom.phases.size(): print("HATA kayıt"); errs += 1
	# iptal / hata yolları
	WR.cancel(g)
	print(WR.start(g))
	print("HATA SAYISI=", errs)
	quit()
