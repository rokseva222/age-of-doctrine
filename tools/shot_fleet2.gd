extends SceneTree
## Filo komutanlığı ekran görüntüleri. Çıktı: /tmp/fleet_shots2/
const Fleets = preload("res://scripts/fleets.gd")
const FleetUI = preload("res://scripts/fleet_ui.gd")
const Seas = preload("res://scripts/seas.gd")
const Info = preload("res://scripts/info_sheets.gd")
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.seen_update = Info.UPDATE_VER
	St.seen_promo = true
	St.tut_done = true
	St.seen_howto = true
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out := "/tmp/fleet_shots2"
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._to_select()
	await create_timer(0.8).timeout
	var me := -1
	for c in main.gs.countries:
		if c.name == "Türkiye": me = c.id
	main._on_start_requested(me)
	await create_timer(1.5).timeout
	var gs = main.gs
	Fleets.ensure(gs)
	main.ui.hide_dialog()
	var surf = null
	var sub = null
	for f in Fleets.fleets_of(gs, me):
		if f.kind == "surface" and surf == null: surf = f
		if f.kind == "sub" and sub == null: sub = f
	Fleets.rename(gs, surf.id, "Karadeniz Akıncıları")
	Fleets.set_flag(gs, surf.id, "H:#c8102e,#ffffff|M:.45,.5,.26,#ffffff,0|S:.62,.5,.1,#ffffff,5")
	surf.xp = 18.0
	Fleets.set_stance(gs, surf.id, "defend")
	# 1) harita: bayraklı filo
	main._select_fleet(surf)
	main.map.zoom = 3.8
	main.map.cam_pos = Seas.pos(surf.zone) + Vector2(0, -10)
	main.map._apply()
	await create_timer(0.8).timeout
	main.ui.hide_dialog()
	await create_timer(0.5).timeout
	await _shot(out + "/01_harita_bayrakli.png")
	# 2) komutanlık
	await create_timer(1.0).timeout
	main.ui.hide_dialog()
	await create_timer(0.4).timeout
	FleetUI.manage(main.ui, gs, surf, main._fleet_done)
	await create_timer(0.8).timeout
	await _shot(out + "/02_komutanlik_muharebe.png")
	main.ui.hide_dialog()
	await create_timer(0.3).timeout
	FleetUI.manage(main.ui, gs, sub, main._fleet_done)
	await create_timer(0.8).timeout
	await _shot(out + "/03_komutanlik_denizalti.png")
	main.ui.hide_dialog()
	await create_timer(0.3).timeout
	# 4) geniş harita: Hazar ve Arktik
	main._clear_fleet_sel()
	main.ui.hide_info()
	main.map.zoom = 2.2
	main.map.cam_pos = Seas.pos("caspian") + Vector2(120, -80)
	main.map._apply()
	await create_timer(0.8).timeout
	await _shot(out + "/04_hazar_arktik.png")
	quit()
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
