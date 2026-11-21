extends SceneTree
## Merkezi sunucu uçtan uca: oda kurdur -> otomatik katıl -> lobi. AOD_HUB=http://127.0.0.1:8790
var main
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png("/tmp/rep/%s.png" % name)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	var Loc = load("res://scripts/loc.gd")
	St.load_all(); St.language = "tr"; St.ui_scale_custom = true; St.ui_scale = 1.0; St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0
	St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	St.player_name = "Kurucu"; St.master_url = OS.get_environment("AOD_HUB"); St.save_all()
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	Loc.apply("tr")
	await create_timer(2.0).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	for i in 6:
		main.ui.hide_dialog()
		await create_timer(0.3).timeout
	load("res://scripts/online_ui.gd").host_form(main)
	await create_timer(1.0).timeout
	await _shot("h1_form")
	main.get_master().create_failed.connect(func(c, m): print("CREATE_FAILED ", c, " ", m))
	main.get_master().created.connect(func(i): print("CREATED ", i))
	main.online_host_remote({"name": "Sunucu Odam", "era": "", "scenario": "ukr", "pass": "", "round_secs": 120.0, "max": 4, "fog": 0})
	await create_timer(6.0).timeout
	main.ui.hide_dialog()
	await _shot("h2_lobi")
	var n = main.get_net()
	print("SONUC is_server=", n.is_server, " connected=", n.connected, " info.name=", n.info.get("name", "-"), " scn=", n.info.get("scn", "-"), " host=", n.players.values().map(func(p): return p.get("host")))
	quit()
