extends SceneTree
## Hikâye Modu: gerçek oyuncu gibi oynayan bot. kullanım: -- <host_en> <bg> <tur> [v]
const GS = preload("res://scripts/game_state.gd")
const Career = preload("res://scripts/career.gd")
const Macro = preload("res://scripts/macro.gd")
var gs
var rng := RandomNumberGenerator.new()
var res := {"t": "", "v": false}
var acts: Dictionary = {}
var cards := 0

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var host: String = a[0]; var bg: String = a[1]; var turns: int = int(a[2])
	var verbose: bool = a.size() > 3
	rng.seed = 5
	gs = GS.new()
	gs.new_world(31)
	gs.start_game(int(gs.macro_idx[host]))
	if not Career.begin(gs, {"host_en": host, "bg": bg, "name": "Test Bey"}):
		print("SONUC ", host, " BAŞLAMADI"); quit(); return
	gs.game_over.connect(func(v, t): res.t = t; res.v = v)
	gs.career_card.connect(_card)
	var fx_log := {}
	for t in turns:
		if not gs.countries[gs.player].alive or res.t != "": break
		_resolve_pending()
		_act()
		gs.end_turn()
		_resolve_pending()
		if verbose and t % 20 == 0:
			var c: Dictionary = gs.career
			var pl = gs.countries[gs.player]
			print("  t=%d durum=%s rütbe=%d itibar=%d göz=%d sadakat=%d eyalet=%d asker=%d altın=%.0f" % [gs.turn, c.state, int(c.rank), int(c.renown), int(c.favor), int(c.loyalty), pl.prov_owned, pl.troops, pl.gold])
	var c2: Dictionary = gs.career
	var pl2 = gs.countries[gs.player]
	print("SONUC %-12s %-9s tur=%3d durum=%s rütbe=%d itibar=%d eyalet=%d canlı=%s kart=%d eylem=%s | %s%s" % [host, bg, gs.turn, c2.state, int(c2.rank), int(c2.renown), pl2.prov_owned, pl2.alive, cards, JSON.stringify(acts), ("ZAFER " if res.v else "YENİLGİ ") if res.t != "" else "", res.t.substr(0, 70)])
	quit()

func n(k: String) -> void:
	acts[k] = int(acts.get(k, 0)) + 1

func _card() -> void:
	pass

func _resolve_pending() -> void:
	var pend: Dictionary = gs.career.get("pending", {})
	if pend.is_empty():
		return
	cards += 1
	var pl = gs.countries[gs.player]
	match String(pend.get("kind", "")):
		"call_to_arms":
			Career.answer_call(gs, pl.troops >= 3000)
		"summons":
			Career.answer_summons(gs, 1 if pl.gold >= pl.income * 4.0 else 0)
		"arrest":
			Career.answer_arrest(gs, pl.troops >= 5000)
		"rebel_peace":
			gs.career.state = "rebel"
			Career.do_action(gs, "declare")
			gs.career["pending"] = {}
		"card":
			var c: Dictionary = pend.card
			var best := 0
			var bs := -1.0e9
			for i in c.c.size():
				var fx: Dictionary = c.c[i][1] if c.c[i].size() > 1 and c.c[i][1] is Dictionary else {}
				var sc: float = float(fx.get("renown", 0)) * 0.6 + float(fx.get("favor", 0)) * 0.5 + float(fx.get("loyalty", 0)) * 0.3 + float(fx.get("gold_w", 0)) * 0.4 + float(fx.get("troops", 0)) * 0.001
				if sc > bs:
					bs = sc
					best = i
			if c.c[best].size() > 2:
				Career.choose_game(gs, best, "win" if rng.randf() < 0.55 else "lose")
			else:
				Career.choose(gs, best)
		_:
			gs.career["pending"] = {}

func _try(id: String) -> void:
	for ac in Career.actions(gs):
		if ac.id == id and ac.ok and int(ac.cd) <= 0:
			var r: String = Career.do_action(gs, id)
			n(id)
			return

func _act() -> void:
	var pl = gs.countries[gs.player]
	var c: Dictionary = gs.career
	var st: String = String(c.state)
	pl.auto_cmd = true
	pl.auto_buy = true
	var at_war: bool = not pl.enemies.is_empty()
	pl.budget = Macro.PRESETS["war" if at_war else "peace"].duplicate()
	if st == "vassal":
		for r in ["komutan", "katip", "casus", "hekim"]:
			_try("hire_" + r)
		if gs.turn % 4 == 0: _try("ask_fief")
		if gs.turn % 6 == 0: _try("feast")
		if gs.turn % 5 == 0: _try("gift")
		if float(c.favor) < 30.0: _try("gift")
		if float(c.renown) >= 70.0 and float(c.favor) >= 60.0: _try("ask_indep")
	elif st == "rebel":
		if gs.turn % 8 == 0: _try("oath")
		_try("declare")
		_try("throne")
	elif st == "independent":
		pass
