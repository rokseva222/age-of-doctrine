extends SceneTree
## Online akış (gerçek sahne): sunucuya bağlan → lobi → ülke seç → başlat → emir → tur. Çıktı: /tmp/online_shots/
const Info = preload("res://scripts/info_sheets.gd")
var main
var out := "/tmp/online_shots"

func _shot(name: String) -> void:
	for i in 3:
		main.ui.hide_dialog()
		await create_timer(0.3).timeout
	var img: Image = get_root().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	print("shot ", name)

func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.seen_update = Info.UPDATE_VER
	St.seen_promo = true
	St.tut_done = true
	St.seen_howto = true
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(2.5).timeout
	main.menu.finish_splash()
	await create_timer(10.0).timeout
	for i in 12:
		main.ui.hide_dialog()
		await create_timer(0.4).timeout
	main._on_multi_menu()
	await create_timer(0.5).timeout
	main.menu.root.get_children().back().close()
	OnlineUI_open()
	await create_timer(1.5).timeout
	await _shot("1_tarayici")
	main.menu.root.get_children().back().close()
	main.OnlineUI.host_form(main)
	await create_timer(0.8).timeout
	await _shot("1b_oda_kur")
	main.menu.root.get_children().back().close()
	main.online_join("127.0.0.1", 47397)
	await create_timer(2.0).timeout
	await _shot("2_lobi")
	main.online_pick_country()
	await create_timer(1.5).timeout
	await _shot("3_ulke_sec")
	var gs = main.gs
	var tr: int = int(gs.macro_idx.get("Turkey", 0))
	main._on_start_requested(tr)
	await create_timer(1.0).timeout
	await _shot("4_lobi_secti")
	main.get_net().to_server("srv_start")
	await create_timer(6.0).timeout
	print("online=", main.online, " mode=", main.mode, " player=", main.gs.player)
	await _shot("5_oyun")
	var g = main.gs
	var foe := -1
	for nb in g.neighbor_countries(g.player):
		if g.countries[nb].alive and not g.at_war(g.player, nb) and not g.is_allied(g.player, nb):
			foe = nb
			break
	print("savaş ilanı: ", g.player_declare_war(foe), " log=", g.cmd_log.size())
	main._on_step()
	await create_timer(2.0).timeout
	await _shot("6_bekleme")
	await create_timer(5.0).timeout
	print("tur=", main.gs.turn, " savaşta=", main.gs.at_war(main.gs.player, foe))
	await _shot("7_tur_raporu")
	print("DONE")
	quit()

func OnlineUI_open() -> void:
	main.OnlineUI.browser(main)
