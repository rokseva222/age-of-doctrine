extends SceneTree
const Ed = preload("res://scripts/scenario_editor.gd")
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute("/tmp/shots_ed")
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main.menu.show_main()
	await create_timer(0.8).timeout
	main.menu._open_scenarios()
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_ed/01_list.png")
	main.menu.root.get_children().back().queue_free()
	await create_timer(0.3).timeout
	Ed.open(main.menu.root, {}, func(_id): pass)
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_ed/02_editor.png")
	var sh = main.menu.root.get_children().back()
	var sc = sh.find_children("*", "ScrollContainer", true, false)
	if not sc.is_empty():
		sc[0].scroll_vertical = 900
		await create_timer(0.4).timeout
		await _shot("/tmp/shots_ed/03_editor_mid.png")
		sc[0].scroll_vertical = 3000
		await create_timer(0.4).timeout
		await _shot("/tmp/shots_ed/04_editor_end.png")
	main.menu.root.get_children().back().queue_free()
	await create_timer(0.3).timeout
	main.menu._open_eras()
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_ed/05_eras.png")
	quit()
