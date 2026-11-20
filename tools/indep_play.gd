extends SceneTree
## Bağımsızlık Yolu: ülke × yöntem toplu oyun. kullanım: -- <host_en> <yöntem> <tur>
const GS = preload("res://scripts/game_state.gd")
const I = preload("res://scripts/independence.gd")
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var host: String = a[0]; var method: String = a[1]; var turns: int = int(a[2])
	var gs = GS.new()
	gs.new_world(77)
	var h: int = gs.macro_idx[host]
	gs.start_game(h)
	if not I.begin(gs, {"host_en": host, "dir": "east", "n": 3, "name": "Test Hareketi", "leader": "Ada Kaya", "color": 1, "ideo": "federal", "method": method}):
		print("SONUC ", host, " ", method, " BAŞLAMADI"); quit(); return
	var res := {"t": "", "v": false}
	gs.game_over.connect(func(v, t): res.t = t; res.v = v)
	gs.indep_card.connect(func():
		var p: Dictionary = gs.indep.pending
		if not p.is_empty(): I.choose(gs, 0))
	gs.countries[gs.player].auto_cmd = true
	var Macro = preload("res://scripts/macro.gd")
	var phase_turn := {}
	var errs := 0
	var done := -1
	for t in turns:
		# açgözlü oyuncu: kullanılabilir ilk eylemleri (öncelik sırasıyla) yap
		for pref in ["uprise", "referendum", "un_apply", "unilateral", "coup", "treaty", "volunteers", "propaganda", "cell", "appeal", "invest", "arms", "fund"]:
			for ac in I.actions(gs):
				if ac.id == pref and ac.why == "" and (ac.chance < 0.0 or ac.chance >= 0.45):
					var r: String = I.do_action(gs, pref)
					break
		var pc = gs.countries[gs.player]
		pc.budget = Macro.PRESETS["war" if not pc.enemies.is_empty() else "peace"].duplicate()
		gs.end_turn()
		if OS.get_cmdline_user_args().size() > 3 and t % 5 == 0:
			var hc = gs.countries[int(gs.indep.host)]
			print("  t=%d eyalet=%d/%d asker=%d altın=%.0f gelir=%.1f destek=%d meşru=%d | merkez asker=%d eyalet=%d" % [gs.turn, I.held(gs), pc.prov_owned, pc.troops, pc.gold, pc.income, int(gs.indep.support), int(gs.indep.legit), hc.troops, hc.prov_owned])
		var ph: int = int(gs.indep.phase)
		if not phase_turn.has(ph): phase_turn[ph] = gs.turn
		if not gs.countries[gs.player].alive:
			done = gs.turn; break
		if res.t != "": done = gs.turn; break
	var pl = gs.countries[gs.player]
	print("SONUC %-14s %-9s tur=%3d evreler=%s son=%d destek=%d meşru=%d tanıyan=%d eyalet=%d canlı=%s | %s%s" % [host, method, gs.turn, str(phase_turn), int(gs.indep.phase), int(gs.indep.support), int(gs.indep.legit), (gs.indep.recog as Array).size(), pl.prov_owned, pl.alive, ("ZAFER " if res.v else "YENİLGİ ") if res.t != "" else "", res.t.substr(0, 60)])
	quit()
