extends SceneTree
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.tut_done = true; St.seen_howto = true; St.language = "tr"
	var keep = [St.missions.duplicate(true), St.xp, St.streak, St.streak_day]
	St.missions = {}; St.xp = 0; St.streak = 0; St.streak_day = -1
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.5).timeout
	main._to_select()
	await create_timer(0.5).timeout
	var me := -1
	for c in main.gs.countries:
		if c.name_en == "Turkey": me = c.id
	main._on_start_requested(me)
	await create_timer(1.0).timeout
	main._track_missions()
	for i in 14: main.gs.end_turn()
	main.gs.stats.orders += 4
	main.gs.stats.p_battles += 3
	var msg: String = main._track_missions()
	print("MESAJ: ", msg.replace("\n", " | "))
	for t in St.missions.daily: print("  ", t.t, " ", t.p, "/", t.n, " ", t.done)
	print("xp=", St.xp)
	St.missions = keep[0]; St.xp = keep[1]; St.streak = keep[2]; St.streak_day = keep[3]; St.save_all()
	quit()
