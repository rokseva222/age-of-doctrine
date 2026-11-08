extends SceneTree
## Arayüz akış testi: açılış → menü → ülke seçimi → oyun → paneller; ekran görüntüleri.
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_ui"
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(1.3).timeout
	await _shot(out + "/01_splash.png")
	await create_timer(2.4).timeout
	main.menu.finish_splash()
	await create_timer(1.2).timeout
	await _shot(out + "/02_menu.png")
	main._to_select()
	await create_timer(1.0).timeout
	var tr_id := -1
	for c in main.gs.countries:
		if c.name == "Türkiye":
			tr_id = c.id
	main.menu.select_country(tr_id)
	await create_timer(1.4).timeout
	await _shot(out + "/03_select.png")
	var St = load("res://scripts/settings.gd")
	St.seen_howto = true
	main._on_start_requested(tr_id)
	await create_timer(1.6).timeout
	main._on_speed_changed(2)
	await create_timer(5.0).timeout
	main._on_speed_changed(0)
	await _shot(out + "/04_game.png")
	# yabancı eyalet seç
	var foe := -1
	for p in main.gs.countries[tr_id].owned_ids:
		for nb in main.gs.provinces[p].neighbors:
			if main.gs.provinces[nb].owner != tr_id and foe < 0:
				foe = nb
	main._select(foe)
	main.map.focus_province(foe, 3.4)
	await create_timer(1.0).timeout
	await _shot(out + "/05_foreign.png")
	main.ui.show_world_panel(0)
	await create_timer(0.6).timeout
	await _shot(out + "/06_world.png")
	main.ui.hide_dialog()
	await create_timer(0.4).timeout
	main.ui.show_world_panel(2)
	await create_timer(0.6).timeout
	await _shot(out + "/07_news.png")
	main.ui.hide_dialog()
	await create_timer(0.4).timeout
	main.ui.show_pause_menu()
	await create_timer(0.6).timeout
	await _shot(out + "/08_pause.png")
	main.ui.hide_dialog()
	await create_timer(0.4).timeout
	load("res://scripts/info_sheets.gd").open_settings(main.ui.root, func(): pass, main.sfx)
	await create_timer(0.6).timeout
	await _shot(out + "/09_settings.png")
	quit()

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)
