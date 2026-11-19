extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var out := "/tmp/shots_col"
	DirAccess.make_dir_recursive_absolute(out)
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(3.8).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	load("res://scripts/settings.gd").seen_howto = true
	load("res://scripts/settings.gd").seen_update = "1.2.4"
	main._to_select()
	await create_timer(1.5).timeout
	await _shot(out + "/world.png")
	for pr in [["eu", Vector2(1450, 420), 3.2], ["asia", Vector2(2300, 480), 2.6]]:
		main.map.animate_to(pr[1], main.map.min_zoom * pr[2], 0.1)
		await create_timer(0.8).timeout
		await _shot(out + "/%s.png" % pr[0])
	print(main.map.world_rect())
	quit()
