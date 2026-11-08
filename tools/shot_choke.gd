extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute("/tmp/shots_new")
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main._start_daily(load("res://scripts/daily.gd").cfg(20400))
	await create_timer(1.5).timeout
	if main.ui._modal != null:
		main.ui._modal.queue_free()
	await create_timer(0.3).timeout
	var g = main.gs
	var CP = load("res://scripts/chokepoints.gd")
	CP.ensure(g)
	g.chokes["suez"]["mode"] = "toll"
	g.chokes["bosphorus"]["mode"] = "enemy"
	g.chokes["gibraltar"]["mode"] = "all"
	g.chokes["hormuz"]["ctrl"] = g.player
	main.map.focus_province(int(CP.def_of("suez").prov[0]), 2.2)
	await create_timer(1.5).timeout
	main.map.hud.queue_redraw()
	await create_timer(0.3).timeout
	await _shot("/tmp/shots_new/10_choke_map.png")
	var hud = main.map.hud
	var sp: Vector2 = hud._choke_pos(g, "suez")
	print("HIT=", hud.choke_at(sp), " MISS=", hud.choke_at(sp + Vector2(200, 200)))
	main.ui.show_chokes("suez")
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_new/11_choke_card.png")
	quit()
