extends SceneTree
## Mağaza/tanıtım için en iyi iki oyun içi ekran görüntüsü (Türkçe arayüz)
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)
func _init() -> void:
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_best"
	DirAccess.make_dir_recursive_absolute(out)
	var St = load("res://scripts/settings.gd")
	var Loc = load("res://scripts/loc.gd")
	St.seen_howto = true
	St.tut_done = true
	St.seen_update = "1.2.13"
	St.seen_promo = true
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(3.8).timeout
	St.language = Loc.setup("tr")
	main.reload_for_language()
	await create_timer(3.8).timeout
	main = get_root().get_children().back()
	for n in get_root().get_children():
		if n.has_method("_start_era"):
			main = n
	St.tut_done = true
	St.seen_howto = true
	St.seen_promo = true
	St.seen_update = "1.2.13"
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	# --- 1) II. Dünya Savaşı: Almanya, Polonya cephesi
	main._start_era("ww2")
	await create_timer(1.4).timeout
	var de: int = main.gs.macro_idx["Germany"]
	main._on_start_requested(de)
	await create_timer(1.5).timeout
	main.ui.hide_dialog()
	for i in 7:
		main.gs.end_turn()
	main.ui.refresh_top()
	var pl: int = main.gs.macro_idx["Poland"]
	main.map.animate_to(main.gs.provinces[main.gs.countries[pl].capital].label_pos + Vector2(-60, 0), main.map.min_zoom * 4.2, 0.1)
	await create_timer(1.4).timeout
	for k in 4:
		main.ui.hide_dialog()
		await create_timer(0.4).timeout
	main._select(main.gs.countries[pl].capital)
	await create_timer(1.2).timeout
	for k in 3:
		main.ui.hide_dialog()
		await create_timer(0.3).timeout
	await _shot(out + "/best_1_ww2.png")
	# --- 2) 2027 dünyası: Türkiye
	main._go_main_menu()
	St.seen_howto = true
	St.tut_done = true
	await create_timer(1.5).timeout
	main._to_select()
	await create_timer(1.0).timeout
	var tr_id: int = main.gs.macro_idx["Turkey"]
	main._on_start_requested(tr_id)
	await create_timer(1.5).timeout
	main.ui.hide_dialog()
	main.ui.hide_info()
	for i in 10:
		main.gs.end_turn()
	main.ui.refresh_top()
	main.map.focus_country(tr_id)
	await create_timer(1.0).timeout
	for k in 4:
		main.ui.hide_dialog()
		await create_timer(0.4).timeout
	main._select(main.gs.countries[tr_id].capital)
	await create_timer(1.2).timeout
	for k in 3:
		main.ui.hide_dialog()
		await create_timer(0.3).timeout
	await _shot(out + "/best_2_modern.png")
	quit()
