extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.seen_howto = true
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	var Info = load("res://scripts/info_sheets.gd")
	Info.open_settings(main.menu.root if "root" in main.menu else main, func(): pass, null)
	await create_timer(1.0).timeout
	await _shot(OS.get_environment("OUT"))
	quit()
