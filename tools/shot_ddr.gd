extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var out := "/tmp/shots_ddr"
	DirAccess.make_dir_recursive_absolute(out)
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(3.8).timeout
	load("res://scripts/settings.gd").seen_howto = true
	load("res://scripts/settings.gd").seen_update = "1.2.7"
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	var eid: String = OS.get_environment("ERA")
	if eid == "": eid = "cw62"
	main._start_era(eid)
	await create_timer(1.5).timeout
	var gid := -1
	var did := -1
	for c in main.gs.countries:
		if c.name_en == "Germany": gid = c.id
		if c.name_en == "Liechtenstein": did = c.id
	main._on_start_requested(gid)
	await create_timer(1.8).timeout
	main.ui.hide_dialog()
	var d = main.gs.countries[did]
	var g = main.gs.countries[gid]
	var cnt := {}
	for p in main.gs.provinces:
		cnt[p.owner] = int(cnt.get(p.owner, 0)) + 1
	var armies := 0
	for a in main.gs.armies.values() if main.gs.armies is Dictionary else main.gs.armies:
		if a.owner == did: armies += 1
	print("DDR alive=", d.alive, " name=", d.name, " provs=", cnt.get(did, 0), " capital=", d.capital, " bloc=", d.bloc, " army=", armies)
	print("FRG alive=", g.alive, " name=", g.name, " provs=", cnt.get(gid, 0), " capital=", g.capital, " bloc=", g.bloc)
	for c in main.gs.countries:
		if c.name_en == "Switzerland": print("CH provs=", cnt.get(c.id, 0))
	var Fl = load("res://scripts/flags.gd")
	var cv := Control.new()
	cv.size = Vector2(1280, 800)
	cv.z_index = 100
	main.add_child(cv)
	cv.draw.connect(func():
		cv.draw_rect(Rect2(0, 0, 1280, 800), Color(0.1, 0.1, 0.12))
		Fl.draw(cv, Rect2(120, 150, 480, 300), d)
		Fl.draw(cv, Rect2(680, 150, 480, 300), g)
		Fl.draw(cv, Rect2(120, 520, 96, 60), d))
	cv.queue_redraw()
	await create_timer(0.5).timeout
	await _shot(out + "/ddrflag.png")
	cv.queue_free()
	main.map.focus_country(gid)
	await create_timer(1.0).timeout
	await _shot(out + "/germany.png")
	quit()
