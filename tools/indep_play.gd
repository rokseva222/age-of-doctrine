extends SceneTree
## Bağımsızlık Yolu: ülke × yöntem toplu oyun. kullanım: -- <host_en> <yöntem> <tur>
const GS = preload("res://scripts/game_state.gd")
const I = preload("res://scripts/independence.gd")
const PlayerBot = preload("res://tools/player_bot.gd")
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
		if p.is_empty(): return
		var bi := 0
		var bs := -1.0e9
		var chs: Array = p.get("choices", [])
		for i in chs.size():
			var fx: Dictionary = chs[i].get("fx", {})
			var sc := -3.0 * float(fx.get("dep", 0)) + 0.4 * float(fx.get("legit", 0)) + 0.3 * float(fx.get("stab", 0)) + 0.15 * float(fx.get("gold_w", 0)) + 0.3 * float(fx.get("support", 0)) + 0.0002 * float(fx.get("troops", 0))
			if fx.has("_cut"): sc += 1.0
			if sc > bs:
				bs = sc
				bi = i
		I.choose(gs, bi))
	gs.countries[gs.player].auto_cmd = true
	var Macro = preload("res://scripts/macro.gd")
	var bot = PlayerBot.new(gs, 77, false)
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
		bot.act()
		gs.end_turn()
		if OS.get_cmdline_user_args().size() > 3 and t % 5 == 0:
			var hc = gs.countries[int(gs.indep.host)]
			var en := ""
			for e in pc.enemies: en += gs.countries[e].name_en + "(" + str(gs.countries[e].troops / 1000) + "k) "
			print("  düşmanlar: ", en, " ist=", int(pc.stability))
			print("  savaşta_merkez=", gs.at_war(gs.player, int(gs.indep.host)), " faz=", gs.indep.phase, " med_cd=", gs.indep.get("med_cd", -1), " faz_tur=", gs.indep.phase_turn)
			print("  t=%d eyalet=%d/%d asker=%d altın=%.0f gelir=%.1f destek=%d meşru=%d | merkez asker=%d eyalet=%d" % [gs.turn, I.held(gs), pc.prov_owned, pc.troops, pc.gold, pc.income, int(gs.indep.support), int(gs.indep.legit), hc.troops, hc.prov_owned])
		if OS.get_cmdline_user_args().size() > 3 and t >= 84 and t <= 92:
			for nn in gs.news_log.slice(maxi(0, gs.news_log.size() - 6)):
				print("   haber t=", gs.turn, ": ", String(nn.text).substr(0, 120))
		var ph: int = int(gs.indep.phase)
		if not phase_turn.has(ph): phase_turn[ph] = gs.turn
		if not gs.countries[gs.player].alive:
			done = gs.turn; break
		if res.t != "": done = gs.turn; break
	var pl = gs.countries[gs.player]
	print("SONUC %-14s %-9s tur=%3d evreler=%s son=%d destek=%d meşru=%d tanıyan=%d eyalet=%d canlı=%s dep=%d iyi=%d | %s%s" % [host, method, gs.turn, str(phase_turn), int(gs.indep.phase), int(gs.indep.support), int(gs.indep.legit), (gs.indep.recog as Array).size(), pl.prov_owned, pl.alive, int(gs.indep.dep), int(gs.indep.get("good", 0)), ("ZAFER " if res.v else "YENİLGİ ") if res.t != "" else "", res.t.substr(0, 60)])
	quit()
