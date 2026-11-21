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
	var p = gs.provinces[istanbul]
	print("ist label=", p.label_pos, " nb=", p.neighbors.size())
	for q in gs.provinces:
		if q.name in ["Bursa", "Edirne", "İzmit", "Çanakkale", "Selanik"]:
			print(q.name, q.id, q.label_pos, gs.countries[q.owner].name)
	print("cam=", main.map.cam_pos, " zoom=", main.map.zoom, " rect=", main.map.world_rect())
	quit()
