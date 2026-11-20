extends SceneTree
## Çağa özel deniz filosu ekran görüntüleri. Çıktı: /tmp/naval_shots/
const FleetUI = preload("res://scripts/fleet_ui.gd")
const Fleets = preload("res://scripts/fleets.gd")
const Seas = preload("res://scripts/seas.gd")
const Eras = preload("res://scripts/eras.gd")
const Info = preload("res://scripts/info_sheets.gd")
var main
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.seen_update = Info.UPDATE_VER
	St.seen_promo = true
	St.tut_done = true
	St.seen_howto = true
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out := "/tmp/naval_shots"
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(2.5).timeout
	main.menu.finish_splash()
	await create_timer(1.5).timeout
	for era in ["ott1453", "ww2"]:
		main._start_era(era)
		await create_timer(1.5).timeout
		var host := String(Eras.get_era(era).suggest[0])
		var me: int = int(main.gs.macro_idx.get(host, 0))
		var St2 = load("res://scripts/settings.gd")
		St2.seen_update = Info.UPDATE_VER
		St2.tut_done = true
		main._on_start_requested(me)
		await create_timer(13.0).timeout
		var gs = main.gs
		for i in 10:
			main.ui.hide_dialog()
			await create_timer(0.5).timeout
		Fleets.ensure(gs)
		var fs: Array = Fleets.fleets_of(gs, gs.player)
		var sub = null
		var sur = null
		for f in fs:
			if f.kind == "sub" and sub == null: sub = f
			if f.kind == "surface" and sur == null: sur = f
		print(era, " fleets=", fs.size())
		if sub != null:
			main._select_fleet(sub)
			main.map.zoom = 2.6
			main.map.cam_pos = Seas.pos(sub.zone)
			main.map._apply()
			await create_timer(0.8).timeout
			for i in 3:
				main.ui.hide_dialog()
				await create_timer(0.3).timeout
			await _shot(out + "/%s_1_harita_kadirga.png" % era)
			main.ui.hide_dialog()
			FleetUI.manage(main.ui, gs, sub, main._fleet_done)
			await create_timer(0.8).timeout
			await _shot(out + "/%s_2_komutanlik_sub.png" % era)
			main.ui.hide_dialog()
			await create_timer(0.3).timeout
		if sur != null:
			FleetUI.manage(main.ui, gs, sur, main._fleet_done)
			await create_timer(0.8).timeout
			await _shot(out + "/%s_3_komutanlik_yuzey.png" % era)
			main.ui.hide_dialog()
			await create_timer(0.3).timeout
		var FP = load("res://scripts/fleet_panel.gd")
		FP.open(main.ui, gs, false)
		await create_timer(0.8).timeout
		await _shot(out + "/%s_4_panel.png" % era)
		main.ui.hide_dialog()
		main._back_to_menu()
		await create_timer(1.5).timeout
	quit()

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
