extends SceneTree
## Online 1453 odası (tanıtım): lobi, ülke seçimi. Önce sunucu + friend_bot'lar çalışmalı. Çıktı: /tmp/on1453/
var main
var out := "/tmp/on1453"
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	var Loc = load("res://scripts/loc.gd")
	St.load_all(); St.language = "tr"; St.ui_scale = 1.4; St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0
	St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	St.player_name = "Fatih"
	St.save_all()
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	Loc.apply("tr")
	St.ui_scale = 1.4; St.language = "tr"; St.apply_display(self)
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(2.0).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	for i in 8:
		main.ui.hide_dialog()
		await create_timer(0.3).timeout
	main._on_multi_menu()
	await create_timer(0.5).timeout
	main.menu.root.get_children().back().close()
	main.OnlineUI.host_form(main)
	await create_timer(1.0).timeout
	await _shot("0_oda_kur")
	main.menu.root.get_children().back().close()
	await create_timer(0.4).timeout
	main.online_join("127.0.0.1", 47398)
	await create_timer(3.0).timeout
	await _shot("1_lobi")
	main.online_pick_country()
	await create_timer(2.0).timeout
	main.ui.hide_dialog()
	await _shot("2_ulke_sec")
	main._on_start_requested(int(main.gs.macro_idx.get("Turkey", 0)))
	await create_timer(1.0).timeout
	main.get_net().to_server("srv_chat", ["Toplar hazır. Sabaha surlar yok."])
	await create_timer(1.5).timeout
	await _shot("3_lobi_dolu")
	main.get_net().to_server("srv_start")
	await create_timer(6.0).timeout
	for i in 4:
		main.ui.hide_dialog()
		await create_timer(0.3).timeout
	main.ui.set_hud_visible(true)
	await _shot("4_oyun")
	print("DONE online=", main.online)
	quit()
