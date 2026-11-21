extends SceneTree
## Katilan oyuncu: ulke sec -> geri. Onceden sunucu calismali (port 47398).
var main
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png("/tmp/rep/%s.png" % name)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	var Loc = load("res://scripts/loc.gd")
	St.load_all(); St.language = "tr"; St.ui_scale_custom = true; St.ui_scale = 1.0; St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0
	St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	St.player_name = "Katilan"
	St.save_all()
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	Loc.apply("tr")
	await create_timer(2.0).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	for i in 6:
		main.ui.hide_dialog()
		await create_timer(0.3).timeout
	if OS.get_environment("AOD_TWICE") != "":
		main.online_join("127.0.0.1", 47555)
		await create_timer(14.0).timeout
		print("ILK DENEME sonrasi lobi var mi=", main._lobby_sheet != null and is_instance_valid(main._lobby_sheet))
	main.online_join(OS.get_environment("AOD_ADDR") if OS.get_environment("AOD_ADDR") != "" else "127.0.0.1", int(OS.get_environment("AOD_PORT")) if OS.get_environment("AOD_PORT") != "" else 47398)
	await create_timer(float(OS.get_environment("AOD_WAIT")) if OS.get_environment("AOD_WAIT") != "" else 2.5).timeout
	await _shot("1_lobi")
	if OS.get_environment("AOD_NOPICK") == "":
		main.online_pick_country()
	await create_timer(2.0).timeout
	main.ui.hide_dialog()
	await _shot("2_ulke_sec")
	if OS.get_environment("AOD_NOPICK") != "":
		await create_timer(16.0).timeout
		await _shot("3_geri")
		print("SONUC lobby=", main._lobby_sheet != null and is_instance_valid(main._lobby_sheet), " mode=", main.mode)
		quit()
		return
	print("pick-world countries=", main.gs.countries.size(), " Ukraine owner prov0=", main.gs.provinces[0].owner)
	main._back_to_menu()
	await create_timer(1.0).timeout
	await _shot("3_geri")
	print("lobby sheet valid=", main._lobby_sheet != null and is_instance_valid(main._lobby_sheet), " visible=", main._lobby_sheet.visible if main._lobby_sheet != null and is_instance_valid(main._lobby_sheet) else "-", " mode=", main.mode)
	quit()
