extends SceneTree
## İstanbul'un Fethi tanıtım klibi (1453 dönemi). Kullanım:
## xvfb-run -a godot --rendering-driver opengl3 --write-movie /tmp/promo/m_1453.avi --fixed-fps 30 --resolution 1920x1080 --path . -s tools/promo_1453.gd
var main
func _tick() -> void:
	if main != null:
		var m = main.ui._modal
		if m != null and is_instance_valid(m):
			m.visible = false
			m.queue_free()
			main.ui._modal = null
		main.ui.toast_panel.visible = false
func _wait(s: float) -> void:
	await create_timer(s).timeout
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	var Loc = load("res://scripts/loc.gd")
	St.load_all(); St.language = "tr"; St.ui_scale = 0.8; St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0
	St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	St.save_all()
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	Loc.apply("tr")
	St.ui_scale = 0.8; St.language = "tr"; St.apply_display(self)
	await _wait(1.0)
	main.menu.finish_splash()
	await _wait(0.6)
	process_frame.connect(_tick)
	main.menu.hide()
	main._start_era("ott1453")
	await _wait(0.8)
	var gs = main.gs
	main._on_start_requested(int(gs.macro_idx.get("Turkey", 0)))
	await _wait(0.8)
	main.ui.hide_dialog()
	gs = main.gs
	gs.countries[gs.player].auto_cmd = true
	main.ui.hide_info(); main.ui.set_hud_visible(false); main.ui.toast_panel.visible = false
	main.map.hud.show_armies = true
	var ist := 423
	for p in gs.provinces:
		if p.name == "Konstantinopolis":
			ist = p.id
	# geniş plan -> sura yaklaş
	main.map.zoom = 5.0
	main.map.cam_pos = gs.provinces[ist].label_pos + Vector2(10, -4)
	main.map._apply()
	await _wait(2.0)
	main.map.animate_to(gs.provinces[ist].label_pos, 24.0, 3.2)
	await _wait(3.6)
	for i in 11:
		main.ui.hide_dialog(); _tick()
		main._do_turn()
		main.ui.hide_info(); main.ui.set_hud_visible(false); main.ui.toast_panel.visible = false
		main.map.hud.queue_redraw()
		await _wait(1.0)
	await _wait(1.0)
	quit()
