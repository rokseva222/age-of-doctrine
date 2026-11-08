extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute("/tmp/shots_new")
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main.menu.show_main()
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_new/01_menu.png")
	var DU = load("res://scripts/daily_ui.gd")
	DU.open(main.menu.root, func(c): pass)
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_new/02_daily.png")
	main.menu.root.get_children().back().queue_free()
	await create_timer(0.3).timeout
	main._start_daily(load("res://scripts/daily.gd").cfg(20400))
	await create_timer(1.5).timeout
	await _shot("/tmp/shots_new/03_daily_game.png")
	main.ui._modal.queue_free()
	await create_timer(0.3).timeout
	main.ui.show_chokes()
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_new/04_chokes.png")
	main.ui._modal.queue_free()
	await create_timer(0.3).timeout
	main.ui.show_politics()
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_new/05_politics.png")
	main.ui._modal.queue_free()
	await create_timer(0.3).timeout
	var g = main.gs
	var pl: int = g.player
	var foe = g.neighbor_countries(pl)[0]
	g.declare_war(pl, foe, false)
	g.deploy_front(pl)
	var WR = load("res://scripts/war_room.gd")
	WR.new_plan(g, foe)
	for s in WR.suggest(g, foe):
		WR.add_phase(g, int(s.pid), String(s.op), float(s.frac), int(s.delay))
	var WU = load("res://scripts/war_room_ui.gd")
	WU.open(main.ui)
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_new/06_warroom.png")
	main.ui._modal.queue_free()
	await create_timer(0.3).timeout
	WU._picker(main.ui, {"step": 0, "pid": -1, "op": "assault", "frac": 1.0, "delay": 1})
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_new/07_picker.png")
	quit()
