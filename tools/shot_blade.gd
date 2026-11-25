extends SceneTree
const BD = preload("res://scripts/blade_duel.gd")
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_bd"
	DirAccess.make_dir_recursive_absolute(out)
	var St0 = load("res://scripts/settings.gd")
	St0.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	St0.seen_promo = true
	await create_timer(1.0).timeout
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
	await create_timer(2.0).timeout
	var res := {"r": ""}
	BD.open(main.ui, {"title": "Tek Dövüş", "intro": "Surların gölgesinde iki ordu seyrediyor.", "skill": 0.4, "power": 1.1}, func(r, _i): res.r = r)
	await create_timer(0.8).timeout
	var view = main.ui.root.get_child(main.ui.root.get_child_count() - 1)
	await _shot(out + "/1_intro.png")
	view.core.player_guard(1)
	var n := 0
	while view.core.f.state != "wind" and n < 600:
		await process_frame
		n += 1
	await create_timer(0.25).timeout
	await _shot(out + "/2_foe_wind.png")
	view.core.player_attack(2)
	await create_timer(0.3).timeout
	await _shot(out + "/3_me_wind.png")
	await create_timer(0.5).timeout
	await _shot(out + "/4_after.png")
	print("HP ", view.core.p.hp, " ", view.core.f.hp, " sonuc=", res.r)
	quit()
