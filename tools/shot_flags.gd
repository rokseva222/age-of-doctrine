extends SceneTree
## Dönem bayrakları ekran görüntüsü (ülke seçimi). Çıktı: /tmp/flag_shots/
const Info = preload("res://scripts/info_sheets.gd")
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.seen_update = Info.UPDATE_VER
	St.seen_promo = true
	St.tut_done = true
	St.seen_howto = true
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute("/tmp/flag_shots")
	await create_timer(2.5).timeout
	main.menu.finish_splash()
	await create_timer(1.5).timeout
	for era in ["ott1453", "ott1520"]:
		main._start_era(era)
		await create_timer(3.0).timeout
		for i in 4:
			main.ui.hide_dialog()
			await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		get_root().get_viewport().get_texture().get_image().save_png("/tmp/flag_shots/%s_secim.png" % era)
		main._back_to_menu()
		await create_timer(1.5).timeout
	quit()
