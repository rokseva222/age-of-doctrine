extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var St = load("res://scripts/settings.gd")
	St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	St.seen_promo = true
	St.seen_howto = true
	var Loc = load("res://scripts/loc.gd")
	Loc.apply(OS.get_environment("LANGX") if OS.get_environment("LANGX") != "" else "en")
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.6).timeout
	main.menu._open_eras()
	await create_timer(0.8).timeout
	var out := "/tmp/shots_card"
	DirAccess.make_dir_recursive_absolute(out)
	await _shot(out + "/eras_" + Loc.lang + ".png")
	# listeyi aşağı kaydır
	var sc = get_root().find_children("*", "ScrollContainer", true, false)
	for s in sc:
		s.scroll_vertical = 100000
	await create_timer(0.5).timeout
	await _shot(out + "/eras_" + Loc.lang + "_end.png")
	Loc.apply("tr")
	quit()
