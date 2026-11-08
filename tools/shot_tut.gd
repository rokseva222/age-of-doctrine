extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"; St.tut_done = false; St.save_all()
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute("/tmp/shots_tut")
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
	await _shot("/tmp/shots_tut/01.png")
	var tu = main.tutorial
	print("TUT ", tu != null)
	tu._advance()
	await create_timer(0.3).timeout
	main.map.tapped.emit(main.gs.countries[me].capital)
	await create_timer(1.6).timeout
	print("idx after tap ", tu.idx)
	tu._show(3)
	await create_timer(0.5).timeout
	await _shot("/tmp/shots_tut/04.png")
	tu._show(6)
	await create_timer(0.5).timeout
	await _shot("/tmp/shots_tut/07.png")
	tu._show(9)
	await create_timer(0.5).timeout
	await _shot("/tmp/shots_tut/10.png")
	main.gs.end_turn()
	tu._show(6); main.gs.end_turn()
	await create_timer(1.6).timeout
	print("idx after turn ", tu.idx)
	tu.finish(true)
	print("done ", St.tut_done, " tut ", main.tutorial)
	St.tut_done = false; St.save_all()
	quit()
