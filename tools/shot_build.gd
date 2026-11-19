extends SceneTree
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_build"
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(3.8).timeout
	main.menu.finish_splash()
	await create_timer(1.2).timeout
	main._to_select()
	await create_timer(1.0).timeout
	var tr_id := -1
	for c in main.gs.countries:
		if c.name == "Türkiye":
			tr_id = c.id
	load("res://scripts/settings.gd").seen_howto = true
	main.menu.select_country(tr_id)
	await create_timer(1.0).timeout
	main._on_start_requested(tr_id)
	await create_timer(1.8).timeout
	main.ui.hide_dialog()
	await create_timer(0.5).timeout
	main.gs.countries[tr_id].gold = 100000.0
	var pid := -1
	for q in main.gs.countries[tr_id].owned_ids:
		if not main.gs.provinces[q].is_capital:
			pid = q; break
	main._select(pid)
	main.map.focus_province(pid, 3.4)
	await create_timer(1.0).timeout
	await _shot(out + "/1_kart.png")
	main._on_ui_action("build", pid)
	await create_timer(0.8).timeout
	await _shot(out + "/2_dialog.png")
	main.gs.player_build(pid, "mine")
	main.ui.hide_dialog()
	main._select(pid)
	await create_timer(0.8).timeout
	await _shot(out + "/3_insa.png")
	quit()
func _shot(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
