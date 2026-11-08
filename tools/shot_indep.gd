extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute("/tmp/shots_in")
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main.menu.show_main()
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_in/01_menu.png")
	var IU = load("res://scripts/independence_ui.gd")
	IU.open_setup(main.menu.root, func(p): main._start_indep(p))
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_in/02_setup.png")
	main.menu.root.get_children().back().queue_free()
	await create_timer(0.3).timeout
	main._start_indep({"host_en": "Spain", "dir": "east", "n": 3, "name": "Ufuk Cephe", "leader": "Ada Kaya", "color": 1, "ideo": "federal", "method": "political"})
	await create_timer(1.2).timeout
	await _shot("/tmp/shots_in/03_panel.png")
	main.ui._modal.queue_free()
	await create_timer(0.3).timeout
	for i in 12:
		main.gs.end_turn()
	await create_timer(0.6).timeout
	await _shot("/tmp/shots_in/04_after.png")
	quit()
