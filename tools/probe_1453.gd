extends SceneTree
var main
func _wait(s: float) -> void:
	await create_timer(s).timeout
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	var Loc = load("res://scripts/loc.gd")
	St.load_all(); St.language = "tr"; St.ui_scale = 0.8; St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0
	St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	Loc.apply("tr")
	St.apply_display(self)
	await _wait(1.0)
	main.menu.finish_splash()
	await _wait(0.6)
	main.menu.hide()
	main._start_era("ott1453")
	await _wait(0.8)
	var gs = main.gs
	var tr: int = int(gs.macro_idx.get("Turkey", 0))
	main._on_start_requested(tr)
	await _wait(1.0)
	for i in 6:
		main.ui.hide_dialog()
		await _wait(0.3)
	gs = main.gs
	print("oyuncu=", gs.countries[gs.player].name, " tur=", gs.turn)
	var istanbul := -1
	for p in gs.provinces:
		if p.name.to_lower().find("stanbul") >= 0 or p.name.to_lower().find("konstantin") >= 0:
			print("il: ", p.name, " id=", p.id, " sahip=", gs.countries[p.owner].name if p.owner >= 0 else "-", " kontrol=", gs.countries[p.controller].name if p.controller >= 0 else "-")
			if istanbul < 0: istanbul = p.id
	gs.countries[gs.player].auto_cmd = true
	main.map.hud.show_armies = true
	if istanbul >= 0:
		main.map.focus_province(istanbul, 3.0)
	await _wait(1.0)
	await _shot("/tmp/p1453_0.png")
	for i in 10:
		for k in 4:
			main.ui.hide_dialog()
		main._do_turn()
		main.map.hud.queue_redraw()
		await _wait(0.6)
		for k in 4:
			main.ui.hide_dialog()
		await _wait(0.2)
		var p = gs.provinces[istanbul]
		print("tur=", gs.turn, " tarih=", load("res://scripts/names.gd").date_string(gs.turn), " sahip=", gs.countries[p.owner].name, " kontrol=", gs.countries[p.controller].name if p.controller >= 0 else "-")
		await _shot("/tmp/p1453_%d.png" % (i + 1))
	quit()
