extends SceneTree
## Hava filosu ekran görüntüleri. Çıktı: /tmp/air_shots/
const Air = preload("res://scripts/air.gd")
const AirUI = preload("res://scripts/air_ui.gd")
const Info = preload("res://scripts/info_sheets.gd")
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.seen_update = Info.UPDATE_VER
	St.seen_promo = true
	St.tut_done = true
	St.seen_howto = true
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out := "/tmp/air_shots"
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(2.5).timeout
	main.menu.finish_splash()
	await create_timer(1.5).timeout
	main._to_select()
	await create_timer(1.5).timeout
	var me := -1
	for c in main.gs.countries:
		if c.name == "Türkiye": me = c.id
	main._on_start_requested(me)
	await create_timer(5.0).timeout
	var gs = main.gs
	Air.ensure(gs)
	main.ui.hide_dialog()
	var ws: Array = Air.wings_of(gs, me)
	print("wings: ", ws.size())
	var bomb = null
	var fight = null
	var trans = null
	for w in ws:
		if w.kind == "bomber" and bomb == null: bomb = w
		if w.kind == "fighter" and fight == null: fight = w
		if w.kind == "transport" and trans == null: trans = w
	if bomb == null:
		bomb = ws[0]
	Air.rename(gs, bomb.id, "Kızıl Elma Bombardıman")
	Air.set_flag(gs, bomb.id, "H:#c8102e,#ffffff|M:.45,.5,.26,#ffffff,0|S:.62,.5,.1,#ffffff,5")
	bomb.xp = 18.0
	main._select_wing(bomb)
	main.map.zoom = 2.6
	main.map.cam_pos = gs.provinces[bomb.base].label_pos
	main.map._apply()
	await create_timer(0.8).timeout
	main.ui.hide_dialog()
	await create_timer(1.0).timeout
	main.ui.hide_dialog()
	await create_timer(0.6).timeout
	main.ui.hide_dialog()
	await create_timer(0.4).timeout
	await _shot(out + "/01_harita_kanat.png")
	main.ui.hide_dialog()
	AirUI.manage(main.ui, gs, bomb, main._wing_done)
	await create_timer(0.8).timeout
	await _shot(out + "/02_komutanlik.png")
	main.ui.hide_dialog()
	await create_timer(0.3).timeout
	if fight != null:
		AirUI.manage(main.ui, gs, fight, main._wing_done)
		await create_timer(0.8).timeout
		await _shot(out + "/03_komutanlik_avci.png")
		main.ui.hide_dialog()
	main.ui.show_pause_menu()
	await create_timer(0.8).timeout
	await _shot(out + "/04_menu.png")
	main.ui.hide_dialog()
	await create_timer(0.3).timeout
	var FP = load("res://scripts/fleet_panel.gd")
	FP.open(main.ui, gs, true)
	await create_timer(0.8).timeout
	await _shot(out + "/05_hava_panel.png")
	main.ui.hide_dialog()
	await create_timer(0.3).timeout
	FP.open(main.ui, gs, false)
	await create_timer(0.8).timeout
	await _shot(out + "/06_deniz_panel.png")
	quit()

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
