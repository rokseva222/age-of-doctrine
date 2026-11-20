extends SceneTree
const SD = preload("res://scripts/sword_duel.gd")
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_sw"
	DirAccess.make_dir_recursive_absolute(out)
	var St0 = load("res://scripts/settings.gd")
	St0.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	St0.seen_promo = true
	await create_timer(1.0).timeout
	St0.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._to_select()
	await create_timer(0.8).timeout
	var tr_id := -1
	for c in main.gs.countries:
		if c.name == "Türkiye":
			tr_id = c.id
	St0.seen_howto = true
	main._on_start_requested(tr_id)
	await create_timer(1.2).timeout
	await create_timer(1.0).timeout
	for ch in main.ui.root.get_children():
		if ch.get_class() != "Control" or ch.name.begins_with("@"):
			pass
	var res := {"r": ""}
	SD.open(main.ui, {"title": "Tek Dövüş", "intro": "Surların gölgesinde iki ordu seyrediyor.", "skill": 0.4, "power": 1.1}, func(r, _i): res.r = r)
	await create_timer(0.8).timeout
	await _shot(out + "/1_intro.png")
	var view = main.ui.root.get_child(main.ui.root.get_child_count() - 1)
	# rakip kılıç kaldırırken
	var n := 0
	while view.core.phase != "wind" and n < 400:
		await process_frame
		n += 1
	await create_timer(view.core.wind * 0.8).timeout
	await _shot(out + "/2_wind.png")
	view.core.press_guard(view.core.dir)
	var m := 0
	while view.core.phase != "counter" and m < 400:
		await process_frame
		m += 1
	await create_timer(0.15).timeout
	await _shot(out + "/3_counter.png")
	quit()
