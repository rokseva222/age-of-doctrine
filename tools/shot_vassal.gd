extends SceneTree
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_build"
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(3.8).timeout
	main.menu.finish_splash()
	await create_timer(1.2).timeout
	main._start_era("ww2")
	await create_timer(1.5).timeout
	var fr := -1
	for c in main.gs.countries:
		if c.name_en == "France": fr = c.id
	main.menu.select_country(fr)
	await create_timer(1.0).timeout
	main._on_start_requested(fr)
	await create_timer(2.0).timeout
	main.ui.hide_dialog()
	await create_timer(0.5).timeout
	var gs = main.gs
	var alg := -1
	for c in gs.countries:
		if c.name_en == "Algeria": alg = c.id
	var pid: int = gs.countries[alg].capital
	gs.vassals[alg].since = -100
	main._select(pid)
	main.map.focus_province(pid, 3.0)
	await create_timer(1.0).timeout
	await _shot(out + "/vasal.png")
	quit()
func _shot(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
