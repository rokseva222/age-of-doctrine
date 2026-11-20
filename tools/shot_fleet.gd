extends SceneTree
## Deniz filoları ekran görüntüleri: harita+filolar, seçili filo paneli, denizde ordu. Çıktı: /tmp/fleet_shots/
## xvfb-run -a godot --path . -s tools/shot_fleet.gd --resolution 2400x1080
const Fleets = preload("res://scripts/fleets.gd")
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
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/fleet_shots"
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._to_select()
	await create_timer(0.8).timeout
	var me := -1
	for c in main.gs.countries:
		if c.name == "Türkiye": me = c.id
	St.tut_done = true
	St.seen_howto = true
	main._on_start_requested(me)
	await create_timer(1.5).timeout
	var gs = main.gs
	Fleets.ensure(gs)
	var gr: int = gs.macro_idx["Greece"]
	gs.player_declare_war(gr)
	for i in 3: gs.end_turn()
	main.ui.refresh_top()
	# 1) harita + filolar (Doğu Akdeniz / Ege)
	main.map.zoom = 3.4
	main.map.cam_pos = Vector2(130, -185)
	main.map._apply()
	await create_timer(0.8).timeout
	main.ui.hide_dialog()
	await create_timer(0.4).timeout
	await _shot(out + "/01_harita_filolar.png")
	# 2) seçili filo + hareket yolu
	var tf = null
	for f in Fleets.fleets_of(gs, me):
		if f.kind == "surface": tf = f
	main._select_fleet(tf)
	var z0: String = tf.zone
	print("filo ", tf.id, " ", z0, " -> ", Fleets.order_move(gs, tf.id, "med_e"))
	main.map.hud.queue_redraw()
	await create_timer(0.8).timeout
	main.ui.hide_dialog()
	await create_timer(0.4).timeout
	await _shot(out + "/02_filo_secili.png")
	# 3) denizde ordu: Akdeniz kıyısındaki ordudan nakliye
	main._clear_fleet_sel()
	var pp := -1
	for pid in gs.countries[me].owned_ids:
		var p = gs.provinces[pid]
		if p.controller == me and not Seas.coast_zones(gs, pid).is_empty() and Seas.coast_zones(gs, pid).has("aegean") and gs.armies.has(pid) and gs.armies[pid].owner == me:
			pp = pid; break
	if pp < 0:
		for pid in gs.countries[me].owned_ids:
			if gs.provinces[pid].controller == me and not Seas.coast_zones(gs, pid).is_empty() and gs.armies.has(pid):
				pp = pid; break
	gs.countries[me].gold = 1.0e7
	print("embark ", gs.provinces[pp].name, " -> ", Fleets.embark(gs, pp, 0, -1))
	var tr = null
	for f in Fleets.fleets_of(gs, me):
		if f.kind == "transport": tr = f
	# hedef: Yunan kıyısına bitişik denize taşı
	var gz := ""
	for z in Seas.ports_of(gs, gr): gz = z
	print("nakliye ", tr.zone, " -> ", gz, " ", Fleets.order_move(gs, tr.id, gz))
	gs.end_turn()
	main.ui.refresh_top()
	main._select_fleet(tr)
	var zp: Vector2 = Seas.pos(tr.zone)
	main.map.cam_pos = zp + Vector2(0, -10)
	main.map.zoom = 3.4
	main.map._apply()
	await create_timer(0.8).timeout
	main.ui.hide_dialog()
	await create_timer(0.5).timeout
	await _shot(out + "/03_denizde_ordu.png")
	# 4) kıyı eyaleti kartında gemiye bin / karaya çıkar
	var p2 := -1
	for pid in gs.countries[me].owned_ids:
		if gs.provinces[pid].controller == me and not Seas.coast_zones(gs, pid).is_empty() and gs.armies.has(pid) and gs.armies[pid].owner == me and pid != pp:
			p2 = pid; break
	main._clear_fleet_sel()
	main._select(p2)
	main.ui.hide_dialog()
	await create_timer(0.6).timeout
	await _shot(out + "/04_eyalet_gemiye_bin.png")
	quit()
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
