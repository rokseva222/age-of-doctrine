extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const I = preload("res://scripts/independence.gd")
func run(host: String, seed_: int, pids: Array) -> void:
	var gs = GS.new()
	gs.new_world(seed_)
	var h: int = gs.macro_idx[host]
	gs.start_game(h)
	I.begin(gs, {"host_en": host, "pids": pids, "name": "T", "method": "uprising"})
	var f = gs.countries[gs.player]
	gs.indep_card.connect(func():
		if not gs.indep.pending.is_empty(): I.choose(gs, 0))
	f.auto_cmd = true
	var died := -1
	for t in 120:
		gs.end_turn()
		if not f.alive and died < 0:
			died = t
	print(host, " troops0=", gs.indep.get("host_troops"), " ölüm haftası=", died, " eyalet=", f.prov_owned, " asker=", f.troops, " kontrol=", snapped(load("res://scripts/districts.gd").total_control(gs), 0.01))
func _init() -> void:
	run("Spain", 31, [])
	run("Turkey", 31, [423])
	run("India", 31, [])
	run("Germany", 7, [])
	quit()
