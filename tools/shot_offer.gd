extends SceneTree
## Teklif ve sohbet ekranları. Çıktı: /tmp/offer_shots/
const Info = preload("res://scripts/info_sheets.gd")
var main
var out := "/tmp/offer_shots"

func _shot_keep(name: String) -> void:
	await create_timer(0.3).timeout
	var img: Image = get_root().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	print("shot ", name)

func _shot(name: String) -> void:
	for i in 3:
		main.ui.hide_dialog()
		await create_timer(0.3).timeout
	var img: Image = get_root().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	print("shot ", name)

func _pass_go() -> bool:
	var n = main.ui.root.get_node_or_null("MpPass")
	if n == null:
		return false
	n.get_meta("go").emit_signal("pressed")
	return true

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
	await _shot("1_mod_secimi")
	for ch in main.menu.root.get_children():
		if ch is Control and ch.get_class() != "":
			pass
	main.menu.root.get_children().back().close()
	main.mp_n = 3
	main._to_select()
	await create_timer(1.0).timeout
	await _shot("2_ulke_secimi_oyuncu1")
	var gs = main.gs
	var ids: Array = []
	for n in ["Turkey", "Germany", "France"]:
		ids.append(int(gs.macro_idx.get(n, 0)))
	main._on_start_requested(ids[0])
	await create_timer(0.6).timeout
	await _shot("3_ulke_secimi_oyuncu2")
	main._on_start_requested(ids[1])
	main._on_start_requested(ids[2])
	await create_timer(1.5).timeout
	print("humans=", main.gs.humans, " player=", main.gs.player)
	await _shot("4_perde_oyuncu1")
	_pass_go()
	await create_timer(1.0).timeout
	await _shot("5_oyuncu1_harita")
	# oyuncu 1 (Türkiye) Almanya'ya ittifak teklif eder
	for i in 8:
		main.ui.hide_dialog()
		await create_timer(0.4).timeout
	var msg: String = main.gs.player_propose_alliance(ids[1])
	print("teklif: ", msg, " offers=", main.gs.offers.size())
	main._on_step()
	await create_timer(1.2).timeout
	_pass_go()
	await create_timer(1.5).timeout
	print("dialog açık: ", main.ui.is_dialog_open(), " seat=", main.gs.player)
	await _shot_keep("9_teklif_diyalogu")
	# sohbet
	var net = main.get_net()
	net.chat_log = [{"cid": 1, "name": "Erdem", "text": "Selam, ittifak teklifimi gördün mü?"}, {"cid": 2, "name": "Ayşe", "text": "Kabul ediyorum, birlikte Fransa'ya yüklenelim."}]
	main.ui.hide_dialog()
	await create_timer(0.5).timeout
	var sh = main.ui._open_sheet("Sohbet", 640, false, true, "Online")
	main.OnlineUI.chat_box(net, sh.body, 320.0)
	await create_timer(0.8).timeout
	await _shot_keep("10_sohbet")
	print("DONE")
	quit()
