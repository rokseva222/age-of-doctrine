extends SceneTree
## Geri bildirim özellikleri ekran görüntüsü: toplu işlem penceresi, eyalet kartı (mezhep etiketi), siyasi sistem, Ülke Formla haritası
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_fb"
	DirAccess.make_dir_recursive_absolute(out)
	var St0 = load("res://scripts/settings.gd")
	St0.seen_update = "1.2.24"
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
	var St = load("res://scripts/settings.gd")
	St.seen_howto = true
	St.seen_update = "1.2.24"
	main._on_start_requested(tr_id)
	await create_timer(1.5).timeout
	var gs = main.gs
	gs.countries[tr_id].gold = 50000.0
	main._select(gs.countries[tr_id].capital)
	await create_timer(0.8).timeout
	await _shot(out + "/1_kart.png")
	main._open_bulk_dialog()
	await create_timer(0.8).timeout
	await _shot(out + "/2_toplu.png")
	main.ui.hide_dialog()
	main.ui.show_politics()
	await create_timer(0.8).timeout
	await _shot(out + "/3_siyaset.png")
	main.ui.hide_dialog()
	for f in load("res://scripts/formables.gd").all():
		if f.id == "ottoman":
			main._on_ui_action("form_view", "ottoman") if main.has_method("_on_ui_action") else main.ui.action.emit("form_view", "ottoman")
	await create_timer(1.0).timeout
	await _shot(out + "/4_form.png")
	quit()
