extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const I = preload("res://scripts/independence.gd")
var fails := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n); if not ok: fails += 1
func run(method: String, host: String) -> void:
	print("=== ", method, " / ", host)
	var gs = GS.new()
	gs.new_world(31)
	var h: int = gs.macro_idx[host]
	gs.start_game(h)
	ck("başladı", I.begin(gs, {"host_en": host, "dir": "east", "n": 3, "name": "Test Hareketi", "leader": "Ada Kaya", "color": 1, "ideo": "federal", "method": method}))
	ck("oyuncu hareket", gs.player != h and gs.countries[gs.player].name == "Test Hareketi" and gs.countries[gs.player].is_player)
	ck("rakip gruplar", gs.indep.groups.size() == 3)
	print("  evre=", gs.indep.phase, " eyalet=", gs.countries[gs.player].prov_owned, " asker=", gs.countries[gs.player].troops, " savaşta=", gs.at_war(gs.player, h))
	gs.indep_card.connect(func():
		var p: Dictionary = gs.indep.pending
		if not p.is_empty():
			I.choose(gs, 0))
	gs.countries[gs.player].auto_cmd = true
	var seen_phases := {}
	for t in 160:
		gs.end_turn()
		seen_phases[int(gs.indep.phase)] = true
		if t == 12 and int(gs.indep.phase) == 0:
			for a in ["propaganda", "cell"]:
				print("  eylem ", a, ": ", I.do_action(gs, a))
			gs.countries[gs.player].gold += 1e6
			gs.indep.support = 70.0
			print("  eylem uprise: ", I.do_action(gs, "uprise"))
		if t == 30:
			print("  grup görüş: ", I.group_act(gs, gs.indep.groups[0].id, "talk"))
			print("  grup ittifak: ", I.group_act(gs, gs.indep.groups[0].id, "ally"))
		if int(gs.indep.phase) == 2 and not gs.indep.ref_done:
			gs.indep.support = 80.0
			gs.indep.legit = 60.0
			gs.countries[gs.player].gold += 1e6
			if gs.at_war(gs.player, h):
				var w = gs.get_war(gs.player, h)
				gs.finish_peace(w, -1, [])
			print("  referandum: ", I.do_action(gs, "referendum"))
		if int(gs.indep.phase) == 3 and gs.indep.recog.size() >= 5:
			gs.indep.legit = 60.0
			gs.countries[gs.player].gold += 1e6
			print("  BM: ", I.do_action(gs, "un_apply"))
	print("  evreler: ", seen_phases.keys(), " son evre=", gs.indep.phase, " destek=", int(gs.indep.support), " meşruiyet=", int(gs.indep.legit), " tanıyan=", gs.indep.recog.size(), " bağımlılık=", gs.indep.dep, " kart=", gs.indep.get("seen", []).size(), " yaşıyor=", gs.countries[gs.player].alive, " eyalet=", gs.countries[gs.player].prov_owned)
	var p := "user://indep.dat"
	ck("kayıt", gs.save_to(p))
	var g2 = GS.new()
	ck("yükle", g2.load_from(p) and I.active(g2) and g2.player == gs.player and g2.indep.phase == gs.indep.phase)
	for t in 10:
		g2.end_turn()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
func _init() -> void:
	run("uprising", "Spain")
	run("political", "Turkey")
	run("coup", "India")
	print("HATA SAYISI=", fails)
	quit()
